package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// ── referrals, K-factor and introducers ─────────────────────────────────────

func (s *Server) adminBusinessReferrals(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Months: 6, Bucket: "month"})
	if !ok {
		return
	}
	defer done()
	fail := func(err error) { writeError(w, http.StatusBadGateway, err) }
	var flag bool
	_ = tx.QueryRowContext(ctx, `SELECT COALESCE((SELECT value_bool FROM matching.platform_feature_flags WHERE key='referrals_enabled'),FALSE)`).Scan(&flag)

	var codesIssued, activeCodes int64
	if err := tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE created_at >= $1 AND created_at < $2), COUNT(*) FILTER (WHERE status='active')
		FROM growth.referral_codes`, p.Since, p.Until).Scan(&codesIssued, &activeCodes); err != nil {
		fail(err)
		return
	}
	var recorded, verified, void, activated, referredPaid int64
	if err := tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE rr.status='recorded'), COUNT(*) FILTER (WHERE rr.status='verified'), COUNT(*) FILTER (WHERE rr.status='void'),
		       COUNT(*) FILTER (WHERE rr.status<>'void' AND u.is_verified),
		       COUNT(*) FILTER (WHERE rr.status<>'void' AND EXISTS (
		         SELECT 1 FROM matching.billing_payments_runtime p
		         WHERE p.user_id=rr.referred_member_id AND p.status IN `+businessChargedStatuses+` AND `+businessModeExpr("p", s.stripeTestMode())+` = ANY($3)))
		FROM growth.referral_redemptions rr JOIN user_management.users u ON u.id=rr.referred_member_id
		WHERE rr.created_at >= $1 AND rr.created_at < $2`, p.Since, p.Until, p.modes()).Scan(&recorded, &verified, &void, &activated, &referredPaid); err != nil {
		fail(err)
		return
	}
	accepted := recorded + verified

	rows, err := tx.QueryContext(ctx, `
		WITH members AS (
		  SELECT u.id, u.created_at, to_char(date_trunc('month', u.created_at AT TIME ZONE $3),'YYYY-MM') AS cohort
		  FROM user_management.users u WHERE `+p.memberFilter("u")+` AND u.created_at >= $1 AND u.created_at < $2
		)
		SELECT m.cohort, COUNT(*),
		  COALESCE(SUM((SELECT COUNT(*) FROM growth.referral_redemptions rr JOIN growth.referral_codes rc ON rc.id=rr.code_id
		                 WHERE rc.owner_id=m.id AND rr.status<>'void' AND rr.created_at < m.created_at + interval '30 days')),0),
		  COALESCE(SUM((SELECT COUNT(*) FROM matching.introducer_invites ii
		                 WHERE ii.member_user_id=m.id AND ii.created_at < m.created_at + interval '30 days')),0),
		  COALESCE(SUM((SELECT COUNT(*) FROM matching.introducer_invites ii
		                 WHERE ii.member_user_id=m.id AND ii.consumed_at IS NOT NULL AND ii.consumed_at < m.created_at + interval '30 days')),0)
		FROM members m GROUP BY 1 ORDER BY 1`, p.Since, p.Until, p.TZ)
	if err != nil {
		fail(err)
		return
	}
	kRows := []map[string]any{}
	kTable := businessTable{Name: "k_factor", Columns: []string{"cohort", "members", "referral_signups_30d", "introducer_invites_30d", "introducer_accepted_30d", "k_referral", "k_introducer", "k_total", "introducer_invites_per_member", "introducer_acceptance_rate"}}
	var totN, totRef, totInv, totAcc int64
	kFields := func(n, ref, inv, acc int64) (any, any, any, any, any) {
		if n < businessSmallCount {
			return nil, nil, nil, nil, nil
		}
		var acceptance any
		if inv >= businessSmallCount {
			acceptance = businessRatio(float64(acc), float64(inv))
		}
		return businessRatio(float64(ref), float64(n)), businessRatio(float64(acc), float64(n)), businessRatio(float64(ref+acc), float64(n)), businessRatio(float64(inv), float64(n)), acceptance
	}
	for rows.Next() {
		var cohort string
		var n, ref, inv, acc int64
		if err := rows.Scan(&cohort, &n, &ref, &inv, &acc); err != nil {
			rows.Close()
			fail(err)
			return
		}
		totN, totRef, totInv, totAcc = totN+n, totRef+ref, totInv+inv, totAcc+acc
		kr, ki, kt, ipm, ar := kFields(n, ref, inv, acc)
		kRows = append(kRows, map[string]any{"cohort": cohort, "members": suppressCount(n), "referral_signups_30d": suppressCount(ref), "introducer_invites_30d": suppressCount(inv), "introducer_accepted_30d": suppressCount(acc), "k_referral": kr, "k_introducer": ki, "k_total": kt, "introducer_invites_per_member": ipm, "introducer_acceptance_rate": ar})
		kTable.Rows = append(kTable.Rows, []any{cohort, suppressCount(n), suppressCount(ref), suppressCount(inv), suppressCount(acc), kr, ki, kt, ipm, ar})
	}
	rows.Close()
	kr, ki, kt, ipm, ar := kFields(totN, totRef, totInv, totAcc)

	var invCreated, invConsumed, invRevoked, invExpired, consentsActive, consentsPending int64
	if err := tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE created_at >= $1 AND created_at < $2),
		       COUNT(*) FILTER (WHERE consumed_at >= $1 AND consumed_at < $2),
		       COUNT(*) FILTER (WHERE revoked_at >= $1 AND revoked_at < $2),
		       COUNT(*) FILTER (WHERE expires_at >= $1 AND expires_at < LEAST($2, NOW()) AND consumed_at IS NULL AND revoked_at IS NULL)
		FROM matching.introducer_invites`, p.Since, p.Until).Scan(&invCreated, &invConsumed, &invRevoked, &invExpired); err != nil {
		fail(err)
		return
	}
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FILTER (WHERE status='active' AND revoked_at IS NULL), COUNT(*) FILTER (WHERE status='pending' AND revoked_at IS NULL) FROM matching.introducer_consents`).Scan(&consentsActive, &consentsPending); err != nil {
		fail(err)
		return
	}
	intros := []map[string]any{}
	introTable := businessTable{Name: "intros", Columns: []string{"introducer_kind", "intros", "matched", "declined", "expired", "open", "match_rate"}}
	rows, err = tx.QueryContext(ctx, `
		SELECT u.account_kind, COUNT(*), COUNT(*) FILTER (WHERE fi.status='matched'), COUNT(*) FILTER (WHERE fi.status='declined'),
		       COUNT(*) FILTER (WHERE fi.status='expired'), COUNT(*) FILTER (WHERE fi.status='open')
		FROM matching.friend_intros fi JOIN user_management.users u ON u.id=fi.introducer_user_id
		WHERE fi.created_at >= $1 AND fi.created_at < $2 GROUP BY 1 ORDER BY 1`, p.Since, p.Until)
	if err != nil {
		fail(err)
		return
	}
	for rows.Next() {
		var kind string
		var n, matched, declined, expired, open int64
		if err := rows.Scan(&kind, &n, &matched, &declined, &expired, &open); err != nil {
			rows.Close()
			fail(err)
			return
		}
		label := "member_introducers"
		if kind == "introducer" {
			label = "introducer_accounts"
		}
		var rate any
		if n >= businessSmallCount {
			rate = businessRatio(float64(matched), float64(n))
		}
		intros = append(intros, map[string]any{"introducer_kind": label, "intros": suppressCount(n), "matched": suppressCount(matched), "declined": suppressCount(declined), "expired": suppressCount(expired), "open": suppressCount(open), "match_rate": rate})
		introTable.Rows = append(introTable.Rows, []any{label, suppressCount(n), suppressCount(matched), suppressCount(declined), suppressCount(expired), suppressCount(open), rate})
	}
	rows.Close()

	payload := businessEnvelope("referrals", p)
	payload["referrals_enabled"] = flag
	if !flag {
		payload["referrals_note"] = "referrals_enabled is off (default); codes and redemptions stay empty until the owner enables the flag."
	}
	payload["referrals"] = map[string]any{
		"codes_issued": suppressCount(codesIssued), "active_codes": suppressCount(activeCodes),
		"redemptions":                map[string]any{"recorded": suppressCount(recorded), "verified": suppressCount(verified), "void": suppressCount(void), "accepted": suppressCount(accepted)},
		"activated_referred_members": suppressCount(activated),
		"referred_members_who_paid":  suppressCount(referredPaid),
		"invites_sent":               "not instrumented: referral codes are reusable links and shares are not recorded",
	}
	payload["k_factor"] = map[string]any{
		"by_cohort":  kRows,
		"overall":    map[string]any{"members": suppressCount(totN), "k_referral": kr, "k_introducer": ki, "k_total": kt, "introducer_invites_per_member": ipm, "introducer_acceptance_rate": ar},
		"targets":    map[string]any{"healthy": 0.5, "redesign_below": 0.2},
		"definition": "K = invites accepted per new member in their first 30 days (pricing strategy 5.2). k_referral counts non-void referral redemptions of the member's code; k_introducer counts introducer invite links the member created that were accepted. For introducer links K = invites per member × acceptance rate.",
	}
	payload["introducers"] = map[string]any{
		"invites_created": suppressCount(invCreated), "invites_accepted": suppressCount(invConsumed),
		"invites_revoked": suppressCount(invRevoked), "invites_expired_unused": suppressCount(invExpired),
		"consents_active": suppressCount(consentsActive), "consents_pending": suppressCount(consentsPending),
		"intros": intros,
	}
	writeBusinessReport(w, p, payload, []businessTable{kTable, introTable})
}

