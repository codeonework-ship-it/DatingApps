package mobile

import (
	"context"
	"net/http"
	"strconv"
	"time"
)

// ── conversion, LTV ─────────────────────────────────────────────────────────

const businessLTVMaxMonths = 24

// adminBusinessConversion reports free→paid conversion by signup cohort
// (month of users.created_at in the reporting zone), cumulative net revenue
// per member by month since signup (LTV curve), and the current
// actives→subscribers conversion the pricing strategy assumes (4–6%).
func (s *Server) adminBusinessConversion(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Months: 12, Bucket: "month"})
	if !ok {
		return
	}
	defer done()
	modeExpr := businessModeExpr("p", s.stripeTestMode())
	cohortSQL := `
		WITH members AS (
		  SELECT u.id, u.created_at, to_char(date_trunc('month', u.created_at AT TIME ZONE $3), 'YYYY-MM') AS cohort
		  FROM user_management.users u
		  WHERE ` + p.memberFilter("u") + ` AND u.created_at >= $1 AND u.created_at < $2
		),
		pay AS (
		  SELECT p.user_id, p.currency, p.created_at, p.status, p.amount_paise, p.refunded_amount_paise, p.subscription_id
		  FROM matching.billing_payments_runtime p
		  JOIN members m ON m.id = p.user_id
		  WHERE ` + modeExpr + ` = ANY($4) AND p.status IN ` + businessChargedStatuses + `
		)`
	rows, err := tx.QueryContext(ctx, cohortSQL+`,
		first_pay AS (
		  SELECT user_id, MIN(created_at) AS first_paid, MIN(created_at) FILTER (WHERE subscription_id IS NOT NULL) AS first_sub
		  FROM pay GROUP BY user_id
		)
		SELECT m.cohort, MIN(m.created_at), COUNT(*),
		  COUNT(*) FILTER (WHERE f.first_paid < m.created_at + interval '7 days'),
		  COUNT(*) FILTER (WHERE f.first_paid < m.created_at + interval '30 days'),
		  COUNT(*) FILTER (WHERE f.first_paid < m.created_at + interval '90 days'),
		  COUNT(*) FILTER (WHERE f.first_paid IS NOT NULL),
		  COUNT(*) FILTER (WHERE f.first_sub IS NOT NULL)
		FROM members m LEFT JOIN first_pay f ON f.user_id = m.id
		GROUP BY m.cohort ORDER BY m.cohort`, p.Since, p.Until, p.TZ, p.modes())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	type cohort struct {
		Name                                      string
		Start                                     time.Time
		Members, D7, D30, D90, ToDate, Subscribed int64
	}
	cohorts := []cohort{}
	size := map[string]int64{}
	for rows.Next() {
		var c cohort
		if err := rows.Scan(&c.Name, &c.Start, &c.Members, &c.D7, &c.D30, &c.D90, &c.ToDate, &c.Subscribed); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		cohorts = append(cohorts, c)
		size[c.Name] = c.Members
	}
	rows.Close()
	now := time.Now()
	cohortRows := []map[string]any{}
	cohortTable := businessTable{Name: "cohorts", Columns: []string{"cohort", "members", "paid_7d", "paid_30d", "paid_90d", "paid_to_date", "subscribed_to_date", "conversion_30d", "conversion_to_date", "mature_30d"}}
	for _, c := range cohorts {
		rate := func(n int64) any {
			if c.Members < businessSmallCount {
				return nil
			}
			return businessRatio(float64(n), float64(c.Members))
		}
		// The youngest member of a month cohort joined by its month end.
		mature := now.Sub(time.Date(c.Start.Year(), c.Start.Month()+1, 1, 0, 0, 0, 0, time.UTC)) >= 30*24*time.Hour
		row := map[string]any{
			"cohort": c.Name, "members": suppressCount(c.Members),
			"paid_7d": suppressCount(c.D7), "paid_30d": suppressCount(c.D30), "paid_90d": suppressCount(c.D90),
			"paid_to_date": suppressCount(c.ToDate), "subscribed_to_date": suppressCount(c.Subscribed),
			"conversion_7d": rate(c.D7), "conversion_30d": rate(c.D30), "conversion_90d": rate(c.D90),
			"conversion_to_date": rate(c.ToDate), "mature_30d": mature,
		}
		cohortRows = append(cohortRows, row)
		cohortTable.Rows = append(cohortTable.Rows, []any{c.Name, row["members"], row["paid_7d"], row["paid_30d"], row["paid_90d"], row["paid_to_date"], row["subscribed_to_date"], row["conversion_30d"], row["conversion_to_date"], mature})
	}

	// LTV: cumulative net revenue per cohort member by month since signup.
	rows, err = tx.QueryContext(ctx, cohortSQL+`
		SELECT m.cohort, p.currency,
		  LEAST(`+strconv.Itoa(businessLTVMaxMonths)+`, (
		    (EXTRACT(YEAR FROM date_trunc('month', p.created_at AT TIME ZONE $3)) - EXTRACT(YEAR FROM date_trunc('month', m.created_at AT TIME ZONE $3))) * 12
		    + EXTRACT(MONTH FROM date_trunc('month', p.created_at AT TIME ZONE $3)) - EXTRACT(MONTH FROM date_trunc('month', m.created_at AT TIME ZONE $3))
		  ))::int AS month_index,
		  COALESCE(SUM(`+businessNetExpr("p")+`),0)
		FROM members m JOIN pay p ON p.user_id = m.id
		GROUP BY 1,2,3 ORDER BY 1,2,3`, p.Since, p.Until, p.TZ, p.modes())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	ltvNet := map[ltvKey]map[int]int64{}
	for rows.Next() {
		var k ltvKey
		var idx int
		var net int64
		if err := rows.Scan(&k.cohort, &k.currency, &idx, &net); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		if ltvNet[k] == nil {
			ltvNet[k] = map[int]int64{}
		}
		ltvNet[k][idx] += net
	}
	rows.Close()
	ltvRows := []map[string]any{}
	ltvCols := []string{"cohort", "currency", "members"}
	for i := 0; i <= businessLTVMaxMonths; i++ {
		ltvCols = append(ltvCols, "m"+strconv.Itoa(i))
	}
	ltvTable := businessTable{Name: "ltv", Columns: ltvCols}
	keys := make([]ltvKey, 0, len(ltvNet))
	for _, c := range cohorts {
		for _, cur := range sortedKeys(currenciesFor(ltvNet, c.Name)) {
			keys = append(keys, ltvKey{c.Name, cur})
		}
	}
	for _, k := range keys {
		members := size[k.cohort]
		start, _ := time.Parse("2006-01", k.cohort)
		age := int(now.Sub(start).Hours() / 24 / 30.4375)
		if age > businessLTVMaxMonths {
			age = businessLTVMaxMonths
		}
		curve := []any{}
		var cum int64
		record := []any{k.cohort, k.currency, suppressCount(members)}
		for i := 0; i <= businessLTVMaxMonths; i++ {
			if i > age {
				record = append(record, nil)
				continue
			}
			cum += ltvNet[k][i]
			v := perMember(cum, members)
			curve = append(curve, v)
			record = append(record, majorUnitsAny(v, k.currency))
		}
		ltvRows = append(ltvRows, map[string]any{"cohort": k.cohort, "currency": k.currency, "members": suppressCount(members), "cumulative_net_per_member_minor": curve, "ltv_to_date_minor": curve[len(curve)-1]})
		ltvTable.Rows = append(ltvTable.Rows, record)
	}

	// Actives → paying subscribers now (the pricing strategy's 4–6% assumption).
	at := p.Until
	if at.After(now) {
		at = now
	}
	active, activeSource := businessActiveMembers(ctx, tx, p, at.Add(-30*24*time.Hour), at)
	subscribers, err := s.subscribersAt(ctx, tx, p, at)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	var subTotal int64
	for _, n := range subscribers {
		subTotal += n
	}
	var actConv any
	if active >= businessSmallCount {
		actConv = businessRatio(float64(subTotal), float64(active))
	}

	payload := businessEnvelope("conversion", p)
	payload["data_status"] = s.businessDataStatus(ctx, tx, p)
	payload["cohorts"] = cohortRows
	payload["ltv"] = ltvRows
	payload["actives_conversion"] = map[string]any{
		"active_members_30d": suppressCount(active),
		"active_source":      activeSource,
		"paying_subscribers": suppressCount(subTotal),
		"rate":               actConv,
		"assumption":         "4–6% of monthly actives (PRICING_AND_GO_TO_MARKET_STRATEGY 4)",
		"at":                 p.Until.UTC().Format(time.RFC3339),
	}
	payload["trials"] = map[string]any{"offered": false, "note": "No trials exist; trial→paid is not applicable."}
	payload["definitions"] = map[string]string{
		"cohort":             "Members (dating accounts, not operators, not erased) by month of signup in the reporting time zone",
		"paid_Nd":            "Members whose first charged payment (success, partially_refunded, refunded, disputed or chargeback; any product) came within N days of signup",
		"ltv":                "Cumulative net revenue of the cohort by month since signup divided by cohort members; months beyond the cohort's age are empty",
		"actives_conversion": "Subscribers with MRR at `until` divided by members active in the 30 days before `until`",
	}
	writeBusinessReport(w, p, payload, []businessTable{cohortTable, ltvTable})
}

