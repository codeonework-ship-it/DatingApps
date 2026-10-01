package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"sort"
	"strconv"

	"github.com/go-chi/chi/v5"
)

type datePlanSharing struct {
	ContactIDs []string             `json:"contact_ids"`
	Contacts   []datePlanShareGroup `json:"contacts"`
	Version    int                  `json:"version"`
}

// Only the requesting member sees their contact choices. The date never does.
func (s *datePlanService) sharing(ctx context.Context, matchID, planID, actor string) (datePlanSharing, error) {
	out := datePlanSharing{ContactIDs: []string{}, Contacts: []datePlanShareGroup{}}
	var partner string
	err := s.db.QueryRowContext(ctx, `SELECT CASE WHEN proposer_user_id=$3::uuid THEN invitee_user_id ELSE proposer_user_id END::text
 FROM matching.match_date_plans WHERE id=$1::uuid AND match_id=$2::uuid
 AND $3::uuid IN (proposer_user_id,invitee_user_id)`, planID, matchID, actor).Scan(&partner)
	if errors.Is(err, sql.ErrNoRows) {
		return out, errDatePlanNotFound
	}
	if err != nil {
		return out, err
	}
	var raw []byte
	err = s.db.QueryRowContext(ctx, `SELECT to_json(contact_ids),version FROM matching.date_plan_sharing WHERE plan_id=$1::uuid AND user_id=$2::uuid`, planID, actor).Scan(&raw, &out.Version)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return out, err
	}
	if len(raw) > 0 {
		if err = json.Unmarshal(raw, &out.ContactIDs); err != nil {
			return out, err
		}
	}
	rows, err := s.db.QueryContext(ctx, `SELECT u.id::text,COALESCE(NULLIF(u.name,''),'A friend') FROM matching.friend_connections f
 JOIN user_management.users u ON u.id=f.friend_user_id WHERE f.user_id=$1::uuid AND f.status='accepted'
 AND u.is_active AND NOT u.is_banned AND u.id<>$2::uuid AND u.id<>$1::uuid
 AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users b WHERE (b.user_id=$1::uuid AND b.blocked_user_id=u.id) OR (b.user_id=u.id AND b.blocked_user_id=$1::uuid)) ORDER BY u.name,u.id`, actor, partner)
	if err != nil {
		return out, err
	}
	defer rows.Close()
	for rows.Next() {
		var c datePlanShareGroup
		if err = rows.Scan(&c.ID, &c.Name); err != nil {
			return out, err
		}
		out.Contacts = append(out.Contacts, c)
	}
	return out, rows.Err()
}

