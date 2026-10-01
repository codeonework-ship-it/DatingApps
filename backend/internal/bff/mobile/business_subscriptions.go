package mobile

import (
	"context"
	"net/http"
	"time"
)

// MRR is reconstructed from settled subscription payments, because each
// payment row carries the period it pays for (period_start, period_end). A
// subscription contributes to MRR at instant T when its latest settled
// payment covering T is not refunded or charged back and the subscription had
// not ended before T. The run-rate of a period is its amount (net of partial
// refunds) divided by the period length in months; a mid-cycle plan change
// (billing_reason subscription_update, a prorated charge) uses the
// subscription's contracted amount instead.
const businessMRRPeriodsCTE = `
	b AS (SELECT t.at, t.i FROM unnest($1::timestamptz[]) WITH ORDINALITY AS t(at, i)),
	periods AS (
	  SELECT p.user_id, p.subscription_id, p.currency, p.period_start, p.period_end, p.created_at,
	         CASE WHEN p.billing_reason='subscription_update' AND s.amount_minor IS NOT NULL
	              THEN s.amount_minor::numeric / CASE WHEN s.billing_cycle='yearly' THEN 12 ELSE 1 END
	              ELSE (p.amount_paise - CASE WHEN p.status='partially_refunded' THEN p.refunded_amount_paise ELSE 0 END)::numeric
	                   / GREATEST(1, ROUND(EXTRACT(EPOCH FROM (p.period_end - p.period_start)) / 2629800.0))
	         END AS mrr,
	         s.status AS sub_status, s.end_date
	  FROM matching.billing_payments_runtime p
	  JOIN matching.billing_subscriptions_runtime s ON s.id = p.subscription_id
	  WHERE p.status IN ('success','partially_refunded','disputed')
	    AND p.period_start IS NOT NULL AND p.period_end > p.period_start
	    AND p.period_start <= $3 AND p.period_end > $2
	    AND %s = ANY($4)
	),
	cover AS (
	  SELECT DISTINCT ON (b.i, pe.subscription_id) b.i, pe.user_id, pe.subscription_id, pe.currency, pe.mrr
	  FROM b JOIN periods pe ON pe.period_start <= b.at AND pe.period_end > b.at
	   AND NOT (pe.sub_status IN ('cancelled','expired') AND pe.end_date IS NOT NULL AND pe.end_date <= b.at)
	  ORDER BY b.i, pe.subscription_id, pe.created_at DESC
	),
	per_user AS (SELECT i, user_id, currency, SUM(mrr) AS mrr FROM cover GROUP BY 1,2,3),
	keys AS (SELECT DISTINCT user_id, currency FROM per_user),
	grid AS (
	  SELECT b.i, k.user_id, k.currency, COALESCE(pu.mrr, 0) AS mrr
	  FROM b CROSS JOIN keys k
	  LEFT JOIN per_user pu ON pu.i=b.i AND pu.user_id=k.user_id AND pu.currency=k.currency
	),
	moves AS (
	  SELECT i, user_id, currency, mrr, LAG(mrr) OVER (PARTITION BY user_id, currency ORDER BY i) AS prev FROM grid
	)`

type mrrPoint struct {
	I                                                                          int
	Currency                                                                   string
	MRR, Subs, PrevMRR, PrevSubs                                               int64
	NewMRR, NewCount, ExpMRR, ExpCount, ConMRR, ConCount, ChurnMRR, ChurnCount int64
}