// ── market / city launch readiness ──────────────────────────────────────────

type launchMarket struct {
	CityKey          string   `json:"city_key"`
	DisplayName      string   `json:"display_name"`
	Country          string   `json:"country"`
	Currency         string   `json:"currency"`
	Aliases          []string `json:"aliases"`
	VerifiedTarget   int64    `json:"verified_target"`
	MaxGenderShare   float64  `json:"max_gender_share"`
	PlansKeptTarget  float64  `json:"plans_kept_target"`
	ApproachingShare float64  `json:"approaching_share"`
	LaunchOrder      *int64   `json:"launch_order"`
	Active           bool     `json:"active"`
	Notes            string   `json:"notes"`
}

var defaultLaunchGates = launchMarket{VerifiedTarget: 3000, MaxGenderShare: 0.6, PlansKeptTarget: 0.08, ApproachingShare: 0.5}

func loadLaunchMarkets(ctx context.Context, q businessQueryer) (map[string]launchMarket, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT city_key, display_name, country, currency, COALESCE(array_to_json(aliases)::text,'[]'), verified_target, max_gender_share::float8,
		       plans_kept_target::float8, approaching_share::float8, launch_order, active, COALESCE(notes,'')
		FROM business.launch_markets`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]launchMarket{}
	for rows.Next() {
		var m launchMarket
		var order sql.NullInt64
		var aliases string
		if err := rows.Scan(&m.CityKey, &m.DisplayName, &m.Country, &m.Currency, &aliases, &m.VerifiedTarget, &m.MaxGenderShare, &m.PlansKeptTarget, &m.ApproachingShare, &order, &m.Active, &m.Notes); err != nil {
			return nil, err
		}
		if err := json.Unmarshal([]byte(aliases), &m.Aliases); err != nil || m.Aliases == nil {
			m.Aliases = []string{}
		}
		if order.Valid {
			v := order.Int64
			m.LaunchOrder = &v
		}
		out[m.CityKey] = m
	}
	return out, rows.Err()
}

type cityCounts struct {
	Members, Verified, Female, Male, Other, Active30, Active7, NewVerified30, PrevVerified30, PlansKept7 int64
}

// readinessStatus applies the pricing strategy's city gates (5.1).
func readinessStatus(c cityCounts, gates launchMarket) (string, map[string]any) {
	balanced := c.Female + c.Male
	var share any
	genderOK := false
	if balanced >= businessSmallCount {
		top := math.Max(float64(c.Female), float64(c.Male)) / float64(balanced)
		share = math.Round(top*1000) / 1000
		genderOK = top <= gates.MaxGenderShare
	}
	verifiedOK := c.Verified >= gates.VerifiedTarget
	var plansPerActive any
	plansOK := false
	if c.Active30 >= businessSmallCount {
		v := float64(c.PlansKept7) / float64(c.Active30)
		plansPerActive = math.Round(v*10000) / 10000
		plansOK = v >= gates.PlansKeptTarget
	}
	status := "not_ready"
	switch {
	case verifiedOK && genderOK:
		status = "ready"
	case float64(c.Verified) >= gates.ApproachingShare*float64(gates.VerifiedTarget):
		status = "approaching"
	}
	gateDetail := map[string]any{
		"verified_members":      map[string]any{"target": gates.VerifiedTarget, "met": verifiedOK, "progress": businessRatio(float64(c.Verified), float64(gates.VerifiedTarget))},
		"gender_balance":        map[string]any{"max_share": gates.MaxGenderShare, "largest_share": share, "met": genderOK, "note": "share of the larger of women and men among verified members; other genders are counted separately"},
		"plans_kept_per_active": map[string]any{"target": gates.PlansKeptTarget, "value": plansPerActive, "met": plansOK, "note": "launch → live gate: plans kept in the last 7 days per member active in the last 30 days"},
		"live_gate_met":         status == "ready" && plansOK,
	}
	return status, gateDetail
}

func (s *Server) adminBusinessMarkets(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Days: 30, Bucket: "day"})
	if !ok {
		return
	}
	defer done()
	markets, err := loadLaunchMarkets(ctx, tx)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	asOf := p.Until
	if now := time.Now(); asOf.After(now) {
		asOf = now
	}
	rows, err := tx.QueryContext(ctx, `
		WITH mem AS (
		  SELECT u.id, lower(btrim(u.city)) AS city_raw, u.gender, u.is_verified, u.created_at, a.last_active_at
		  FROM user_management.users u
		  LEFT JOIN platform.member_last_activity a ON a.user_id=u.id
		  WHERE `+p.memberFilter("u")+` AND COALESCE(btrim(u.city),'')<>''
		    AND u.deactivated_at IS NULL AND u.deletion_requested_at IS NULL AND NOT u.is_banned
		    AND u.created_at < $1
		),
		keyed AS (
		  SELECT mem.*, COALESCE((SELECT lm.city_key FROM business.launch_markets lm
		                          WHERE lm.city_key = mem.city_raw OR mem.city_raw = ANY(lm.aliases) ORDER BY lm.city_key LIMIT 1), mem.city_raw) AS city_key
		  FROM mem
		),
		plans AS (
		  SELECT k.city_key, COUNT(DISTINCT dp.id) AS kept
		  FROM matching.match_date_plans dp
		  JOIN keyed k ON k.id IN (dp.proposer_user_id, dp.invitee_user_id)
		  WHERE dp.status='completed' AND COALESCE(dp.resolved_at, dp.updated_at) >= $1 - interval '7 days' AND COALESCE(dp.resolved_at, dp.updated_at) < $1
		  GROUP BY 1
		)
		SELECT k.city_key, COUNT(*),
		  COUNT(*) FILTER (WHERE k.is_verified),
		  COUNT(*) FILTER (WHERE k.is_verified AND k.gender='female'),
		  COUNT(*) FILTER (WHERE k.is_verified AND k.gender='male'),
		  COUNT(*) FILTER (WHERE k.is_verified AND COALESCE(k.gender,'other') NOT IN ('female','male')),
		  COUNT(*) FILTER (WHERE k.last_active_at >= $1 - interval '30 days'),
		  COUNT(*) FILTER (WHERE k.last_active_at >= $1 - interval '7 days'),
		  COUNT(*) FILTER (WHERE k.is_verified AND k.created_at >= $1 - interval '30 days'),
		  COUNT(*) FILTER (WHERE k.is_verified AND k.created_at >= $1 - interval '60 days' AND k.created_at < $1 - interval '30 days'),
		  COALESCE(MAX(pl.kept),0)
		FROM keyed k LEFT JOIN plans pl ON pl.city_key=k.city_key
		GROUP BY k.city_key`, asOf)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	counts := map[string]cityCounts{}
	for rows.Next() {
		var key string
		var c cityCounts
		if err := rows.Scan(&key, &c.Members, &c.Verified, &c.Female, &c.Male, &c.Other, &c.Active30, &c.Active7, &c.NewVerified30, &c.PrevVerified30, &c.PlansKept7); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		counts[key] = c
	}
	rows.Close()

	cityRow := func(key, name string, c cityCounts, gates launchMarket, configured bool) map[string]any {
		status, gateDetail := readinessStatus(c, gates)
		var growth, daysToTarget any
		if c.PrevVerified30 >= businessSmallCount {
			growth = businessRatio(float64(c.NewVerified30-c.PrevVerified30), float64(c.PrevVerified30))
		}
		if c.NewVerified30 > 0 && c.Verified < gates.VerifiedTarget {
			daysToTarget = int64(math.Ceil(float64(gates.VerifiedTarget-c.Verified) / (float64(c.NewVerified30) / 30.0)))
		}
		row := map[string]any{
			"city_key": key, "city": name, "configured": configured, "status": status,
			"members": suppressCount(c.Members), "verified_members": suppressCount(c.Verified),
			"verified_women": suppressCount(c.Female), "verified_men": suppressCount(c.Male), "verified_other": suppressCount(c.Other),
			"active_30d": suppressCount(c.Active30), "active_7d": suppressCount(c.Active7),
			"new_verified_30d": suppressCount(c.NewVerified30), "new_verified_prev_30d": suppressCount(c.PrevVerified30),
			"verified_growth_30d": growth, "projected_days_to_target": daysToTarget,
			"plans_kept_7d": suppressCount(c.PlansKept7), "gates": gateDetail,
		}
		if configured {
			row["country"], row["currency"], row["launch_order"], row["active"] = gates.Country, gates.Currency, gates.LaunchOrder, gates.Active
		}
		return row
	}
	out := []map[string]any{}
	table := businessTable{Name: "markets", Columns: []string{"city", "configured", "status", "members", "verified_members", "verified_women", "verified_men", "largest_gender_share", "active_30d", "new_verified_30d", "verified_growth_30d", "plans_kept_7d", "plans_kept_per_active", "verified_target", "projected_days_to_target"}}
	addRow := func(row map[string]any, target int64) {
		g := row["gates"].(map[string]any)
		table.Rows = append(table.Rows, []any{row["city"], row["configured"], row["status"], row["members"], row["verified_members"], row["verified_women"], row["verified_men"], g["gender_balance"].(map[string]any)["largest_share"], row["active_30d"], row["new_verified_30d"], row["verified_growth_30d"], row["plans_kept_7d"], g["plans_kept_per_active"].(map[string]any)["value"], target, row["projected_days_to_target"]})
		out = append(out, row)
	}
	// Configured markets first, in launch order, even with no members yet.
	configured := make([]launchMarket, 0, len(markets))
	for _, m := range markets {
		configured = append(configured, m)
	}
	sortLaunchMarkets(configured)
	for _, m := range configured {
		addRow(cityRow(m.CityKey, m.DisplayName, counts[m.CityKey], m, true), m.VerifiedTarget)
		delete(counts, m.CityKey)
	}
	var pooled cityCounts
	pooledCities := 0
	for _, key := range sortedKeys(counts) {
		c := counts[key]
		if c.Members < businessSmallCount {
			pooled.Members += c.Members
			pooled.Verified += c.Verified
			pooled.Female += c.Female
			pooled.Male += c.Male
			pooled.Other += c.Other
			pooled.Active30 += c.Active30
			pooled.Active7 += c.Active7
			pooled.NewVerified30 += c.NewVerified30
			pooled.PrevVerified30 += c.PrevVerified30
			pooled.PlansKept7 += c.PlansKept7
			pooledCities++
			continue
		}
		addRow(cityRow(key, key, c, defaultLaunchGates, false), defaultLaunchGates.VerifiedTarget)
	}
	if pooledCities > 0 {
		row := cityRow("_other", fmt.Sprintf("other cities (%d, each <5 members)", pooledCities), pooled, defaultLaunchGates, false)
		row["status"] = "not_assessed"
		row["pooled"] = true
		addRow(row, defaultLaunchGates.VerifiedTarget)
	}
	var noCity int64
	_ = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM user_management.users u WHERE `+p.memberFilter("u")+` AND COALESCE(btrim(u.city),'')='' AND u.created_at < $1`, asOf).Scan(&noCity)

	payload := businessEnvelope("markets", p)
	payload["as_of"] = asOf.UTC().Format(time.RFC3339)
	payload["markets"] = out
	payload["members_without_city"] = suppressCount(noCity)
	payload["default_gates"] = map[string]any{"verified_target": defaultLaunchGates.VerifiedTarget, "max_gender_share": defaultLaunchGates.MaxGenderShare, "plans_kept_target": defaultLaunchGates.PlansKeptTarget, "approaching_share": defaultLaunchGates.ApproachingShare, "source": "PRICING_AND_GO_TO_MARKET_STRATEGY_2026-09-27 5.1 (assumptions)"}
	payload["liquidity"] = map[string]any{"source": "computed here", "note": "Engagement liquidity (matches, conversations per city) is owned by the product analytics reports; this report covers launch gates only."}
	payload["definitions"] = map[string]string{
		"ready":       "verified members ≥ target and the larger of women/men ≤ max share of verified women+men",
		"approaching": "not ready, verified members ≥ approaching_share × target",
		"not_ready":   "anything else",
		"live_gate":   "a ready city graduates from launch to live when plans kept per active member ≥ plans_kept_target",
		"members":     "dating accounts, not operators, not erased, deactivated, deletion-pending or banned; city from the member's profile (aliases map spellings)",
	}
	writeBusinessReport(w, p, payload, []businessTable{table})
}

