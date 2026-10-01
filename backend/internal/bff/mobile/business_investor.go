package mobile

import (
	"context"
	"math"
	"net/http"
	"strconv"
	"time"
)

// adminBusinessInvestorPack is the monthly KPI summary an investor update
// needs: members, MAU, the north star (weekly plans kept per active member),
// revenue, MRR, conversion, ARPPU, churn, and CAC/payback when marketing spend
// has been recorded. Burn is not available from product data.
func (s *Server) adminBusinessInvestorPack(w http.ResponseWriter, r *http.Request) {
	months := 12
	if raw := r.URL.Query().Get("months"); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v >= 1 && v <= 36 {
			months = v
		}
	}
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Months: months, Bucket: "month"})
	if !ok {
		return
	}
	defer done()
	p.Bucket = "month"
	fail := func(err error) { writeError(w, http.StatusBadGateway, err) }
	labels := businessBucketLabels(p)
	index := map[string]int{}
	for i, l := range labels {
		index[l] = i
	}
	n := len(labels)

	// Members: base before the window plus monthly signups.
	var base int64
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM user_management.users u WHERE `+p.memberFilter("u")+` AND u.created_at < $1`, p.Since).Scan(&base); err != nil {
		fail(err)
		return
	}
	newMembers := make([]int64, n)
	newVerified := make([]int64, n)
	rows, err := tx.QueryContext(ctx, `
		SELECT to_char(date_trunc('month', u.created_at AT TIME ZONE $3),'YYYY-MM-DD'), COUNT(*), COUNT(*) FILTER (WHERE u.is_verified)
		FROM user_management.users u WHERE `+p.memberFilter("u")+` AND u.created_at >= $1 AND u.created_at < $2 GROUP BY 1`, p.Since, p.Until, p.TZ)
	if err != nil {
		fail(err)
		return
	}
	for rows.Next() {
		var label string
		var c, v int64
		if err := rows.Scan(&label, &c, &v); err != nil {
			rows.Close()
			fail(err)
			return
		}
		if i, ok := index[label]; ok {
			newMembers[i], newVerified[i] = c, v
		}
	}
	rows.Close()

	plansKept := make([]int64, n)
	rows, err = tx.QueryContext(ctx, `
		SELECT to_char(date_trunc('month', COALESCE(dp.resolved_at, dp.updated_at) AT TIME ZONE $3),'YYYY-MM-DD'), COUNT(*)
		FROM matching.match_date_plans dp
		WHERE dp.status='completed' AND COALESCE(dp.resolved_at, dp.updated_at) >= $1 AND COALESCE(dp.resolved_at, dp.updated_at) < $2 GROUP BY 1`, p.Since, p.Until, p.TZ)
	if err != nil {
		fail(err)
		return
	}
	for rows.Next() {
		var label string
		var c int64
		if err := rows.Scan(&label, &c); err != nil {
			rows.Close()
			fail(err)
			return
		}
		if i, ok := index[label]; ok {
			plansKept[i] = c
		}
	}
	rows.Close()

	// Revenue per month and currency.
	type cell struct{ m, c string }
	revenue := map[cell]*moneyTotals{}
	revRows, err := s.queryRevenueRows(ctx, tx, p)
	if err != nil {
		fail(err)
		return
	}
	selected := map[string]bool{}
	for _, m := range p.modes() {
		selected[m] = true
	}
	currencies := map[string]bool{}
	for _, row := range revRows {
		if !selected[row.Mode] {
			continue
		}
		k := cell{row.Bucket, row.Currency}
		if revenue[k] == nil {
			revenue[k] = &moneyTotals{}
		}
		revenue[k].add(row.Status, row.Count, row.Amount, row.Refunded)
		currencies[row.Currency] = true
	}
	payers := map[cell]int64{}
	rows, err = tx.QueryContext(ctx, `
		SELECT to_char(date_trunc('month', p.created_at AT TIME ZONE $3),'YYYY-MM-DD'), p.currency, COUNT(DISTINCT p.user_id)
		FROM matching.billing_payments_runtime p
		WHERE p.created_at >= $1 AND p.created_at < $2 AND p.status IN ('success','partially_refunded')
		  AND `+businessModeExpr("p", s.stripeTestMode())+` = ANY($4)
		GROUP BY 1,2`, p.Since, p.Until, p.TZ, p.modes())
	if err != nil {
		fail(err)
		return
	}
	for rows.Next() {
		var label, currency string
		var c int64
		if err := rows.Scan(&label, &currency, &c); err != nil {
			rows.Close()
			fail(err)
			return
		}
		payers[cell{label, currency}] = c
	}
	rows.Close()

	// MRR at each month end and churn within each month.
	boundaries, _ := businessBoundaries(p)
	points, err := s.queryMRR(ctx, tx, p, boundaries)
	if err != nil {
		fail(err)
		return
	}
	mrr := map[cell]mrrPoint{}
	for _, pt := range points {
		if pt.I < 2 {
			continue
		}
		// Boundary i (1-based) closes the bucket that starts at boundary i-1.
		label := labels[pt.I-2]
		mrr[cell{label, pt.Currency}] = pt
		currencies[pt.Currency] = true
	}

	// Marketing spend per month and currency.
	spend := map[cell]int64{}
	rows, err = tx.QueryContext(ctx, `
		SELECT to_char(month,'YYYY-MM-DD'), currency, SUM(amount_minor) FROM business.marketing_spend
		WHERE month >= date_trunc('month', $1 AT TIME ZONE $3)::date AND month < ($2 AT TIME ZONE $3)::date GROUP BY 1,2`, p.Since, p.Until, p.TZ)
	if err != nil {
		fail(err)
		return
	}
	spendRecorded := false
	for rows.Next() {
		var label, currency string
		var amount int64
		if err := rows.Scan(&label, &currency, &amount); err != nil {
			rows.Close()
			fail(err)
			return
		}
		spend[cell{label, currency}] = amount
		currencies[currency] = true
		spendRecorded = true
	}
	rows.Close()

	now := time.Now()
	monthsOut := []map[string]any{}
	table := businessTable{Name: "monthly", Columns: []string{"month", "currency", "members_total", "new_members", "new_verified", "mau", "mau_source", "plans_kept", "north_star", "gross", "net", "mrr", "arr", "subscribers", "paying_members", "arppu", "conversion", "subscriber_churn_rate", "marketing_spend", "cac", "payback_months", "burn"}}
	members := base
	for i, label := range labels {
		members += newMembers[i]
		start, _ := time.ParseInLocation("2006-01-02", label, p.Loc)
		end := start.AddDate(0, 1, 0)
		mau, mauSource := s.monthlyActives(ctx, tx, p, start, end, now)
		weeks := end.Sub(start).Hours() / 24 / 7
		var northStar any
		if mau != nil && *mau >= businessSmallCount {
			northStar = math.Round(float64(plansKept[i])/weeks/float64(*mau)*10000) / 10000
		}
		var mauOut any
		if mau != nil {
			mauOut = suppressCount(*mau)
		}
		perCurrency := []map[string]any{}
		for _, c := range sortedKeys(currencies) {
			k := cell{label, c}
			m := moneyTotals{}
			if revenue[k] != nil {
				m = *revenue[k]
			}
			pt := mrr[k]
			payer := payers[k]
			arppu := perMember(m.Net, payer)
			var conversion, churn any
			if mau != nil && *mau >= businessSmallCount {
				conversion = businessRatio(float64(pt.Subs), float64(*mau))
			}
			if pt.PrevSubs >= businessSmallCount {
				churn = businessRatio(float64(pt.ChurnCount), float64(pt.PrevSubs))
			}
			// ARPU per month uses MAU when known, otherwise all members.
			denominator := members
			if mau != nil && *mau > 0 {
				denominator = *mau
			}
			var cac, payback any
			spendMinor, hasSpend := spend[k]
			if hasSpend && newMembers[i] > 0 {
				cacValue := float64(spendMinor) / float64(newMembers[i])
				cac = int64(math.Round(cacValue))
				if denominator > 0 && m.Net > 0 {
					arpu := float64(m.Net) / float64(denominator)
					payback = math.Round(cacValue/arpu*10) / 10
				}
			}
			var spendOut any = "needs spend data"
			if hasSpend {
				spendOut = majorUnits(spendMinor, c)
			}
			entry := map[string]any{
				"currency": c, "gross_minor": m.Gross, "gross": majorUnits(m.Gross, c), "net_minor": m.Net, "net": majorUnits(m.Net, c),
				"mrr_minor": pt.MRR, "mrr": majorUnits(pt.MRR, c), "arr_minor": pt.MRR * 12, "arr": majorUnits(pt.MRR*12, c),
				"subscribers": suppressCount(pt.Subs), "paying_members": suppressCount(payer),
				"arppu_minor": arppu, "arppu": majorUnitsAny(arppu, c), "conversion": conversion, "subscriber_churn_rate": churn,
				"marketing_spend": spendOut, "cac_minor": cac, "cac": majorUnitsAny(cac, c), "payback_months": payback,
			}
			if !hasSpend {
				entry["cac"] = "needs spend data"
				entry["payback_months"] = "needs spend data"
			}
			perCurrency = append(perCurrency, entry)
			table.Rows = append(table.Rows, []any{label[:7], c, members, suppressCount(newMembers[i]), suppressCount(newVerified[i]), mauOut, mauSource, plansKept[i], northStar, entry["gross"], entry["net"], entry["mrr"], entry["arr"], entry["subscribers"], entry["paying_members"], entry["arppu"], conversion, churn, spendOut, entry["cac"], entry["payback_months"], "not available"})
		}
		if len(currencies) == 0 {
			table.Rows = append(table.Rows, []any{label[:7], "", members, suppressCount(newMembers[i]), suppressCount(newVerified[i]), mauOut, mauSource, plansKept[i], northStar, nil, nil, nil, nil, nil, nil, nil, nil, nil, "needs spend data", "needs spend data", "needs spend data", "not available"})
		}
		monthsOut = append(monthsOut, map[string]any{
			"month": label[:7], "members_total": suppressCount(members), "new_members": suppressCount(newMembers[i]), "new_verified_members": suppressCount(newVerified[i]),
			"mau": mauOut, "mau_source": mauSource, "plans_kept": suppressCount(plansKept[i]), "north_star": northStar,
			"by_currency": perCurrency, "burn": "not available",
		})
	}

	payload := businessEnvelope("investor-pack", p)
	payload["data_status"] = s.businessDataStatus(ctx, tx, p)
	payload["months"] = monthsOut
	payload["inputs"] = map[string]any{
		"marketing_spend":   map[string]any{"recorded": spendRecorded, "path": "/v1/admin/business/marketing-spend", "note": "CAC and payback show \"needs spend data\" until spend is recorded for the month and currency."},
		"burn":              "not available from product data; take it from the finance system",
		"price_assumptions": "PRICING_AND_GO_TO_MARKET_STRATEGY_2026-09-27 sections 3–4",
	}
	payload["definitions"] = map[string]string{
		"members_total":         "Dating members (not operators, not erased) who joined before the month end",
		"mau":                   "Members active in the month; exact only for the current month (last 30 days) unless product analytics snapshots exist",
		"north_star":            "Weekly plans kept per active member: date plans completed in the month / weeks in the month / MAU",
		"mrr":                   "MRR at the month end (see the subscriptions report)",
		"conversion":            "Paying subscribers at month end / MAU (assumption 4–6%)",
		"arppu":                 "Net revenue / members with a settled payment in the month",
		"subscriber_churn_rate": "Subscribers lost in the month / subscribers at the month start",
		"cac":                   "Marketing spend in the month (same currency) / members who joined in the month",
		"payback_months":        "CAC / (net revenue in the month / MAU, or / members when MAU is unknown)",
	}
	writeBusinessReport(w, p, payload, []businessTable{table})
}

// monthlyActives returns MAU for one month when it can be known: from product
// analytics daily snapshots when that report exists, otherwise only for the
// month that contains now (members active in the last 30 days).
func (s *Server) monthlyActives(ctx context.Context, q businessQueryer, p businessParams, start, end, now time.Time) (*int64, string) {
	if v, ok := analyticsSnapshotActives(ctx, q, start, end); ok {
		return &v, "analytics daily snapshots"
	}
	if !now.Before(start) && now.Before(end) {
		v, _ := businessActiveMembers(ctx, q, p, now.Add(-30*24*time.Hour), now)
		return &v, "member_last_activity (last 30 days)"
	}
	return nil, "unavailable for past months without analytics snapshots"
}
