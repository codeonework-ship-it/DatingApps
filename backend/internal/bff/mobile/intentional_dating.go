package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

var errDatingConflict = errors.New("This has changed. Refresh before trying again.")

type datingWindow struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}
type datingPreferences struct {
	Intent            string         `json:"intent"`
	Pace              string         `json:"pace"`
	PaceStatus        string         `json:"pace_status"`
	SharePace         bool           `json:"share_pace"`
	Activities        []string       `json:"activities"`
	ShareAvailability bool           `json:"share_availability"`
	Availability      []datingWindow `json:"availability"`
	AllowFriendIntros bool           `json:"allow_friend_intros"`
	IntroSharePhoto   bool           `json:"intro_share_photo"`
	IntroShareCity    bool           `json:"intro_share_city"`
	Version           int            `json:"version"`
}

func emptyDatingPreferences() datingPreferences {
	return datingPreferences{Activities: []string{}, Availability: []datingWindow{}}
}
func datingChoice(value string, choices ...string) bool {
	for _, v := range choices {
		if v == value {
			return true
		}
	}
	return false
}
func parseDatingPreferences(payload map[string]any, now time.Time) (datingPreferences, error) {
	p := emptyDatingPreferences()
	raw, err := json.Marshal(payload)
	if err != nil {
		return p, err
	}
	if err = json.Unmarshal(raw, &p); err != nil {
		return p, errors.New("Invalid dating preferences")
	}
	if !datingChoice(p.Intent, "", "relationship", "exploring", "casual") || !datingChoice(p.Pace, "", "slow", "steady", "frequent") || !datingChoice(p.PaceStatus, "", "slow_week") || p.Version < 0 {
		return p, errors.New("Choose a supported intent and communication pace")
	}
	if len(p.Activities) > 5 || len(p.Availability) > 21 {
		return p, errors.New("Choose up to five activities and 21 broad time windows")
	}
	seen := map[string]bool{}
	activities := []string{}
	for _, a := range p.Activities {
		if !allowedDatePlanVenues[a] {
			return p, errors.New("Choose a supported first-date activity")
		}
		if !seen[a] {
			activities = append(activities, a)
			seen[a] = true
		}
	}
	p.Activities = activities
	windows := []datingWindow{}
	if p.ShareAvailability {
		for _, w := range p.Availability {
			if !w.End.After(now) {
				continue
			}
			if !w.End.After(w.Start) || w.End.Sub(w.Start) < time.Hour || w.End.Sub(w.Start) > 6*time.Hour || w.Start.Before(now.Add(-6*time.Hour)) || w.End.After(now.Add(15*24*time.Hour)) {
				return p, errors.New("Availability must be a one-to-six-hour window within the next two weeks")
			}
			w.Start = w.Start.UTC()
			w.End = w.End.UTC()
			windows = append(windows, w)
		}
	}
	sort.Slice(windows, func(i, j int) bool { return windows[i].Start.Before(windows[j].Start) })
	for i := 1; i < len(windows); i++ {
		if windows[i].Start.Before(windows[i-1].End) {
			return p, errors.New("Availability windows cannot overlap")
		}
	}
	p.Availability = windows
	if !p.AllowFriendIntros {
		p.IntroSharePhoto = false
		p.IntroShareCity = false
	}
	return p, nil
}

type datingQuerier interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}