func sortLaunchMarkets(ms []launchMarket) {
	order := func(m launchMarket) int64 {
		if m.LaunchOrder == nil {
			return 1 << 30
		}
		return *m.LaunchOrder
	}
	for i := 1; i < len(ms); i++ {
		for j := i; j > 0; j-- {
			a, b := ms[j-1], ms[j]
			if order(a) > order(b) || (order(a) == order(b) && a.CityKey > b.CityKey) {
				ms[j-1], ms[j] = b, a
			}
		}
	}
}

var (
	businessKeyPattern      = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]{0,63}$`)
	businessCurrencyPattern = regexp.MustCompile(`^[A-Z]{3}$`)
)

func (s *Server) adminBusinessSaveMarket(w http.ResponseWriter, r *http.Request) {
	principal, ok := businessAccess(w, r, businessMarketRoles)
	if !ok {
		return
	}
	db, err := s.businessDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	m := launchMarket{
		CityKey:          strings.ToLower(strings.TrimSpace(toString(body["city_key"]))),
		DisplayName:      strings.TrimSpace(toString(body["display_name"])),
		Country:          strings.TrimSpace(toString(body["country"])),
		Currency:         strings.ToUpper(strings.TrimSpace(toString(body["currency"]))),
		VerifiedTarget:   int64(orInt(body["verified_target"], int(defaultLaunchGates.VerifiedTarget))),
		MaxGenderShare:   orFloat(body["max_gender_share"], defaultLaunchGates.MaxGenderShare),
		PlansKeptTarget:  orFloat(body["plans_kept_target"], defaultLaunchGates.PlansKeptTarget),
		ApproachingShare: orFloat(body["approaching_share"], defaultLaunchGates.ApproachingShare),
		Active:           orBool(body["active"], true),
		Notes:            strings.TrimSpace(toString(body["notes"])),
	}
	if v, ok := toInt(body["launch_order"]); ok && v > 0 {
		order := int64(v)
		m.LaunchOrder = &order
	}
	if raw, ok := body["aliases"].([]any); ok {
		for _, a := range raw {
			if alias := strings.ToLower(strings.TrimSpace(toString(a))); alias != "" && len(alias) <= 64 {
				m.Aliases = append(m.Aliases, alias)
			}
		}
	}
	if m.Aliases == nil {
		m.Aliases = []string{}
	}
	switch {
	case !businessKeyPattern.MatchString(m.CityKey) || m.CityKey == "all":
		err = errors.New("city_key must be lower-case letters, digits, '-' or '_' (and not 'all')")
	case len(m.DisplayName) < 2 || len(m.DisplayName) > 100:
		err = errors.New("display_name must be 2–100 characters")
	case len(m.Country) < 2 || len(m.Country) > 100:
		err = errors.New("country must be 2–100 characters")
	case !businessCurrencyPattern.MatchString(m.Currency):
		err = errors.New("currency must be an ISO 4217 code such as INR, GBP or EUR")
	case m.VerifiedTarget < 1 || m.VerifiedTarget > 10000000:
		err = errors.New("verified_target must be 1–10,000,000")
	case m.MaxGenderShare <= 0.5 || m.MaxGenderShare > 1:
		err = errors.New("max_gender_share must be above 0.5 and at most 1")
	case m.PlansKeptTarget < 0 || m.PlansKeptTarget > 10:
		err = errors.New("plans_kept_target must be 0–10")
	case m.ApproachingShare <= 0 || m.ApproachingShare >= 1:
		err = errors.New("approaching_share must be between 0 and 1")
	case len(m.Aliases) > 20:
		err = errors.New("at most 20 aliases")
	case len(m.Notes) > 500:
		err = errors.New("notes must be at most 500 characters")
	}
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	ctx, cancel := s.businessContext(r)
	defer cancel()
	var order any
	if m.LaunchOrder != nil {
		order = *m.LaunchOrder
	}
	var created bool
	if err := db.QueryRowContext(ctx, `
		INSERT INTO business.launch_markets(city_key, display_name, country, currency, aliases, verified_target, max_gender_share,
		  plans_kept_target, approaching_share, launch_order, active, notes, updated_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,NULLIF($12,''),$13::uuid)
		ON CONFLICT (city_key) DO UPDATE SET display_name=EXCLUDED.display_name, country=EXCLUDED.country, currency=EXCLUDED.currency,
		  aliases=EXCLUDED.aliases, verified_target=EXCLUDED.verified_target, max_gender_share=EXCLUDED.max_gender_share,
		  plans_kept_target=EXCLUDED.plans_kept_target, approaching_share=EXCLUDED.approaching_share, launch_order=EXCLUDED.launch_order,
		  active=EXCLUDED.active, notes=EXCLUDED.notes, updated_by=EXCLUDED.updated_by, updated_at=NOW()
		RETURNING (xmax = 0)`, m.CityKey, m.DisplayName, m.Country, m.Currency, m.Aliases, m.VerifiedTarget, m.MaxGenderShare,
		m.PlansKeptTarget, m.ApproachingShare, order, m.Active, m.Notes, uuidOrNil(principal.UserID)).Scan(&created); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	writeJSON(w, status, map[string]any{"market": m, "created": created})
}

func orFloat(v any, def float64) float64 {
	switch x := v.(type) {
	case float64:
		return x
	case int:
		return float64(x)
	case string:
		if f, err := strconv.ParseFloat(strings.TrimSpace(x), 64); err == nil {
			return f
		}
	}
	return def
}

func uuidOrNil(id string) any {
	if len(id) == 36 && strings.Count(id, "-") == 4 {
		return id
	}
	return nil
}

// ── marketing spend (CAC inputs) ────────────────────────────────────────────

type marketingSpend struct {
	ID                string `json:"id"`
	Month             string `json:"month"`
	Channel           string `json:"channel"`
	Market            string `json:"market"`
	Currency          string `json:"currency"`
	AmountMinor       int64  `json:"amount_minor"`
	Amount            string `json:"amount"`
	AttributedMembers *int64 `json:"attributed_members"`
	Note              string `json:"note"`
	UpdatedAt         string `json:"updated_at"`
}

var marketingChannels = map[string]bool{"paid_social": true, "search": true, "influencer": true, "events": true, "referral_rewards": true, "partnerships": true, "pr": true, "content": true, "app_store": true, "other": true}

func parseSpendBody(ctx context.Context, q businessQueryer, body map[string]any) (marketingSpend, error) {
	sp := marketingSpend{
		Channel:  strings.TrimSpace(toString(body["channel"])),
		Market:   strings.ToLower(strings.TrimSpace(toString(body["market"]))),
		Currency: strings.ToUpper(strings.TrimSpace(toString(body["currency"]))),
		Note:     strings.TrimSpace(toString(body["note"])),
	}
	if sp.Market == "" {
		sp.Market = "all"
	}
	month := strings.TrimSpace(toString(body["month"]))
	t, err := time.Parse("2006-01", month)
	if err != nil {
		if t, err = time.Parse("2006-01-02", month); err != nil {
			return sp, errors.New("month must be YYYY-MM")
		}
	}
	sp.Month = time.Date(t.Year(), t.Month(), 1, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
	if !marketingChannels[sp.Channel] {
		return sp, errors.New("channel must be one of paid_social, search, influencer, events, referral_rewards, partnerships, pr, content, app_store, other")
	}
	if !businessCurrencyPattern.MatchString(sp.Currency) {
		return sp, errors.New("currency must be an ISO 4217 code such as INR, GBP or EUR")
	}
	// amount_minor wins; amount (major units, e.g. "1250.50") is accepted for forms.
	if v, ok := body["amount_minor"]; ok && v != nil {
		f, isNum := v.(float64)
		if !isNum || f != math.Trunc(f) {
			return sp, errors.New("amount_minor must be a whole number of minor units")
		}
		sp.AmountMinor = int64(f)
	} else {
		raw := strings.TrimSpace(toString(body["amount"]))
		minor, err := parseMajorAmount(raw, sp.Currency)
		if err != nil {
			return sp, err
		}
		sp.AmountMinor = minor
	}
	if sp.AmountMinor < 0 || sp.AmountMinor > 100000000000 {
		return sp, errors.New("amount must be between 0 and 1,000,000,000 major units")
	}
	if v, ok := body["attributed_members"]; ok && v != nil {
		f, isNum := v.(float64)
		if !isNum || f < 0 || f != math.Trunc(f) {
			return sp, errors.New("attributed_members must be a whole number ≥ 0")
		}
		n := int64(f)
		sp.AttributedMembers = &n
	}
	if len(sp.Note) > 500 {
		return sp, errors.New("note must be at most 500 characters")
	}
	if !businessKeyPattern.MatchString(sp.Market) {
		return sp, errors.New("market must be 'all' or a launch market city_key")
	}
	if sp.Market != "all" {
		var exists bool
		if err := q.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM business.launch_markets WHERE city_key=$1)`, sp.Market).Scan(&exists); err != nil {
			return sp, err
		}
		if !exists {
			return sp, errors.New("market must be 'all' or a configured launch market city_key")
		}
	}
	sp.Amount = majorUnits(sp.AmountMinor, sp.Currency)
	return sp, nil
}