func (s *Server) queryMRR(ctx context.Context, q businessQueryer, p businessParams, boundaries []time.Time) ([]mrrPoint, error) {
	query := `WITH ` + sprintfMode(businessMRRPeriodsCTE, businessModeExpr("p", s.stripeTestMode())) + `
		SELECT i, currency,
		  ROUND(SUM(mrr))::bigint, COUNT(*) FILTER (WHERE mrr > 0),
		  ROUND(COALESCE(SUM(prev),0))::bigint, COUNT(*) FILTER (WHERE prev > 0),
		  ROUND(COALESCE(SUM(mrr) FILTER (WHERE prev = 0 AND mrr > 0),0))::bigint, COUNT(*) FILTER (WHERE prev = 0 AND mrr > 0),
		  ROUND(COALESCE(SUM(mrr - prev) FILTER (WHERE prev > 0 AND mrr > prev),0))::bigint, COUNT(*) FILTER (WHERE prev > 0 AND mrr > prev),
		  ROUND(COALESCE(SUM(prev - mrr) FILTER (WHERE prev > 0 AND mrr > 0 AND mrr < prev),0))::bigint, COUNT(*) FILTER (WHERE prev > 0 AND mrr > 0 AND mrr < prev),
		  ROUND(COALESCE(SUM(prev) FILTER (WHERE prev > 0 AND mrr = 0),0))::bigint, COUNT(*) FILTER (WHERE prev > 0 AND mrr = 0)
		FROM moves GROUP BY i, currency ORDER BY i, currency`
	rows, err := q.QueryContext(ctx, query, boundaries, boundaries[0], boundaries[len(boundaries)-1], p.modes())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []mrrPoint{}
	for rows.Next() {
		var pt mrrPoint
		if err := rows.Scan(&pt.I, &pt.Currency, &pt.MRR, &pt.Subs, &pt.PrevMRR, &pt.PrevSubs,
			&pt.NewMRR, &pt.NewCount, &pt.ExpMRR, &pt.ExpCount, &pt.ConMRR, &pt.ConCount, &pt.ChurnMRR, &pt.ChurnCount); err != nil {
			return nil, err
		}
		out = append(out, pt)
	}
	return out, rows.Err()
}

// queryChurnReasons classifies each subscriber who went from paying to not
// paying between two boundaries. Graduation (leaving Connect as a couple) is
// healthy churn and is reported separately.
func (s *Server) queryChurnReasons(ctx context.Context, q businessQueryer, p businessParams, boundaries []time.Time) (map[int]map[string]int64, error) {
	query := `WITH ` + sprintfMode(businessMRRPeriodsCTE, businessModeExpr("p", s.stripeTestMode())) + `,
		churned AS (SELECT m.i, m.user_id, m.currency FROM moves m WHERE m.prev > 0 AND m.mrr = 0)
		SELECT ch.i,
		  CASE
		    WHEN EXISTS (SELECT 1 FROM matching.match_graduations g
		                 WHERE g.status='confirmed' AND (g.proposer_user_id=ch.user_id OR g.partner_user_id=ch.user_id)
		                   AND g.decided_at < b.at AND g.decided_at >= b.at - interval '120 days') THEN 'graduated'
		    WHEN ls.id IS NULL THEN 'other'
		    WHEN ls.metadata->>'ended_reason' = 'chargeback' THEN 'chargeback'
		    WHEN EXISTS (SELECT 1 FROM matching.billing_payments_runtime rp WHERE rp.subscription_id=ls.id AND rp.status='refunded') THEN 'refunded'
		    WHEN ls.status='expired' AND NOT ls.cancel_at_period_end AND ls.cancelled_at IS NULL THEN 'payment_failed'
		    WHEN ls.cancel_at_period_end OR ls.cancelled_at IS NOT NULL OR ls.status IN ('cancelled','expired') THEN 'member_cancelled'
		    ELSE 'other'
		  END AS reason,
		  COUNT(*)
		FROM churned ch
		JOIN b ON b.i = ch.i
		LEFT JOIN LATERAL (
		  SELECT s.id, s.status, s.metadata, s.cancel_at_period_end, s.cancelled_at
		  FROM matching.billing_subscriptions_runtime s
		  WHERE s.user_id=ch.user_id AND s.currency=ch.currency AND s.start_date < b.at
		  ORDER BY s.start_date DESC LIMIT 1
		) ls ON TRUE
		GROUP BY 1,2`
	rows, err := q.QueryContext(ctx, query, boundaries, boundaries[0], boundaries[len(boundaries)-1], p.modes())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[int]map[string]int64{}
	for rows.Next() {
		var i int
		var reason string
		var n int64
		if err := rows.Scan(&i, &reason, &n); err != nil {
			return nil, err
		}
		if out[i] == nil {
			out[i] = map[string]int64{}
		}
		out[i][reason] += n
	}
	return out, rows.Err()
}