func loadDatingPreferences(ctx context.Context, q datingQuerier, id string, now time.Time) (datingPreferences, error) {
	p := emptyDatingPreferences()
	var activities, availability []byte
	err := q.QueryRowContext(ctx, `SELECT intent,pace,pace_status,share_pace,activities,share_availability,availability,allow_friend_intros,intro_share_photo,intro_share_city,version,updated_at FROM matching.dating_preferences WHERE user_id=$1::uuid`, id)
	var updated time.Time
	e := err.Scan(&p.Intent, &p.Pace, &p.PaceStatus, &p.SharePace, &activities, &p.ShareAvailability, &availability, &p.AllowFriendIntros, &p.IntroSharePhoto, &p.IntroShareCity, &p.Version, &updated)
	if errors.Is(e, sql.ErrNoRows) {
		return p, nil
	}
	if e != nil {
		return p, e
	}
	if e = json.Unmarshal(activities, &p.Activities); e != nil {
		return p, e
	}
	if e = json.Unmarshal(availability, &p.Availability); e != nil {
		return p, e
	}
	valid := []datingWindow{}
	if p.ShareAvailability {
		for _, w := range p.Availability {
			if w.End.After(now) {
				valid = append(valid, w)
			}
		}
	}
	p.Availability = valid
	if now.Sub(updated) > 7*24*time.Hour {
		p.PaceStatus = ""
	}
	return p, nil
}
func saveDatingPreferences(ctx context.Context, db *sql.DB, id string, p datingPreferences) (datingPreferences, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return p, err
	}
	defer tx.Rollback()
	a, _ := json.Marshal(p.Activities)
	w, _ := json.Marshal(p.Availability)
	// Lock the owning member, including the first write when no preference row exists.
	var owner string
	if err = tx.QueryRowContext(ctx, `SELECT id::text FROM user_management.users WHERE id=$1::uuid FOR UPDATE`, id).Scan(&owner); err != nil {
		return p, err
	}
	old, err := loadDatingPreferences(ctx, tx, id, time.Now().UTC())
	if err != nil {
		return p, err
	}
	if old.Version != p.Version {
		return p, errDatingConflict
	}
	err = tx.QueryRowContext(ctx, `INSERT INTO matching.dating_preferences(user_id,intent,pace,pace_status,share_pace,activities,share_availability,availability,allow_friend_intros,intro_share_photo,intro_share_city)
 VALUES($1::uuid,$2,$3,$4,$5,$6::jsonb,$7,$8::jsonb,$9,$10,$11)
 ON CONFLICT(user_id) DO UPDATE SET intent=EXCLUDED.intent,pace=EXCLUDED.pace,pace_status=EXCLUDED.pace_status,share_pace=EXCLUDED.share_pace,activities=EXCLUDED.activities,share_availability=EXCLUDED.share_availability,availability=EXCLUDED.availability,allow_friend_intros=EXCLUDED.allow_friend_intros,intro_share_photo=EXCLUDED.intro_share_photo,intro_share_city=EXCLUDED.intro_share_city,version=matching.dating_preferences.version+1,updated_at=NOW() RETURNING version`, id, p.Intent, p.Pace, p.PaceStatus, p.SharePace, string(a), p.ShareAvailability, string(w), p.AllowFriendIntros, p.IntroSharePhoto, p.IntroShareCity).Scan(&p.Version)
	if err != nil {
		return p, err
	}
	// A consent change must also remove cached explanations in today's sets.
	if _, err = tx.ExecContext(ctx, `DELETE FROM matching.daily_candidate_sets WHERE set_date=(NOW() AT TIME ZONE 'UTC')::date AND (user_id=$1::uuid OR $1::uuid=ANY(candidate_user_ids))`, id); err != nil {
		return p, err
	}
	return p, tx.Commit()
}

func datingOverlap(a, b datingPreferences, now time.Time) []datingWindow {
	out := []datingWindow{}
	if !a.ShareAvailability || !b.ShareAvailability {
		return out
	}
	for _, x := range a.Availability {
		for _, y := range b.Availability {
			start := x.Start
			if y.Start.After(start) {
				start = y.Start
			}
			end := x.End
			if y.End.Before(end) {
				end = y.End
			}
			if start.Before(now) {
				start = now
			}
			if end.Sub(start) >= time.Hour {
				out = append(out, datingWindow{start, end})
			}
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Start.Before(out[j].Start) })
	if len(out) > 7 {
		out = out[:7]
	}
	return out
}
func datingFit(a, b datingPreferences, now time.Time) ([]string, []datingWindow) {
	reasons := []string{}
	if a.Intent != "" && a.Intent == b.Intent {
		reasons = append(reasons, "You want the same kind of connection")
	}
	if a.Pace != "" && a.Pace == b.Pace {
		reasons = append(reasons, "A similar communication pace")
	}
	labels := map[string]string{"coffee": "coffee", "meal": "a meal", "walk": "a walk", "drinks": "drinks", "activity": "an activity", "event": "an event", "video_call": "a video hello", "other": "something a little different"}
	for _, activity := range a.Activities {
		if sharedTagCount([]string{activity}, b.Activities) > 0 {
			reasons = append(reasons, "You both enjoy "+labels[activity])
			break
		}
	}
	overlap := datingOverlap(a, b, now)
	if len(overlap) > 0 {
		reasons = append(reasons, "Your shared availability overlaps")
	}
	return reasons, overlap
}