func parseMajorAmount(raw, currency string) (int64, error) {
	if raw == "" {
		return 0, errors.New("amount or amount_minor is required")
	}
	raw = strings.ReplaceAll(raw, ",", "")
	decimals := 2
	if zeroDecimalCurrencies[currency] {
		decimals = 0
	}
	parts := strings.SplitN(raw, ".", 2)
	whole, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil || whole < 0 {
		return 0, errors.New("amount must be a positive decimal such as 1250.50")
	}
	frac := int64(0)
	if len(parts) == 2 {
		if len(parts[1]) > decimals {
			return 0, fmt.Errorf("amount has more than %d decimal places", decimals)
		}
		digits := parts[1] + strings.Repeat("0", decimals-len(parts[1]))
		if digits != "" {
			if frac, err = strconv.ParseInt(digits, 10, 64); err != nil {
				return 0, errors.New("amount must be a positive decimal such as 1250.50")
			}
		}
	}
	return whole*int64(math.Pow10(decimals)) + frac, nil
}

const spendColumns = `id::text, to_char(month,'YYYY-MM-DD'), channel, market, currency, amount_minor, attributed_members, COALESCE(note,''), updated_at`

func scanSpend(row interface{ Scan(...any) error }) (marketingSpend, error) {
	var sp marketingSpend
	var attributed sql.NullInt64
	var updated time.Time
	if err := row.Scan(&sp.ID, &sp.Month, &sp.Channel, &sp.Market, &sp.Currency, &sp.AmountMinor, &attributed, &sp.Note, &updated); err != nil {
		return sp, err
	}
	if attributed.Valid {
		v := attributed.Int64
		sp.AttributedMembers = &v
	}
	sp.Amount = majorUnits(sp.AmountMinor, sp.Currency)
	sp.UpdatedAt = updated.UTC().Format(time.RFC3339)
	return sp, nil
}