type ltvKey struct{ cohort, currency string }

func currenciesFor(m map[ltvKey]map[int]int64, cohort string) map[string]bool {
	out := map[string]bool{}
	for k := range m {
		if k.cohort == cohort {
			out[k.currency] = true
		}
	}
	return out
}

// subscribersAt counts subscribers with MRR at one instant, per currency.
func (s *Server) subscribersAt(ctx context.Context, q businessQueryer, p businessParams, at time.Time) (map[string]int64, error) {
	points, err := s.queryMRR(ctx, q, p, []time.Time{at})
	if err != nil {
		return nil, err
	}
	out := map[string]int64{}
	for _, pt := range points {
		out[pt.Currency] = pt.Subs
	}
	return out, nil
}

// ── paywall / checkout funnel ───────────────────────────────────────────────

func (s *Server) adminBusinessFunnel(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Days: 30, Bucket: "day"})
	if !ok {
		return
	}
	defer done()
	rows, err := tx.QueryContext(ctx, `
		WITH cs AS (
		  SELECT c.id, c.kind, c.status, c.user_id, c.subscription_id,
		         CASE WHEN c.kind='coin_package' THEN COALESCE(c.package_id,'unknown')
		              ELSE COALESCE(c.plan_code,'unknown')||':'||COALESCE(c.billing_cycle,'?') END AS product,
		         COALESCE(NULLIF(c.metadata->>'platform',''),'not_captured') AS platform
		  FROM matching.billing_checkout_sessions c
		  WHERE c.kind <> 'card_update' AND c.created_at >= $1 AND c.created_at < $2
		    AND `+businessModeExpr("c", s.stripeTestMode())+` = ANY($3)
		)
		SELECT cs.kind, cs.product, cs.platform, COUNT(*),
		  COUNT(*) FILTER (WHERE cs.status='completed'),
		  COUNT(*) FILTER (WHERE cs.status='open'),
		  COUNT(*) FILTER (WHERE cs.status IN ('expired','abandoned')),
		  COUNT(*) FILTER (WHERE x.paid),
		  COUNT(*) FILTER (WHERE x.reversed),
		  COUNT(DISTINCT cs.user_id)
		FROM cs LEFT JOIN LATERAL (
		  SELECT BOOL_OR(p.status IN `+businessChargedStatuses+`) AS paid,
		         BOOL_OR(p.status IN ('refunded','partially_refunded','chargeback')) AS reversed
		  FROM matching.billing_payments_runtime p
		  WHERE p.checkout_id = cs.id
		     OR (cs.subscription_id IS NOT NULL AND p.subscription_id = cs.subscription_id AND p.billing_reason='subscription_create')
		) x ON TRUE
		GROUP BY 1,2,3 ORDER BY 1,2,3`, p.Since, p.Until, p.modes())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	type stage struct{ Created, Completed, Open, Dropped, Paid, Refunded, Members int64 }
	stageFields := func(st stage) map[string]any {
		var completion, payRate, refundRate any
		if st.Created >= businessSmallCount {
			completion = businessRatio(float64(st.Completed), float64(st.Created))
			payRate = businessRatio(float64(st.Paid), float64(st.Created))
		}
		if st.Paid >= businessSmallCount {
			refundRate = businessRatio(float64(st.Refunded), float64(st.Paid))
		}
		return map[string]any{
			"created": suppressCount(st.Created), "completed": suppressCount(st.Completed), "open": suppressCount(st.Open),
			"abandoned_or_expired": suppressCount(st.Dropped), "paid": suppressCount(st.Paid), "refunded": suppressCount(st.Refunded),
			"members": suppressCount(st.Members), "completion_rate": completion, "paid_rate": payRate, "refund_rate": refundRate,
		}
	}
	detail := []map[string]any{}
	table := businessTable{Name: "funnel", Columns: []string{"kind", "product", "platform", "created", "completed", "paid", "refunded", "abandoned_or_expired", "open", "completion_rate", "paid_rate", "refund_rate"}}
	byKind := map[string]*stage{}
	overall := stage{}
	for rows.Next() {
		var kind, product, platform string
		var st stage
		if err := rows.Scan(&kind, &product, &platform, &st.Created, &st.Completed, &st.Open, &st.Dropped, &st.Paid, &st.Refunded, &st.Members); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		f := stageFields(st)
		f["kind"], f["product"], f["platform"] = kind, product, platform
		detail = append(detail, f)
		table.Rows = append(table.Rows, []any{kind, product, platform, f["created"], f["completed"], f["paid"], f["refunded"], f["abandoned_or_expired"], f["open"], f["completion_rate"], f["paid_rate"], f["refund_rate"]})
		if byKind[kind] == nil {
			byKind[kind] = &stage{}
		}
		for _, target := range []*stage{byKind[kind], &overall} {
			target.Created += st.Created
			target.Completed += st.Completed
			target.Open += st.Open
			target.Dropped += st.Dropped
			target.Paid += st.Paid
			target.Refunded += st.Refunded
		}
	}
	rows.Close()
	kinds := []map[string]any{}
	for _, k := range sortedKeys(byKind) {
		f := stageFields(*byKind[k])
		f["kind"] = k
		delete(f, "members")
		kinds = append(kinds, f)
	}
	totals := stageFields(overall)
	delete(totals, "members")

	payload := businessEnvelope("funnel", p)
	payload["data_status"] = s.businessDataStatus(ctx, tx, p)
	payload["stages"] = []string{"created", "completed", "paid", "refunded"}
	payload["totals"] = totals
	payload["by_kind"] = kinds
	payload["detail"] = detail
	payload["instrumentation"] = map[string]any{
		"paywall_views": "not instrumented: the funnel starts at checkout creation",
		"platform":      "checkout sessions do not record the client platform yet (metadata.platform); rows show not_captured",
	}
	payload["definitions"] = map[string]string{
		"created":   "Checkout sessions (subscription and coin package; card updates excluded) created in the window",
		"completed": "Sessions the provider completed",
		"paid":      "Sessions with a charged payment linked by checkout id, or the subscription's first invoice",
		"refunded":  "Paid sessions whose payment was refunded, partially refunded or charged back",
	}
	writeBusinessReport(w, p, payload, []businessTable{table})
}