func (s *datePlanService) updateSharing(ctx context.Context, matchID, planID, actor string, ids []string, version int) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var proposer, invitee, status string
	err = tx.QueryRowContext(ctx, `SELECT proposer_user_id::text,invitee_user_id::text,status FROM matching.match_date_plans
 WHERE id=$1::uuid AND match_id=$2::uuid FOR UPDATE`, planID, matchID).Scan(&proposer, &invitee, &status)
	if errors.Is(err, sql.ErrNoRows) {
		return errDatePlanNotFound
	}
	if err != nil {
		return err
	}
	if actor != proposer && actor != invitee {
		return errDatePlanForbidden
	}
	// Clearing sharing remains available after an unmatch or plan closure.
	if len(ids) > 0 {
		if _, err = activeDatingPair(ctx, tx, matchID, actor, false); err != nil {
			return err
		}
	}
	_, err = tx.ExecContext(ctx, `INSERT INTO matching.date_plan_sharing(plan_id,user_id) VALUES($1::uuid,$2::uuid) ON CONFLICT DO NOTHING`, planID, actor)
	if err != nil {
		return err
	}
	var current int
	if err = tx.QueryRowContext(ctx, `SELECT version FROM matching.date_plan_sharing WHERE plan_id=$1::uuid AND user_id=$2::uuid FOR UPDATE`, planID, actor).Scan(&current); err != nil {
		return err
	}
	if current != version {
		return errDatingConflict
	}
	partner := invitee
	side := "proposer"
	if actor == invitee {
		partner = proposer
		side = "invitee"
	}
	// Validate every recipient. A bad/blocked/group-only ID rejects the entire update.
	for _, id := range ids {
		var valid bool
		err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.friend_connections f JOIN user_management.users u ON u.id=f.friend_user_id
   WHERE f.user_id=$1::uuid AND f.friend_user_id=$2::uuid AND f.status='accepted' AND u.is_active AND NOT u.is_banned
   AND u.id<>$1::uuid AND u.id<>$3::uuid AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users b
    WHERE (b.user_id=$1::uuid AND b.blocked_user_id=u.id) OR (b.user_id=u.id AND b.blocked_user_id=$1::uuid)))`, actor, id, partner).Scan(&valid)
		if err != nil {
			return err
		}
		if !valid {
			return errDatePlanForbidden
		}
	}
	sort.Strings(ids)
	raw, _ := json.Marshal(ids)
	_, err = tx.ExecContext(ctx, `UPDATE matching.date_plan_sharing SET contact_ids=ARRAY(SELECT jsonb_array_elements_text($3::jsonb)::uuid),version=version+1,updated_at=NOW() WHERE plan_id=$1::uuid AND user_id=$2::uuid`, planID, actor, raw)
	if err != nil {
		return err
	}
	// Remove server-side copies and queued deliveries that no longer have consent.
	_, err = tx.ExecContext(ctx, `DELETE FROM matching.friend_activity_feed WHERE metadata->>'plan_id'=$1 AND friend_user_id=$2::uuid
 AND NOT EXISTS(SELECT 1 FROM matching.date_plan_trusted_recipients($1::uuid,$2::uuid,$3::uuid) r WHERE r.recipient_user_id=user_id)`, planID, actor, partner)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `DELETE FROM matching.user_notifications n WHERE n.reference_id=$1::uuid AND n.payload->>'friend_user_id'=$2
 AND NOT EXISTS(SELECT 1 FROM matching.date_plan_trusted_recipients($1::uuid,$2::uuid,$3::uuid) r WHERE r.recipient_user_id=n.recipient_user_id)`, planID, actor, partner)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `UPDATE matching.notification_outbox n SET status='suppressed',processed_at=NOW(),last_error='Plan sharing withdrawn',updated_at=NOW()
 WHERE n.reference_id=$1::uuid AND n.payload->>'friend_user_id'=$2 AND n.status IN ('pending','retry','processing')
 AND NOT EXISTS(SELECT 1 FROM matching.date_plan_trusted_recipients($1::uuid,$2::uuid,$3::uuid) r WHERE r.recipient_user_id=n.recipient_user_id)`, planID, actor, partner)
	if err != nil {
		return err
	}
	if len(ids) > 0 {
		if _, err = tx.ExecContext(ctx, `SELECT matching.notify_date_plan_status($1::uuid,$2::uuid,$3,ARRAY[$4]::text[],FALSE)`, planID, actor, status, side); err != nil {
			return err
		}
	}
	_, err = tx.ExecContext(ctx, `SELECT platform.publish_domain_event('date_plan.sharing_changed',1,'date_plan',$1,'mobile-bff.date-plans',$2::uuid,$2::uuid,NULL,NULL,$3,
 jsonb_build_object('plan_id',$1::text,'contact_count',$4::int,'version',$5::int))`, planID, actor, "plan-sharing:"+planID+":"+actor+":"+strconv.Itoa(current+1), len(ids), current+1)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func (s *Server) datePlanSharingHandler(w http.ResponseWriter, r *http.Request) {
	p, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	svc, err := s.datePlans()
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	match, plan := chi.URLParam(r, "matchID"), chi.URLParam(r, "planID")
	if r.Method == http.MethodPost {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		rawIDs, present := body["contact_ids"]
		if !present || rawIDs == nil {
			writeError(w, 400, errors.New("contact_ids is required"))
			return
		}
		ids, err := parseDatePlanGroupIDs(rawIDs)
		if err != nil {
			writeError(w, 400, errors.New("contact_ids must contain at most 10 contact UUIDs"))
			return
		}
		version, ok := body["expected_version"].(float64)
		if !ok || version < 0 || version != float64(int(version)) {
			writeError(w, 400, errors.New("expected_version is required"))
			return
		}
		if err = svc.updateSharing(r.Context(), match, plan, p.UserID, ids, int(version)); err != nil {
			writeDatePlanError(w, err)
			return
		}
	}
	out, err := svc.sharing(r.Context(), match, plan, p.UserID)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	writeJSON(w, 200, map[string]any{"contact_ids": out.ContactIDs, "contacts": out.Contacts, "version": out.Version})
}