// spendCAC computes CAC and spend per month and currency. CAC divides spend in
// one currency by the members who joined that month (in the market when the
// spend names a launch market). Different currencies are never combined.
func spendCAC(ctx context.Context, q businessQueryer, p businessParams) ([]map[string]any, businessTable, error) {
	table := businessTable{Name: "cac", Columns: []string{"month", "market", "currency", "spend", "new_members", "cac", "attributed_members", "attributed_cac"}}
	rows, err := q.QueryContext(ctx, `
		WITH spend AS (
		  SELECT month, market, currency, SUM(amount_minor) AS amount, SUM(attributed_members) AS attributed, COUNT(attributed_members) AS attributed_rows
		  FROM business.marketing_spend
		  WHERE month >= date_trunc('month', $1 AT TIME ZONE $3)::date AND month < ($2 AT TIME ZONE $3)::date
		  GROUP BY 1,2,3
		),
		joins AS (
		  SELECT to_char(date_trunc('month', u.created_at AT TIME ZONE $3),'YYYY-MM-DD') AS month,
		         COALESCE((SELECT lm.city_key FROM business.launch_markets lm WHERE lm.city_key=lower(btrim(u.city)) OR lower(btrim(u.city)) = ANY(lm.aliases) LIMIT 1),'') AS market
		  FROM user_management.users u
		  WHERE `+p.memberFilter("u")+` AND u.created_at >= date_trunc('month', $1 AT TIME ZONE $3) AT TIME ZONE $3 AND u.created_at < $2
		)
		SELECT to_char(s.month,'YYYY-MM-DD'), s.market, s.currency, s.amount, COALESCE(s.attributed,0), s.attributed_rows,
		       (SELECT COUNT(*) FROM joins j WHERE j.month = to_char(s.month,'YYYY-MM-DD') AND (s.market='all' OR j.market=s.market))
		FROM spend s
		ORDER BY 1,2,3`, p.Since, p.Until, p.TZ)
	if err != nil {
		return nil, table, err
	}
	defer rows.Close()
	out := []map[string]any{}
	for rows.Next() {
		var month, market, currency string
		var amount, attributed, attributedRows, joined int64
		if err := rows.Scan(&month, &market, &currency, &amount, &attributed, &attributedRows, &joined); err != nil {
			return nil, table, err
		}
		var cac, attributedCAC any
		if joined > 0 {
			cac = int64(math.Round(float64(amount) / float64(joined)))
		}
		if attributedRows > 0 && attributed > 0 {
			attributedCAC = int64(math.Round(float64(amount) / float64(attributed)))
		}
		out = append(out, map[string]any{
			"month": month[:7], "market": market, "currency": currency, "spend_minor": amount, "spend": majorUnits(amount, currency),
			"new_members": suppressCount(joined), "cac_minor": cac, "cac": majorUnitsAny(cac, currency),
			"attributed_members": attributed, "attributed_cac_minor": attributedCAC, "attributed_cac": majorUnitsAny(attributedCAC, currency),
		})
		table.Rows = append(table.Rows, []any{month[:7], market, currency, majorUnits(amount, currency), suppressCount(joined), majorUnitsAny(cac, currency), attributed, majorUnitsAny(attributedCAC, currency)})
	}
	return out, table, rows.Err()
}

