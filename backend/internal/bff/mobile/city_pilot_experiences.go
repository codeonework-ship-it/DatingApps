package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

func listPilotExperiences(ctx context.Context, db *sql.DB, pilotID, memberID string, admin, open bool) ([]map[string]any, error) {
	rows, err := db.QueryContext(ctx, `SELECT e.id::text,e.title,e.summary,e.city,COALESCE(e.venue_name,''),e.starts_at,x.ends_at,e.registration_closes_at,e.capacity,e.safety_contact,e.status,x.host_name,x.accessibility_note,
 (SELECT COUNT(*) FROM growth.event_registrations a WHERE a.event_id=e.id AND a.status='registered'),
 COALESCE(r.status,''),f.attended,f.worthwhile
 FROM growth.city_pilot_experiences x JOIN growth.events e ON e.id=x.event_id
 LEFT JOIN growth.event_registrations r ON r.event_id=e.id AND r.member_id=NULLIF($2,'')::uuid
 LEFT JOIN growth.city_pilot_feedback f ON f.event_id=e.id AND f.member_id=NULLIF($2,'')::uuid
 WHERE x.pilot_id=$1 AND ($3 OR r.member_id IS NOT NULL OR ($4 AND e.status='published' AND e.starts_at>NOW())) ORDER BY e.starts_at LIMIT 100`, pilotID, memberID, admin, open)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []map[string]any{}
	for rows.Next() {
		var id, title, summary, city, venue, safety, status, host, access, registration string
		var starts, ends, closes time.Time
		var capacity, booked int
		var attended, worthwhile sql.NullBool
		if err = rows.Scan(&id, &title, &summary, &city, &venue, &starts, &ends, &closes, &capacity, &safety, &status, &host, &access, &booked, &registration, &attended, &worthwhile); err != nil {
			return nil, err
		}
		var feedback any
		if attended.Valid {
			feedback = map[string]any{"attended": attended.Bool, "worthwhile": nil}
			if worthwhile.Valid {
				feedback.(map[string]any)["worthwhile"] = worthwhile.Bool
			}
		}
		items = append(items, map[string]any{"id": id, "title": title, "summary": summary, "city": city, "venue": venue, "starts_at": starts, "ends_at": ends, "registration_closes_at": closes, "capacity": capacity, "spaces_remaining": capacity - booked, "safety_contact": safety, "status": status, "host": host, "accessibility": access, "registration": registration, "feedback": feedback, "can_register": open && status == "published" && time.Now().Before(closes) && booked < capacity, "can_feedback": registration == "registered" && status != "cancelled" && time.Now().After(ends) && time.Now().Before(ends.Add(14*24*time.Hour)) && !attended.Valid})
	}
	return items, rows.Err()
}
func (s *Server) adminPilotExperiences(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	p, err := readCityPilot(r.Context(), db, chi.URLParam(r, "pilotID"), false)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	if p == nil {
		pilotBad(w, 404, "Pilot not found")
		return
	}
	items, err := listPilotExperiences(r.Context(), db, p.ID, "", true, false)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true, "experiences": items})
}
func (s *Server) adminCreatePilotExperience(w http.ResponseWriter, r *http.Request) {
	var input struct {
		ID            string    `json:"id"`
		Title         string    `json:"title"`
		Summary       string    `json:"summary"`
		Venue         string    `json:"venue"`
		Host          string    `json:"host"`
		Accessibility string    `json:"accessibility"`
		SafetyContact string    `json:"safety_contact"`
		StartsAt      time.Time `json:"starts_at"`
		EndsAt        time.Time `json:"ends_at"`
		ClosesAt      time.Time `json:"registration_closes_at"`
		Capacity      int       `json:"capacity"`
		HostVetted    bool      `json:"host_vetted"`
	}
	if !pilotBody(w, r, &input) {
		return
	}
	_, idErr := uuid.Parse(input.ID)
	if idErr != nil || len(strings.TrimSpace(input.Title)) < 5 || len(input.Title) > 120 || len(strings.TrimSpace(input.Summary)) < 10 || len(input.Summary) > 1000 || len(strings.TrimSpace(input.Host)) < 3 || len(input.Host) > 120 || len(strings.TrimSpace(input.Venue)) < 5 || len(input.Venue) > 200 || len(strings.TrimSpace(input.Accessibility)) < 10 || len(input.Accessibility) > 1000 || len(strings.TrimSpace(input.SafetyContact)) < 5 || len(input.SafetyContact) > 200 || !input.HostVetted || input.Capacity < 2 || input.Capacity > 30 || !input.ClosesAt.After(time.Now()) || input.ClosesAt.After(input.StartsAt) || !input.EndsAt.After(input.StartsAt) || input.EndsAt.Sub(input.StartsAt) > 6*time.Hour || input.StartsAt.After(time.Now().Add(60*24*time.Hour)) {
		pilotBad(w, 400, "Provide a vetted host, venue, accessibility details and safety contact; use 2–30 free places, a future booking deadline, and a session up to 6 hours within 60 days")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	defer tx.Rollback()
	p, err := readCityPilot(r.Context(), tx, chi.URLParam(r, "pilotID"), true)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	if p == nil || p.Status != "experiences" || !p.SafetyReady || !s.pilotEnabled(r.Context(), tx) {
		pilotBad(w, 409, "Hosted experiences require an approved pilot outcome review")
		return
	}
	var n int
	if err = tx.QueryRowContext(r.Context(), `SELECT COUNT(*) FROM growth.city_pilot_experiences WHERE pilot_id=$1`, p.ID).Scan(&n); err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	if n >= 3 {
		pilotBad(w, 409, "This pilot is limited to three hosted tests. Review outcomes before expanding")
		return
	}
	var exists bool
	err = tx.QueryRowContext(r.Context(), `SELECT EXISTS(SELECT 1 FROM growth.events WHERE id=$1)`, input.ID).Scan(&exists)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	if exists {
		pilotBad(w, 409, "This experience was already submitted. Refresh to see its status")
		return
	}
	principal, _ := requestPrincipal(r)
	_, err = tx.ExecContext(r.Context(), `INSERT INTO growth.events(id,title,summary,city,venue_name,starts_at,registration_closes_at,capacity,safety_contact,status,created_by) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,'published',$10)`, input.ID, input.Title, input.Summary, p.City, input.Venue, input.StartsAt, input.ClosesAt, input.Capacity, input.SafetyContact, principal.UserID)
	if err == nil {
		_, err = tx.ExecContext(r.Context(), `INSERT INTO growth.city_pilot_experiences(event_id,pilot_id,ends_at,host_name,accessibility_note) VALUES($1,$2,$3,$4,$5)`, input.ID, p.ID, input.EndsAt, input.Host, input.Accessibility)
	}
	if err != nil || tx.Commit() != nil {
		pilotBad(w, 503, "Could not publish. Refresh before retrying")
		return
	}
	writeJSON(w, 201, map[string]any{"success": true, "id": input.ID})
}
func (s *Server) adminCancelPilotExperience(w http.ResponseWriter, r *http.Request) {
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	result, err := db.ExecContext(r.Context(), `UPDATE growth.events SET status='cancelled' WHERE id::text=$1 AND id IN(SELECT event_id FROM growth.city_pilot_experiences WHERE pilot_id::text=$2) AND starts_at>NOW() AND status='published'`, chi.URLParam(r, "eventID"), chi.URLParam(r, "pilotID"))
	if err != nil {
		pilotBad(w, 503, "Could not cancel experience")
		return
	}
	n, _ := result.RowsAffected()
	if n == 0 {
		pilotBad(w, 409, "Only an upcoming, published experience can be cancelled")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true})
}
func (s *Server) cityPilotRegistration(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		pilotBad(w, 401, "Sign in first")
		return
	}
	var input struct {
		SafetyAccepted bool `json:"safety_terms_accepted"`
	}
	if r.Method == http.MethodPost && !pilotBody(w, r, &input) {
		return
	}
	eventID := chi.URLParam(r, "eventID")
	if _, err = uuid.Parse(eventID); err != nil {
		pilotBad(w, 404, "Experience unavailable")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	defer tx.Rollback()
	var pilotID string
	err = tx.QueryRowContext(r.Context(), `SELECT pilot_id::text FROM growth.city_pilot_experiences WHERE event_id=$1`, eventID).Scan(&pilotID)
	if errors.Is(err, sql.ErrNoRows) {
		pilotBad(w, 404, "Experience unavailable")
		return
	}
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	p, err := readCityPilot(r.Context(), tx, pilotID, true)
	if err != nil || p == nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	// All bookings/withdrawals/stops acquire pilot then event locks in the same order.
	var capacity int
	var closes time.Time
	var status string
	err = tx.QueryRowContext(r.Context(), `SELECT capacity,registration_closes_at,status FROM growth.events WHERE id=$1 FOR UPDATE`, eventID).Scan(&capacity, &closes, &status)
	if err != nil {
		pilotBad(w, 503, "Experiences unavailable")
		return
	}
	if r.Method == http.MethodDelete {
		_, err = tx.ExecContext(r.Context(), `UPDATE growth.event_registrations SET status='cancelled',updated_at=NOW() WHERE event_id=$1 AND member_id=$2 AND status='registered'`, eventID, principal.UserID)
	} else {
		if !input.SafetyAccepted {
			pilotBad(w, 400, "Read and accept the experience safety guidance")
			return
		}
		var joined, booked bool
		var count int
		err = tx.QueryRowContext(r.Context(), `SELECT EXISTS(SELECT 1 FROM growth.city_pilot_members WHERE pilot_id=$1 AND member_id=$2 AND withdrawn_at IS NULL),EXISTS(SELECT 1 FROM growth.event_registrations WHERE event_id=$3 AND member_id=$2 AND status='registered'),(SELECT COUNT(*) FROM growth.event_registrations WHERE event_id=$3 AND status='registered')`, p.ID, principal.UserID, eventID).Scan(&joined, &booked, &count)
		if err != nil {
			pilotBad(w, 503, "Experiences unavailable")
			return
		}
		if !joined || p.Status != "experiences" || !p.SafetyReady || !s.pilotEnabled(r.Context(), tx) || status != "published" || !time.Now().Before(closes) {
			pilotBad(w, 409, "This experience is not open for booking")
			return
		}
		if booked {
			writeJSON(w, 200, map[string]any{"success": true})
			return
		}
		if count >= capacity {
			pilotBad(w, 409, "This experience is full")
			return
		}
		_, err = tx.ExecContext(r.Context(), `INSERT INTO growth.event_registrations(event_id,member_id,safety_terms_accepted_at) VALUES($1,$2,NOW()) ON CONFLICT(event_id,member_id) DO UPDATE SET status='registered',safety_terms_accepted_at=NOW(),updated_at=NOW()`, eventID, principal.UserID)
	}
	if err != nil || tx.Commit() != nil {
		pilotBad(w, 503, "Could not save your booking. Refresh before retrying")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true})
}
func (s *Server) cityPilotFeedback(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		pilotBad(w, 401, "Sign in first")
		return
	}
	var input struct {
		Attended   *bool `json:"attended"`
		Worthwhile *bool `json:"worthwhile"`
	}
	if !pilotBody(w, r, &input) {
		return
	}
	if input.Attended == nil || (!*input.Attended && input.Worthwhile != nil) {
		pilotBad(w, 400, "Say whether you attended; worthwhile is optional for attendees")
		return
	}
	db, err := s.growthDB()
	if err != nil {
		pilotBad(w, 503, "Feedback unavailable")
		return
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		pilotBad(w, 503, "Feedback unavailable")
		return
	}
	defer tx.Rollback()
	var pilotID string
	err = tx.QueryRowContext(r.Context(), `SELECT pilot_id::text FROM growth.city_pilot_experiences WHERE event_id::text=$1`, chi.URLParam(r, "eventID")).Scan(&pilotID)
	if err != nil {
		pilotBad(w, 404, "Experience unavailable")
		return
	}
	p, err := readCityPilot(r.Context(), tx, pilotID, true)
	if err != nil || p == nil {
		pilotBad(w, 503, "Feedback unavailable")
		return
	}
	result, err := tx.ExecContext(r.Context(), `INSERT INTO growth.city_pilot_feedback(event_id,member_id,attended,worthwhile)
 SELECT e.id,$2,$3,$4 FROM growth.events e JOIN growth.city_pilot_experiences x ON x.event_id=e.id JOIN growth.event_registrations r ON r.event_id=e.id AND r.member_id=$2 AND r.status='registered'
 JOIN growth.city_pilot_members m ON m.pilot_id=x.pilot_id AND m.member_id=$2 AND m.withdrawn_at IS NULL
 WHERE e.id::text=$1 AND e.status<>'cancelled' AND x.ends_at<=NOW() AND x.ends_at>NOW()-INTERVAL '14 days'
 ON CONFLICT(event_id,member_id) DO NOTHING`, chi.URLParam(r, "eventID"), principal.UserID, *input.Attended, input.Worthwhile)
	if err != nil {
		pilotBad(w, 503, "Could not save feedback")
		return
	}
	n, _ := result.RowsAffected()
	if n == 0 {
		pilotBad(w, 409, "Feedback is available once per booking for 14 days after the experience")
		return
	}
	if tx.Commit() != nil {
		pilotBad(w, 503, "Could not save feedback. Refresh before retrying")
		return
	}
	writeJSON(w, 200, map[string]any{"success": true})
}