func sprintfMode(template, modeExpr string) string {
	// The template has exactly one %s (the mode expression); avoid fmt so
	// the SQL's own % characters never need escaping.
	for i := 0; i+1 < len(template); i++ {
		if template[i] == '%' && template[i+1] == 's' {
			return template[:i] + modeExpr + template[i+2:]
		}
	}
	return template
}

var churnReasons = []string{"member_cancelled", "payment_failed", "refunded", "chargeback", "graduated", "other"}

func (s *Server) adminBusinessSubscriptions(w http.ResponseWriter, r *http.Request) {
	p, tx, ctx, done, ok := s.businessBegin(w, r, businessDefaults{Months: 12, Bucket: "month"})
	if !ok {
		return
	}
	defer done()
	boundaries, labels := businessBoundaries(p)
	points, err := s.queryMRR(ctx, tx, p, boundaries)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	reasons, err := s.queryChurnReasons(ctx, tx, p, boundaries)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	byIndex := map[int]map[string]mrrPoint{}
	currencies := map[string]bool{}
	for _, pt := range points {
		if byIndex[pt.I] == nil {
			byIndex[pt.I] = map[string]mrrPoint{}
		}
		byIndex[pt.I][pt.Currency] = pt
		currencies[pt.Currency] = true
	}

	snapshots := []map[string]any{}
	snapTable := businessTable{Name: "mrr", Columns: []string{"at", "currency", "mrr", "arr", "active_subscribers"}}
	for i := range boundaries {
		for _, c := range sortedKeys(currencies) {
			pt := byIndex[i+1][c]
			label := labels[i]
			snapshots = append(snapshots, map[string]any{
				"at": boundaries[i].UTC().Format(time.RFC3339), "label": label, "currency": c,
				"mrr_minor": pt.MRR, "mrr": majorUnits(pt.MRR, c), "arr_minor": pt.MRR * 12, "arr": majorUnits(pt.MRR*12, c),
				"active_subscribers": suppressCount(pt.Subs),
			})
			snapTable.Rows = append(snapTable.Rows, []any{boundaries[i].In(p.Loc).Format(time.RFC3339), c, majorUnits(pt.MRR, c), majorUnits(pt.MRR*12, c), suppressCount(pt.Subs)})
		}
	}

	movements := []map[string]any{}
	moveTable := businessTable{Name: "movements", Columns: []string{"bucket", "currency", "mrr_start", "new", "expansion", "contraction", "churned", "mrr_end", "subscribers_start", "new_subscribers", "churned_subscribers", "subscribers_end", "logo_churn_rate", "revenue_churn_rate"}}
	reasonTable := businessTable{Name: "churn_reasons", Columns: []string{"bucket", "reason", "subscribers"}}
	reasonTotals := map[string]int64{}
	var churnedTotal, startTotal, graduatedTotal int64
	for i := 1; i < len(boundaries); i++ {
		for _, c := range sortedKeys(currencies) {
			pt := byIndex[i+1][c]
			logo := businessRatio(float64(pt.ChurnCount), float64(pt.PrevSubs))
			if pt.PrevSubs < businessSmallCount {
				logo = nil
			}
			movements = append(movements, map[string]any{
				"bucket": labels[i-1], "currency": c,
				"mrr_start_minor": pt.PrevMRR, "new_minor": pt.NewMRR, "expansion_minor": pt.ExpMRR,
				"contraction_minor": pt.ConMRR, "churned_minor": pt.ChurnMRR, "mrr_end_minor": pt.MRR,
				"mrr_start": majorUnits(pt.PrevMRR, c), "new": majorUnits(pt.NewMRR, c), "expansion": majorUnits(pt.ExpMRR, c),
				"contraction": majorUnits(pt.ConMRR, c), "churned": majorUnits(pt.ChurnMRR, c), "mrr_end": majorUnits(pt.MRR, c),
				"subscribers_start": suppressCount(pt.PrevSubs), "new_subscribers": suppressCount(pt.NewCount),
				"expanded_subscribers": suppressCount(pt.ExpCount), "contracted_subscribers": suppressCount(pt.ConCount),
				"churned_subscribers": suppressCount(pt.ChurnCount), "subscribers_end": suppressCount(pt.Subs),
				"logo_churn_rate":    logo,
				"revenue_churn_rate": businessRatio(float64(pt.ChurnMRR+pt.ConMRR), float64(pt.PrevMRR)),
				"net_mrr_retention":  businessRatio(float64(pt.PrevMRR+pt.ExpMRR-pt.ConMRR-pt.ChurnMRR), float64(pt.PrevMRR)),
			})
			moveTable.Rows = append(moveTable.Rows, []any{labels[i-1], c, majorUnits(pt.PrevMRR, c), majorUnits(pt.NewMRR, c), majorUnits(pt.ExpMRR, c), majorUnits(pt.ConMRR, c), majorUnits(pt.ChurnMRR, c), majorUnits(pt.MRR, c), suppressCount(pt.PrevSubs), suppressCount(pt.NewCount), suppressCount(pt.ChurnCount), suppressCount(pt.Subs), logo, businessRatio(float64(pt.ChurnMRR+pt.ConMRR), float64(pt.PrevMRR))})
			churnedTotal += pt.ChurnCount
			startTotal += pt.PrevSubs
		}
		for _, reason := range churnReasons {
			n := reasons[i+1][reason]
			reasonTotals[reason] += n
			if reason == "graduated" {
				graduatedTotal += n
			}
			if n > 0 {
				reasonTable.Rows = append(reasonTable.Rows, []any{labels[i-1], reason, suppressCount(n)})
			}
		}
	}
	reasonRows := []map[string]any{}
	for _, reason := range churnReasons {
		reasonRows = append(reasonRows, map[string]any{"reason": reason, "subscribers": suppressCount(reasonTotals[reason]), "healthy": reason == "graduated"})
	}
	var avgChurn, avgChurnExGrad any
	if startTotal >= businessSmallCount {
		avgChurn = businessRatio(float64(churnedTotal), float64(startTotal))
		avgChurnExGrad = businessRatio(float64(churnedTotal-graduatedTotal), float64(startTotal))
	}

	// Current plan mix for the selected mode.
	planRows := []map[string]any{}
	planTable := businessTable{Name: "plan_mix", Columns: []string{"plan", "billing_cycle", "currency", "active_subscribers", "cancel_at_period_end"}}
	rows, err := tx.QueryContext(ctx, `
		SELECT s.plan_code, s.billing_cycle, s.currency, COUNT(*), COUNT(*) FILTER (WHERE s.cancel_at_period_end)
		FROM matching.billing_subscriptions_runtime s
		WHERE s.status IN ('active','past_due') AND `+businessModeExpr("s", s.stripeTestMode())+` = ANY($1)
		GROUP BY 1,2,3 ORDER BY 1,2,3`, p.modes())
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	for rows.Next() {
		var plan, cycle, currency string
		var n, ending int64
		if err := rows.Scan(&plan, &cycle, &currency, &n, &ending); err != nil {
			rows.Close()
			writeError(w, http.StatusBadGateway, err)
			return
		}
		planRows = append(planRows, map[string]any{"plan": plan, "billing_cycle": cycle, "currency": currency, "active_subscribers": suppressCount(n), "cancel_at_period_end": suppressCount(ending)})
		planTable.Rows = append(planTable.Rows, []any{plan, cycle, currency, suppressCount(n), suppressCount(ending)})
	}
	rows.Close()

	graduation, err := s.graduationRefundModel(ctx, tx, p)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}

	payload := businessEnvelope("subscriptions", p)
	payload["data_status"] = s.businessDataStatus(ctx, tx, p)
	payload["mrr"] = snapshots
	payload["movements"] = movements
	payload["churn"] = map[string]any{
		"reasons":                               reasonRows,
		"average_logo_churn_rate":               avgChurn,
		"average_logo_churn_rate_ex_graduation": avgChurnExGrad,
		"note":                                  "Cancellation reasons are not captured from members yet; reasons are inferred from subscription state. Graduation is healthy churn.",
	}
	payload["plan_mix"] = planRows
	payload["trials"] = map[string]any{"offered": false, "note": "Billing has no trial primitive, so trial-to-paid is not applicable."}
	payload["graduation_refund"] = graduation
	payload["definitions"] = map[string]string{
		"mrr":            "Sum over subscribers of the monthly run-rate of the settled payment period covering the instant (amount net of partial refunds / period months); refunded and charged-back periods and ended subscriptions do not count",
		"arr":            "mrr × 12",
		"movements":      "Per subscriber and currency between consecutive boundaries: new (0 → >0), expansion (up), contraction (down, still >0), churned (>0 → 0). mrr_start + new + expansion - contraction - churned = mrr_end (± rounding)",
		"logo_churn":     "churned subscribers / subscribers at the bucket start",
		"revenue_churn":  "(churned + contraction MRR) / MRR at the bucket start",
		"snapshot_limit": "A subscriber who starts and churns between two boundaries is not seen; use day buckets for precision",
	}
	writeBusinessReport(w, p, payload, []businessTable{moveTable, snapTable, reasonTable, planTable})
}