func (s *Server) adminBusinessListSpend(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Months: 12, Bucket: "month"})
	if !ok {
		return
	}
	defer done()
	rows, err := tx.QueryContext(ctx, `SELECT `+spendColumns+` FROM business.marketing_spend
		WHERE month >= date_trunc('month', $1 AT TIME ZONE $3)::date AND month < ($2 AT TIME ZONE $3)::date
		ORDER BY month DESC, market, channel, currency`, p.Since, p.Until, p.TZ)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	entries := []marketingSpend{}
	entryTable := businessTable{Name: "entries", Columns: []string{"month", "channel", "market", "currency", "amount", "attributed_members", "note"}}
	for rows.Next() {
		sp, err := scanSpend(rows)
		if err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		entries = append(entries, sp)
		var attributed any
		if sp.AttributedMembers != nil {
			attributed = *sp.AttributedMembers
		}
		entryTable.Rows = append(entryTable.Rows, []any{sp.Month[:7], sp.Channel, sp.Market, sp.Currency, sp.Amount, attributed, sp.Note})
	}
	rows.Close()
	cac, cacTable, err := spendCAC(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	markets, err := loadLaunchMarkets(ctx, tx)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	payload := businessEnvelope("marketing-spend", p)
	payload["entries"] = entries
	payload["cac"] = cac
	payload["channels"] = sortedKeys(marketingChannels)
	payload["markets"] = append([]string{"all"}, sortedKeys(markets)...)
	if len(entries) == 0 {
		payload["status"] = "needs spend data"
		payload["note"] = "No marketing spend recorded in this window: CAC and payback cannot be computed until spend is entered per month, channel, market and currency."
	} else {
		payload["status"] = "ok"
	}
	writeBusinessReport(w, p, payload, []businessTable{entryTable, cacTable})
}