// ── coin economy ────────────────────────────────────────────────────────────

func (s *Server) adminBusinessCoins(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Days: 30, Bucket: "day"})
	if !ok {
		return
	}
	defer done()
	modeExpr := businessModeExpr("w", s.stripeTestMode())
	selected := map[string]bool{}
	for _, m := range p.modes() {
		selected[m] = true
	}
	type flow struct{ Purchased, Granted, Returned, Gifts, Debits int64 }
	trend := map[string]*flow{}
	get := func(bucket string) *flow {
		if trend[bucket] == nil {
			trend[bucket] = &flow{}
		}
		return trend[bucket]
	}
	rows, err := tx.QueryContext(ctx, `
		SELECT to_char(date_trunc($3, w.created_at AT TIME ZONE $4),'YYYY-MM-DD'), w.source, `+modeExpr+`, COALESCE(SUM(w.coins),0)
		FROM matching.wallet_coin_purchases w WHERE w.created_at >= $1 AND w.created_at < $2 GROUP BY 1,2,3`, p.Since, p.Until, p.Bucket, p.TZ)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	for rows.Next() {
		var bucket, source, mode string
		var coins int64
		if err := rows.Scan(&bucket, &source, &mode, &coins); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		f := get(bucket)
		switch {
		case source == "buy" && mode != "local":
			if selected[mode] {
				f.Purchased += coins
			}
		case source == "gift_refund":
			f.Returned += coins
		default:
			f.Granted += coins
		}
	}
	rows.Close()
	rows, err = tx.QueryContext(ctx, `
		SELECT to_char(date_trunc($3, g.created_at AT TIME ZONE $4),'YYYY-MM-DD'), COALESCE(SUM(g.total_cost_coins),0)
		FROM matching.match_gift_sends g WHERE g.created_at >= $1 AND g.created_at < $2 GROUP BY 1`, p.Since, p.Until, p.Bucket, p.TZ)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	for rows.Next() {
		var bucket string
		var coins int64
		if err := rows.Scan(&bucket, &coins); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		get(bucket).Gifts += coins
	}
	rows.Close()
	debits := []map[string]any{}
	rows, err = tx.QueryContext(ctx, `
		SELECT to_char(date_trunc($3, d.created_at AT TIME ZONE $4),'YYYY-MM-DD'), d.source, COUNT(*), COALESCE(SUM(d.coins_debited),0), COALESCE(SUM(d.coins_shortfall),0)
		FROM matching.wallet_coin_debits d WHERE d.created_at >= $1 AND d.created_at < $2 GROUP BY 1,2`, p.Since, p.Until, p.Bucket, p.TZ)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	debitBySource := map[string][3]int64{}
	for rows.Next() {
		var bucket, source string
		var n, coins, shortfall int64
		if err := rows.Scan(&bucket, &source, &n, &coins, &shortfall); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		get(bucket).Debits += coins
		v := debitBySource[source]
		debitBySource[source] = [3]int64{v[0] + n, v[1] + coins, v[2] + shortfall}
	}
	rows.Close()
	for _, src := range sortedKeys(debitBySource) {
		v := debitBySource[src]
		debits = append(debits, map[string]any{"source": src, "count": v[0], "coins_debited": v[1], "coins_shortfall": v[2]})
	}

	purchases, credits, purchasedCoins, err := s.coinCreditSummary(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	var paidSends, paidCoins, freeSends, senders, refundedSends, refundedCoins int64
	if err := tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE total_cost_coins > 0), COALESCE(SUM(total_cost_coins),0),
		       COUNT(*) FILTER (WHERE total_cost_coins = 0), COUNT(DISTINCT sender_user_id) FILTER (WHERE total_cost_coins > 0),
		       COUNT(*) FILTER (WHERE refunded_at IS NOT NULL), COALESCE(SUM(total_cost_coins) FILTER (WHERE refunded_at IS NOT NULL),0)
		FROM matching.match_gift_sends WHERE created_at >= $1 AND created_at < $2`, p.Since, p.Until).Scan(
		&paidSends, &paidCoins, &freeSends, &senders, &refundedSends, &refundedCoins); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	topGifts := []map[string]any{}
	rows, err = tx.QueryContext(ctx, `
		SELECT gift_id, COUNT(*), COALESCE(SUM(total_cost_coins),0) FROM matching.match_gift_sends
		WHERE created_at >= $1 AND created_at < $2 AND total_cost_coins > 0
		GROUP BY 1 ORDER BY 3 DESC, 1 LIMIT 10`, p.Since, p.Until)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	for rows.Next() {
		var gift string
		var n, coins int64
		if err := rows.Scan(&gift, &n, &coins); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		topGifts = append(topGifts, map[string]any{"gift_id": gift, "sends": suppressCount(n), "coins": coins})
	}
	rows.Close()

	// Liability: coins outstanding now. The share bought with money (selected
	// mode) is valued at the average price paid per coin, per currency.
	var walletsWithBalance, outstanding, debt, frozen int64
	if err := tx.QueryRowContext(ctx, `
		SELECT COUNT(*) FILTER (WHERE coin_balance > 0), COALESCE(SUM(coin_balance),0), COALESCE(SUM(debt_coins),0), COUNT(*) FILTER (WHERE frozen_at IS NOT NULL)
		FROM matching.user_wallets`).Scan(&walletsWithBalance, &outstanding, &debt, &frozen); err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	var allCredited, allBought int64
	boughtByCurrency := map[string][2]int64{}
	rows, err = tx.QueryContext(ctx, `
		SELECT w.source='buy' AND `+modeExpr+` = ANY($1), w.currency, COALESCE(SUM(w.coins),0), COALESCE(SUM(w.amount_minor),0)
		FROM matching.wallet_coin_purchases w GROUP BY 1,2`, p.modes())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	for rows.Next() {
		var bought bool
		var currency string
		var coins, amount int64
		if err := rows.Scan(&bought, &currency, &coins, &amount); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		allCredited += coins
		if bought {
			allBought += coins
			v := boughtByCurrency[currency]
			boughtByCurrency[currency] = [2]int64{v[0] + coins, v[1] + amount}
		}
	}
	rows.Close()
	valuations := []map[string]any{}
	purchasedShare := 0.0
	if allCredited > 0 {
		purchasedShare = float64(allBought) / float64(allCredited)
	}
	for _, currency := range sortedKeys(boughtByCurrency) {
		v := boughtByCurrency[currency]
		if v[0] == 0 || allBought == 0 {
			continue
		}
		coinsInCurrency := float64(outstanding) * purchasedShare * float64(v[0]) / float64(allBought)
		value := int64(coinsInCurrency * float64(v[1]) / float64(v[0]))
		valuations = append(valuations, map[string]any{
			"currency": currency, "average_price_per_100_coins_minor": int64(float64(v[1]) * 100 / float64(v[0])),
			"estimated_purchased_coins_outstanding": int64(coinsInCurrency),
			"estimated_liability_minor":             value, "estimated_liability": majorUnits(value, currency),
		})
	}
	var windowSources, windowSinks int64
	trendRows := []map[string]any{}
	trendTable := businessTable{Name: "trend", Columns: []string{"bucket", "purchased", "granted", "returned", "gift_spend", "clawback_debits", "net_flow"}}
	for _, label := range businessBucketLabels(p) {
		f := trend[label]
		if f == nil {
			f = &flow{}
		}
		net := f.Purchased + f.Granted + f.Returned - f.Gifts - f.Debits
		windowSources += f.Purchased + f.Granted + f.Returned
		windowSinks += f.Gifts + f.Debits
		trendRows = append(trendRows, map[string]any{"bucket": label, "purchased": f.Purchased, "granted": f.Granted, "returned": f.Returned, "gift_spend": f.Gifts, "clawback_debits": f.Debits, "net_flow": net})
		trendTable.Rows = append(trendTable.Rows, []any{label, f.Purchased, f.Granted, f.Returned, f.Gifts, f.Debits, net})
	}

	payload := businessEnvelope("coins", p)
	payload["data_status"] = s.businessDataStatus(ctx, tx, p)
	payload["sources"] = map[string]any{
		"purchased":   map[string]any{"coins": purchasedCoins, "by_currency": purchases},
		"non_revenue": credits,
		"total_coins": windowSources,
	}
	payload["sinks"] = map[string]any{
		"gifts": map[string]any{
			"paid_sends": paidSends, "coins": paidCoins, "free_sends": freeSends, "senders": suppressCount(senders),
			"refunded_sends": refundedSends, "refunded_coins": refundedCoins, "top_gifts": topGifts,
		},
		"clawbacks":   debits,
		"boosts":      map[string]any{"coins": 0, "note": "Not sold: the pricing strategy rules out boosts and paid exposure."},
		"theme_packs": map[string]any{"coins": 0, "note": "Not built yet; theme packs will be a coin sink when they ship."},
		"total_coins": windowSinks,
	}
	payload["liability"] = map[string]any{
		"outstanding_coins":    outstanding,
		"wallets_with_balance": suppressCount(walletsWithBalance),
		"debt_coins":           debt,
		"frozen_wallets":       suppressCount(frozen),
		"purchased_share":      businessRatio(float64(allBought), float64(allCredited)),
		"valuation":            valuations,
		"note":                 "Point-in-time (now), not windowed. Only the purchased share of outstanding coins is valued, at the average price paid; granted coins carry no cash liability.",
	}
	payload["velocity"] = map[string]any{
		"window_spend_to_outstanding": businessRatio(float64(windowSinks), float64(outstanding)),
		"note":                        "coins spent (gifts + clawbacks) in the window / coins outstanding now",
	}
	payload["trend"] = trendRows
	payload["definitions"] = map[string]string{
		"purchased":       "source=buy wallet credits from a payment provider in the selected mode",
		"granted":         "admin_topup, promo, bootstrap and opening_balance credits (never revenue)",
		"returned":        "gift_refund credits",
		"gift_spend":      "coins paid for gifts (total_cost_coins), by send time",
		"clawback_debits": "coins taken back after refunded or charged-back purchases and debt collection",
	}
	writeBusinessReport(w, p, payload, []businessTable{trendTable})
}