// graduationRefundModel estimates the cost of the Graduation Refund: unused
// whole months of the member's plan at graduation (after at least one month
// on the plan), valued at the plan's monthly run-rate. Billing has no pause
// or refund primitive yet, so this is a model, not money that moved.
func (s *Server) graduationRefundModel(ctx context.Context, q businessQueryer, p businessParams) (map[string]any, error) {
	rows, err := q.QueryContext(ctx, `
		SELECT kind, status, COUNT(*) FROM matching.graduation_rewards
		WHERE created_at >= $1 AND created_at < $2 GROUP BY 1,2 ORDER BY 1,2`, p.Since, p.Until)
	if err != nil {
		return nil, err
	}
	rewards := []map[string]any{}
	for rows.Next() {
		var kind, status string
		var n int64
		if err := rows.Scan(&kind, &status, &n); err != nil {
			rows.Close()
			return nil, err
		}
		rewards = append(rewards, map[string]any{"kind": kind, "status": status, "members": suppressCount(n)})
	}
	rows.Close()
	rows, err = q.QueryContext(ctx, `
		SELECT s.currency, COUNT(*),
		       COALESCE(SUM(FLOOR(GREATEST(0, EXTRACT(EPOCH FROM (s.current_period_end - gr.created_at))) / 2629800.0)
		                    * (s.amount_minor::numeric / CASE WHEN s.billing_cycle='yearly' THEN 12 ELSE 1 END)),0)::bigint
		FROM matching.graduation_rewards gr
		JOIN LATERAL (
		  SELECT sub.* FROM matching.billing_subscriptions_runtime sub
		  WHERE sub.user_id=gr.user_id AND sub.start_date <= gr.created_at
		  ORDER BY sub.start_date DESC LIMIT 1
		) s ON TRUE
		WHERE gr.kind='subscription_pause' AND gr.created_at >= $1 AND gr.created_at < $2
		  AND s.amount_minor IS NOT NULL AND s.current_period_end IS NOT NULL
		  AND gr.created_at >= s.start_date + interval '1 month'
		  AND `+businessModeExpr("s", s.stripeTestMode())+` = ANY($3)
		GROUP BY 1 ORDER BY 1`, p.Since, p.Until, p.modes())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	costs := []map[string]any{}
	for rows.Next() {
		var currency string
		var n, cost int64
		if err := rows.Scan(&currency, &n, &cost); err != nil {
			return nil, err
		}
		costs = append(costs, map[string]any{"currency": currency, "eligible_members": suppressCount(n), "estimated_cost_minor": cost, "estimated_cost": majorUnits(cost, currency)})
	}
	return map[string]any{
		"rewards":         rewards,
		"estimated_costs": costs,
		"modelled":        true,
		"note":            "Estimate: unused whole months at graduation × monthly run-rate, for members on the plan at least one month. Billing has no pause/refund primitive yet; no money has moved.",
	}, rows.Err()
}