func (s *Server) adminBusinessCreateSpend(w http.ResponseWriter, r *http.Request) {
	principal, ok := businessAccess(w, r, businessSpendRoles)
	if !ok {
		return
	}
	db, err := s.businessDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.businessContext(r)
	defer cancel()
	sp, err := parseSpendBody(ctx, db, body)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	var created bool
	row := db.QueryRowContext(ctx, `
		INSERT INTO business.marketing_spend(month, channel, market, currency, amount_minor, attributed_members, note, created_by, updated_by)
		VALUES ($1::date,$2,$3,$4,$5,$6,NULLIF($7,''),$8::uuid,$8::uuid)
		ON CONFLICT (month, channel, market, currency) DO UPDATE SET amount_minor=EXCLUDED.amount_minor,
		  attributed_members=EXCLUDED.attributed_members, note=EXCLUDED.note, updated_by=EXCLUDED.updated_by, updated_at=NOW()
		RETURNING `+spendColumns+`, (xmax = 0)`, sp.Month, sp.Channel, sp.Market, sp.Currency, sp.AmountMinor, sp.AttributedMembers, sp.Note, uuidOrNil(principal.UserID))
	var attributed sql.NullInt64
	var updated time.Time
	if err := row.Scan(&sp.ID, &sp.Month, &sp.Channel, &sp.Market, &sp.Currency, &sp.AmountMinor, &attributed, &sp.Note, &updated, &created); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	sp.UpdatedAt = updated.UTC().Format(time.RFC3339)
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	writeJSON(w, status, map[string]any{"spend": sp, "created": created})
}