func (s *Server) datingPreferencesHandler(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	if chi.URLParam(r, "userID") != principal.UserID {
		writeError(w, 403, errDatePlanForbidden)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New("Dating preferences are unavailable"))
		return
	}
	var p datingPreferences
	if r.Method == http.MethodGet {
		p, err = loadDatingPreferences(r.Context(), db, principal.UserID, time.Now().UTC())
	} else {
		payload, ok := readJSON(w, r)
		if !ok {
			return
		}
		p, err = parseDatingPreferences(payload, time.Now().UTC())
		if err != nil {
			writeError(w, 400, err)
			return
		}
		p, err = saveDatingPreferences(r.Context(), db, principal.UserID, p)
	}
	if errors.Is(err, errDatingConflict) {
		writeError(w, 409, err)
		return
	}
	if err != nil {
		writeError(w, 503, errors.New("Unable to save dating preferences"))
		return
	}
	writeJSON(w, 200, map[string]any{"preferences": p})
}

var chemistryPrompts = map[string]map[string]string{
	"sunday":     {"bookstore": "Bookstore and coffee", "outdoors": "A walk somewhere green", "food": "Find a new brunch spot"},
	"adventure":  {"explore": "Explore a new neighbourhood", "create": "Make something together", "music": "Find live music"},
	"first_date": {"coffee": "A relaxed coffee", "walk": "A daytime walk", "activity": "A playful shared activity"},
}

type chemistryView struct {
	ID            string            `json:"id"`
	Prompt        string            `json:"prompt"`
	Status        string            `json:"status"`
	MyAnswer      string            `json:"my_answer,omitempty"`
	PartnerAnswer string            `json:"partner_answer,omitempty"`
	Options       map[string]string `json:"options"`
}