func (s *Server) adminBusinessUpdateSpend(w http.ResponseWriter, r *http.Request) {
	principal, ok := businessAccess(w, r, businessSpendRoles)
	if !ok {
		return
	}
	db, err := s.businessDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	id := strings.TrimSpace(chi.URLParam(r, "spendID"))
	if uuidOrNil(id) == nil {
		writeError(w, http.StatusBadRequest, errors.New("spend id must be a UUID"))
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.businessContext(r)
	defer cancel()
	sp, err := parseSpendBody(ctx, db, body)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	updated, err := scanSpend(db.QueryRowContext(ctx, `
		UPDATE business.marketing_spend SET month=$2::date, channel=$3, market=$4, currency=$5, amount_minor=$6,
		  attributed_members=$7, note=NULLIF($8,''), updated_by=$9::uuid, updated_at=NOW()
		WHERE id=$1::uuid RETURNING `+spendColumns, id, sp.Month, sp.Channel, sp.Market, sp.Currency, sp.AmountMinor, sp.AttributedMembers, sp.Note, uuidOrNil(principal.UserID)))
	var pgErr *pgconn.PgError
	switch {
	case errors.Is(err, sql.ErrNoRows):
		writeError(w, http.StatusNotFound, errors.New("marketing spend entry not found"))
		return
	case errors.As(err, &pgErr) && pgErr.Code == "23505":
		writeError(w, http.StatusConflict, errors.New("another entry already exists for this month, channel, market and currency"))
		return
	case err != nil:
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"spend": updated})
}

func (s *Server) adminBusinessDeleteSpend(w http.ResponseWriter, r *http.Request) {
	if _, ok := businessAccess(w, r, businessSpendRoles); !ok {
		return
	}
	db, err := s.businessDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	id := strings.TrimSpace(chi.URLParam(r, "spendID"))
	if uuidOrNil(id) == nil {
		writeError(w, http.StatusBadRequest, errors.New("spend id must be a UUID"))
		return
	}
	ctx, cancel := s.businessContext(r)
	defer cancel()
	res, err := db.ExecContext(ctx, `DELETE FROM business.marketing_spend WHERE id=$1::uuid`, id)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		writeError(w, http.StatusNotFound, errors.New("marketing spend entry not found"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"deleted": true, "id": id})
}