func activeDatingPair(ctx context.Context, db datingQuerier, match, actor string, lock bool) (string, error) {
	if _, err := uuid.Parse(match); err != nil {
		return "", errDatePlanNotFound
	}
	query := `SELECT user_id_1::text,user_id_2::text FROM matching.matches m WHERE m.id=$1::uuid AND m.unmatched_at IS NULL AND m.user_1_status='active' AND m.user_2_status='active' AND NOT m.user_1_blocked AND NOT m.user_2_blocked
 AND NOT EXISTS(SELECT 1 FROM user_management.users u WHERE u.id IN (m.user_id_1,m.user_id_2) AND (NOT u.is_active OR u.deactivated_at IS NOT NULL OR u.deletion_requested_at IS NOT NULL))
 AND NOT EXISTS(SELECT 1 FROM user_management.blocked_users b WHERE (b.user_id=m.user_id_1 AND b.blocked_user_id=m.user_id_2) OR (b.user_id=m.user_id_2 AND b.blocked_user_id=m.user_id_1))`
	if lock {
		query += " FOR UPDATE OF m"
	}
	var a, b string
	err := db.QueryRowContext(ctx, query, match).Scan(&a, &b)
	if errors.Is(err, sql.ErrNoRows) {
		return "", errDatePlanNotFound
	}
	if err != nil {
		return "", err
	}
	if actor == a {
		return b, nil
	}
	if actor == b {
		return a, nil
	}
	return "", errDatePlanForbidden
}
func loadChemistry(ctx context.Context, q datingQuerier, match, actor, partner string, ids ...string) (*chemistryView, error) {
	id := ""
	if len(ids) > 0 {
		id = ids[0]
	}
	v := chemistryView{}
	var expires time.Time
	var mine, theirs sql.NullString
	err := q.QueryRowContext(ctx, `SELECT m.id::text,m.prompt,m.expires_at,a.answer,b.answer FROM matching.chemistry_moments m
 LEFT JOIN matching.chemistry_answers a ON a.moment_id=m.id AND a.user_id=$2::uuid
 LEFT JOIN matching.chemistry_answers b ON b.moment_id=m.id AND b.user_id=$3::uuid
 WHERE m.match_id=$1::uuid AND ($4='' OR m.id::text=$4) ORDER BY m.created_at DESC,m.id DESC LIMIT 1`, match, actor, partner, id).Scan(&v.ID, &v.Prompt, &expires, &mine, &theirs)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	v.Options = chemistryPrompts[v.Prompt]
	v.Status = "open"
	v.MyAnswer = mine.String
	if mine.Valid && theirs.Valid {
		v.Status = "revealed"
		v.PartnerAnswer = theirs.String
	} else if time.Now().After(expires) {
		v.Status = "expired"
	} else if mine.Valid {
		v.Status = "waiting"
	}
	return &v, nil
}
func (s *Server) getDatingConnection(w http.ResponseWriter, r *http.Request) {
	p, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New("Connection details are unavailable"))
		return
	}
	match := chi.URLParam(r, "matchID")
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelRepeatableRead, ReadOnly: true})
	if err != nil {
		writeError(w, 503, errors.New("Connection details are unavailable"))
		return
	}
	defer tx.Rollback()
	partner, err := activeDatingPair(r.Context(), tx, match, p.UserID, false)
	if err != nil {
		writeDatePlanError(w, err)
		return
	}
	now := time.Now().UTC()
	a, err := loadDatingPreferences(r.Context(), tx, p.UserID, now)
	if err != nil {
		writeError(w, 503, errors.New("Connection details are unavailable"))
		return
	}
	b, err := loadDatingPreferences(r.Context(), tx, partner, now)
	if err != nil {
		writeError(w, 503, errors.New("Connection details are unavailable"))
		return
	}
	reasons, overlap := datingFit(a, b, now)
	pace := ""
	if b.SharePace {
		pace = b.PaceStatus
	}
	moment, err := loadChemistry(r.Context(), tx, match, p.UserID, partner)
	if err != nil {
		writeError(w, 503, errors.New("Chemistry moments are unavailable"))
		return
	}
	var revision string
	if err = tx.QueryRowContext(r.Context(), `SELECT COALESCE(MAX(updated_at)::text,'') FROM matching.match_date_plans WHERE match_id=$1::uuid`, match).Scan(&revision); err != nil {
		writeError(w, 503, errors.New("Connection details are unavailable"))
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	chapter, err := readChapter(r.Context(), tx, match)
	if err != nil {
		writeError(w, 503, errors.New("Chapter details are unavailable"))
		return
	}
	chapterStatus := ""
	if chapter != nil {
		chapterStatus = "waiting"
		if chapter.Surprise != "" {
			chapterStatus = "complete"
		} else if chapter.Creator != p.UserID {
			chapterStatus = "your_turn"
		}
	}
	writeJSON(w, 200, map[string]any{"reasons": reasons, "overlap": overlap, "partner_pace_status": pace, "moment": moment, "plan_revision": revision, "chapter_status": chapterStatus})
}
func mutateChemistry(ctx context.Context, db *sql.DB, match, actor, id, prompt, answer string) (*chemistryView, error) {
	if _, err := uuid.Parse(id); err != nil {
		return nil, errors.New("Moment id must be a UUID")
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	partner, err := activeDatingPair(ctx, tx, match, actor, true)
	if err != nil {
		return nil, err
	}
	if answer == "" {
		if chemistryPrompts[prompt] == nil {
			return nil, errors.New("Choose a supported chemistry moment")
		}
		var existingMatch, existingPrompt string
		err = tx.QueryRowContext(ctx, `SELECT match_id::text,prompt FROM matching.chemistry_moments WHERE id=$1::uuid`, id).Scan(&existingMatch, &existingPrompt)
		if err == nil {
			if existingMatch != match || existingPrompt != prompt {
				return nil, errDatingConflict
			}
		} else if !errors.Is(err, sql.ErrNoRows) {
			return nil, err
		} else {
			if _, err = tx.ExecContext(ctx, `UPDATE matching.chemistry_moments SET completed_at=NOW() WHERE match_id=$1::uuid AND completed_at IS NULL AND expires_at<=NOW()`, match); err != nil {
				return nil, err
			}
			var n int
			err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.chemistry_moments WHERE match_id=$1::uuid AND (completed_at IS NULL OR created_at>NOW()-INTERVAL '1 day')`, match).Scan(&n)
			if err != nil {
				return nil, err
			}
			if n >= 3 {
				return nil, errors.New("Enjoy your existing moments; try another tomorrow")
			}
			_, err = tx.ExecContext(ctx, `INSERT INTO matching.chemistry_moments(id,match_id,started_by,prompt) VALUES($1::uuid,$2::uuid,$3::uuid,$4)`, id, match, actor, prompt)
			if isUniqueViolation(err) {
				return nil, errDatingConflict
			}
			if err != nil {
				return nil, err
			}
			if err = enqueueNotificationTx(ctx, tx, partner, actor, "chemistry.invited", "message", id, "chemistry:"+id+":invite", "A little chemistry?", "Your match invited you to an optional shared moment.", "/matches", map[string]any{"match_id": match}, 4); err != nil {
				return nil, err
			}
		}
	} else {
		var savedPrompt string
		var expires time.Time
		err = tx.QueryRowContext(ctx, `SELECT prompt,expires_at FROM matching.chemistry_moments WHERE id=$1::uuid AND match_id=$2::uuid FOR UPDATE`, id, match).Scan(&savedPrompt, &expires)
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errDatePlanNotFound
		}
		if err != nil {
			return nil, err
		}
		if !expires.After(time.Now()) {
			return nil, errDatingConflict
		}
		if chemistryPrompts[savedPrompt][answer] == "" {
			return nil, errors.New("Choose one of this moment's answers")
		}
		var old string
		err = tx.QueryRowContext(ctx, `SELECT answer FROM matching.chemistry_answers WHERE moment_id=$1::uuid AND user_id=$2::uuid`, id, actor).Scan(&old)
		if err == nil {
			if old != answer {
				return nil, errDatingConflict
			}
		} else if errors.Is(err, sql.ErrNoRows) {
			if _, err = tx.ExecContext(ctx, `INSERT INTO matching.chemistry_answers(moment_id,user_id,answer) VALUES($1::uuid,$2::uuid,$3)`, id, actor, answer); err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.chemistry_moments SET completed_at=COALESCE(completed_at,NOW()) WHERE id=$1::uuid AND (SELECT COUNT(*) FROM matching.chemistry_answers WHERE moment_id=$1::uuid)=2`, id); err != nil {
			return nil, err
		}
	}
	view, err := loadChemistry(ctx, tx, match, actor, partner, id)
	if err != nil {
		return nil, err
	}
	return view, tx.Commit()
}
func (s *Server) chemistryHandler(w http.ResponseWriter, r *http.Request) {
	p, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, errors.New("Chemistry moments are unavailable"))
		return
	}
	id := chi.URLParam(r, "momentID")
	answer := ""
	if id == "" {
		id = toString(payload["id"])
	} else {
		answer = strings.TrimSpace(toString(payload["answer"]))
		if answer == "" {
			writeError(w, 400, errors.New("Choose an answer"))
			return
		}
	}
	view, err := mutateChemistry(r.Context(), db, chi.URLParam(r, "matchID"), p.UserID, id, toString(payload["prompt"]), answer)
	if err != nil {
		if errors.Is(err, errDatingConflict) {
			writeError(w, 409, err)
		} else if errors.Is(err, errDatePlanForbidden) || errors.Is(err, errDatePlanNotFound) {
			writeDatePlanError(w, err)
		} else {
			writeError(w, 400, errors.New("Unable to save this moment. Check your choice and refresh."))
		}
		return
	}
	writeJSON(w, 200, map[string]any{"moment": view})
}

func loadDatingPreferenceSet(ctx context.Context, db *sql.DB, ids []string) (map[string]datingPreferences, error) {
	out := map[string]datingPreferences{}
	rows, err := db.QueryContext(ctx, `SELECT user_id::text,to_jsonb(p) FROM matching.dating_preferences p WHERE user_id=ANY($1::uuid[])`, ids)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		var raw []byte
		var p datingPreferences
		if err = rows.Scan(&id, &raw); err != nil {
			return nil, err
		}
		if err = json.Unmarshal(raw, &p); err != nil {
			return nil, err
		}
		out[id] = p
	}
	return out, rows.Err()
}

// Extensions to existing routes also honor the intentional-dating rollout.
func (s *Server) requireIntentionalDating(w http.ResponseWriter, r *http.Request) bool {
	const key = "intentional_dating_enabled"
	enabled, err := s.runtimeFeatureEnabled(r.Context(), key, false)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("feature policy is unavailable"))
		return false
	}
	if s.cfg.IsReleaseExcluded(key) || !enabled {
		writeJSON(w, http.StatusForbidden, map[string]any{"error": "This feature is not available right now", "error_code": "FEATURE_DISABLED", "feature_flag": key})
		return false
	}
	return true
}
