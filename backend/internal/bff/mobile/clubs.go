package mobile

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Book & Film Clubs: member-run clubs with a weekly pick, a discussion per
// pick, a shared title catalogue, title reviews and personal lists.

const clubsUnavailable = "Clubs are temporarily unavailable. Please retry."

const (
	clubMaxOwned        = 5
	clubMaxJoined       = 20
	clubMaxPostsPerDay  = 60
	clubMaxLists        = 20
	clubMaxListItems    = 100
	clubMaxTitlesPerDay = 50
	clubPicksWindowDays = 28
)

type clubTitle struct {
	ID            string   `json:"id"`
	Kind          string   `json:"kind"`
	Title         string   `json:"title"`
	Creator       string   `json:"creator"`
	ReleaseYear   *int     `json:"release_year"`
	AverageRating *float64 `json:"average_rating"`
	ReviewCount   int      `json:"review_count"`
}

type clubSelection struct {
	ID        string    `json:"id"`
	WeekStart string    `json:"week_start"`
	Note      string    `json:"note"`
	Title     clubTitle `json:"title"`
	PostCount int       `json:"post_count"`
}

type clubView struct {
	ID               string         `json:"id"`
	Kind             string         `json:"kind"`
	Name             string         `json:"name"`
	Description      string         `json:"description"`
	OwnerID          string         `json:"owner_id"`
	MemberCount      int            `json:"member_count"`
	MyRole           string         `json:"my_role"`
	Version          int            `json:"version"`
	Moderation       string         `json:"moderation_state"`
	CurrentSelection *clubSelection `json:"current_selection"`
	currentID        string
}

type clubMemberView struct {
	UserID   string    `json:"user_id"`
	Name     string    `json:"name"`
	Role     string    `json:"role"`
	JoinedAt time.Time `json:"joined_at"`
}

type clubPost struct {
	ID          string    `json:"id"`
	ClubID      string    `json:"club_id"`
	SelectionID string    `json:"selection_id"`
	AuthorID    string    `json:"author_id"`
	AuthorName  string    `json:"author_name"`
	Body        string    `json:"body"`
	HasSpoilers bool      `json:"has_spoilers"`
	Created     time.Time `json:"created_at"`
	Mine        bool      `json:"mine"`
	Hidden      bool      `json:"hidden"`
	Moderation  string    `json:"moderation_state"`
}

type titleReview struct {
	ID          string    `json:"id"`
	TitleID     string    `json:"title_id"`
	AuthorID    string    `json:"author_id"`
	AuthorName  string    `json:"author_name"`
	Rating      int       `json:"rating"`
	Body        string    `json:"body"`
	HasSpoilers bool      `json:"has_spoilers"`
	Audience    string    `json:"audience"`
	Version     int       `json:"version"`
	Created     time.Time `json:"created_at"`
	Updated     time.Time `json:"updated_at"`
	Mine        bool      `json:"mine"`
	Moderation  string    `json:"moderation_state"`
}

type listItem struct {
	Title    clubTitle `json:"title"`
	Note     string    `json:"note"`
	Position int       `json:"position"`
}

type memberList struct {
	ID         string     `json:"id"`
	OwnerID    string     `json:"owner_id"`
	OwnerName  string     `json:"owner_name"`
	Name       string     `json:"name"`
	Kind       string     `json:"kind"`
	Audience   string     `json:"audience"`
	Version    int        `json:"version"`
	Mine       bool       `json:"mine"`
	Moderation string     `json:"moderation_state"`
	Items      []listItem `json:"items"`
}

// ---------------------------------------------------------------------------
// SQL fragments
// ---------------------------------------------------------------------------

// Title columns with community rating aggregates. Private reviews and
// removed or inactive authors never contribute to the average.
const clubTitleColumns = `t.id::text,t.kind,t.title,t.creator,t.release_year,
 (SELECT AVG(rv.rating)::float8 FROM matching.title_reviews rv JOIN user_management.users u ON u.id=rv.author_id
   WHERE rv.title_id=t.id AND rv.deleted_at IS NULL AND rv.moderation_state='active' AND rv.audience<>'private' AND ` + blogActive + `),
 (SELECT COUNT(*) FROM matching.title_reviews rv JOIN user_management.users u ON u.id=rv.author_id
   WHERE rv.title_id=t.id AND rv.deleted_at IS NULL AND rv.moderation_state='active' AND rv.audience<>'private' AND ` + blogActive + `)`

func scanClubTitle(row interface{ Scan(...any) error }, extra ...any) (clubTitle, error) {
	var t clubTitle
	var year sql.NullInt64
	var avg sql.NullFloat64
	dest := append([]any{&t.ID, &t.Kind, &t.Title, &t.Creator, &year, &avg, &t.ReviewCount}, extra...)
	if err := row.Scan(dest...); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return t, errDatePlanNotFound
		}
		return t, err
	}
	if year.Valid {
		y := int(year.Int64)
		t.ReleaseYear = &y
	}
	if avg.Valid {
		a := float64(int(avg.Float64*10+0.5)) / 10
		t.AverageRating = &a
	}
	return t, nil
}

// clubVisible: viewer $1, club alias c. Owners always see their club;
// everyone else needs an active club, no block with the owner, and either a
// membership or the community bar.
func clubVisible() string {
	return `c.deleted_at IS NULL AND ` + activityActive("$1::uuid") + ` AND ` + activityActive("c.owner_id") + `
 AND (c.owner_id=$1::uuid OR (c.moderation_state='active' AND ` + activityNotBlocked("$1::uuid", "c.owner_id") + `
  AND (EXISTS(SELECT 1 FROM matching.club_members vm WHERE vm.club_id=c.id AND vm.user_id=$1::uuid AND vm.status='active') OR ` + activityCommunity("$1::uuid") + `)))`
}

func clubSelect() string {
	return `SELECT c.id::text,c.kind,c.name,c.description,c.owner_id::text,c.version,c.moderation_state,
 (SELECT COUNT(*) FROM matching.club_members m WHERE m.club_id=c.id AND m.status='active'),
 COALESCE((SELECT m.role FROM matching.club_members m WHERE m.club_id=c.id AND m.user_id=$1::uuid AND m.status='active'),''),
 COALESCE((SELECT s.id::text FROM matching.club_selections s WHERE s.club_id=c.id AND s.week_start=date_trunc('week',NOW() AT TIME ZONE 'UTC')::date),'')
 FROM matching.clubs c WHERE ` + clubVisible()
}

func scanClub(row interface{ Scan(...any) error }) (clubView, error) {
	var c clubView
	err := row.Scan(&c.ID, &c.Kind, &c.Name, &c.Description, &c.OwnerID, &c.Version, &c.Moderation, &c.MemberCount, &c.MyRole, &c.currentID)
	if errors.Is(err, sql.ErrNoRows) {
		return c, errDatePlanNotFound
	}
	return c, err
}

func readClubSelection(ctx context.Context, q blogQuerier, selectionID string) (clubSelection, error) {
	var s clubSelection
	t, err := scanClubTitle(q.QueryRowContext(ctx, `SELECT `+clubTitleColumns+`,s.id::text,s.week_start::text,s.note,
 (SELECT COUNT(*) FROM matching.club_posts p WHERE p.selection_id=s.id AND p.deleted_at IS NULL AND p.moderation_state='active' AND p.hidden_at IS NULL)
 FROM matching.club_selections s JOIN matching.club_titles t ON t.id=s.title_id WHERE s.id=$1::uuid`, selectionID), &s.ID, &s.WeekStart, &s.Note, &s.PostCount)
	s.Title = t
	return s, err
}

func completeClub(ctx context.Context, q blogQuerier, c clubView) (clubView, error) {
	if c.currentID == "" {
		return c, nil
	}
	s, err := readClubSelection(ctx, q, c.currentID)
	if err != nil {
		return c, err
	}
	c.CurrentSelection = &s
	return c, nil
}

func readClub(ctx context.Context, q blogQuerier, actor, clubID string) (clubView, error) {
	c, err := scanClub(q.QueryRowContext(ctx, clubSelect()+` AND c.id=$2::uuid`, actor, clubID))
	if err != nil {
		return c, err
	}
	return completeClub(ctx, q, c)
}

func clubRole(ctx context.Context, q blogQuerier, clubID, actor string) (string, error) {
	var role string
	err := q.QueryRowContext(ctx, `SELECT role FROM matching.club_members WHERE club_id=$1 AND user_id=$2 AND status='active'`, clubID, actor).Scan(&role)
	if errors.Is(err, sql.ErrNoRows) {
		return "", nil
	}
	return role, err
}

func clubManager(role string) bool { return role == "owner" || role == "moderator" }

// clubPostVisible: viewer $1, club $2, viewer-is-manager $3, post alias p.
func clubPostVisible() string {
	return `p.club_id=$2::uuid AND p.deleted_at IS NULL AND ` + activityActive("p.author_id") + ` AND ` + activityNotBlocked("$1::uuid", "p.author_id") + `
 AND (p.author_id=$1::uuid OR p.moderation_state='active') AND (p.hidden_at IS NULL OR p.author_id=$1::uuid OR $3::boolean)`
}

const clubPostColumns = `SELECT p.id::text,p.club_id::text,p.selection_id::text,p.author_id::text,COALESCE(u.name,''),p.body,p.has_spoilers,p.created_at,
 p.author_id=$1::uuid,p.hidden_at IS NOT NULL,p.moderation_state FROM matching.club_posts p JOIN user_management.users u ON u.id=p.author_id WHERE `

func scanClubPost(row interface{ Scan(...any) error }) (clubPost, error) {
	var p clubPost
	err := row.Scan(&p.ID, &p.ClubID, &p.SelectionID, &p.AuthorID, &p.AuthorName, &p.Body, &p.HasSpoilers, &p.Created, &p.Mine, &p.Hidden, &p.Moderation)
	if errors.Is(err, sql.ErrNoRows) {
		return p, errDatePlanNotFound
	}
	return p, err
}

func readClubPost(ctx context.Context, q blogQuerier, actor, clubID, postID string, manager bool) (clubPost, error) {
	return scanClubPost(q.QueryRowContext(ctx, clubPostColumns+clubPostVisible()+` AND p.id=$4::uuid`, actor, clubID, manager, postID))
}

func reviewVisible() string {
	return `rv.deleted_at IS NULL AND ` + activityActive("$1::uuid") + ` AND ` + activityActive("rv.author_id") + `
 AND (rv.author_id=$1::uuid OR rv.moderation_state='active') AND ` + activityAudience("rv.audience", "rv.author_id")
}

func reviewSelect() string {
	return `SELECT rv.id::text,rv.title_id::text,rv.author_id::text,COALESCE(u.name,''),rv.rating,rv.body,rv.has_spoilers,rv.audience,rv.version,
 rv.created_at,rv.updated_at,rv.author_id=$1::uuid,rv.moderation_state
 FROM matching.title_reviews rv JOIN user_management.users u ON u.id=rv.author_id WHERE ` + reviewVisible()
}

func scanReview(row interface{ Scan(...any) error }) (titleReview, error) {
	var v titleReview
	err := row.Scan(&v.ID, &v.TitleID, &v.AuthorID, &v.AuthorName, &v.Rating, &v.Body, &v.HasSpoilers, &v.Audience, &v.Version, &v.Created, &v.Updated, &v.Mine, &v.Moderation)
	if errors.Is(err, sql.ErrNoRows) {
		return v, errDatePlanNotFound
	}
	return v, err
}

func listVisible() string {
	return `l.deleted_at IS NULL AND ` + activityActive("$1::uuid") + ` AND ` + activityActive("l.owner_id") + `
 AND (l.owner_id=$1::uuid OR l.moderation_state='active') AND ` + activityAudience("l.audience", "l.owner_id")
}

func listSelect() string {
	return `SELECT l.id::text,l.owner_id::text,COALESCE(u.name,''),l.name,l.kind,l.audience,l.version,l.owner_id=$1::uuid,l.moderation_state
 FROM matching.member_lists l JOIN user_management.users u ON u.id=l.owner_id WHERE ` + listVisible()
}

func scanList(row interface{ Scan(...any) error }) (memberList, error) {
	l := memberList{Items: []listItem{}}
	err := row.Scan(&l.ID, &l.OwnerID, &l.OwnerName, &l.Name, &l.Kind, &l.Audience, &l.Version, &l.Mine, &l.Moderation)
	if errors.Is(err, sql.ErrNoRows) {
		return l, errDatePlanNotFound
	}
	return l, err
}

func fillListItems(ctx context.Context, q blogQuerier, l *memberList) error {
	rows, err := q.QueryContext(ctx, `SELECT `+clubTitleColumns+`,i.note,i.position FROM matching.member_list_items i
 JOIN matching.club_titles t ON t.id=i.title_id WHERE i.list_id=$1::uuid ORDER BY i.position,i.added_at`, l.ID)
	if err != nil {
		return err
	}
	defer rows.Close()
	l.Items = []listItem{}
	for rows.Next() {
		var item listItem
		t, scanErr := scanClubTitle(rows, &item.Note, &item.Position)
		if scanErr != nil {
			return scanErr
		}
		item.Title = t
		l.Items = append(l.Items, item)
	}
	return rows.Err()
}

func readList(ctx context.Context, q blogQuerier, actor, listID string) (memberList, error) {
	l, err := scanList(q.QueryRowContext(ctx, listSelect()+` AND l.id=$2::uuid`, actor, listID))
	if err != nil {
		return l, err
	}
	return l, fillListItems(ctx, q, &l)
}

// ---------------------------------------------------------------------------
// Input helpers
// ---------------------------------------------------------------------------

func clubVersion(body map[string]any, allowZero bool) (int, error) {
	v, ok := body["expected_version"].(float64)
	lowest := 1.0
	if allowZero {
		lowest = 0
	}
	if !ok || v < lowest || v > 2147483646 || v != float64(int(v)) {
		return 0, blogInputError("A current expected_version is required")
	}
	return int(v), nil
}

func validKind(kind string) bool { return kind == "book" || kind == "film" }

func validAudience(a string) bool { return a == "private" || a == "friends" || a == "community" }

func runeLen(s string) int { return utf8.RuneCountInString(s) }

func normalizeTitleText(s string) string {
	return strings.ToLower(strings.Join(strings.Fields(s), " "))
}

func clubBegin(ctx context.Context, db *sql.DB, actor string) (*sql.Tx, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	if err = lockBlogAuthor(ctx, tx, actor); err != nil {
		_ = tx.Rollback()
		return nil, err
	}
	return tx, nil
}

func (s *Server) clubsContext(w http.ResponseWriter, r *http.Request) (string, *sql.DB, bool) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return "", nil, false
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return "", nil, false
	}
	w.Header().Set("Cache-Control", "private, no-store")
	return actor.UserID, db, true
}

// ---------------------------------------------------------------------------
// Clubs and membership
// ---------------------------------------------------------------------------

func (s *Server) clubsHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	scope := r.URL.Query().Get("scope")
	if scope == "" {
		scope = "mine"
	}
	kind := r.URL.Query().Get("kind")
	if (scope != "mine" && scope != "discover") || (kind != "" && !validKind(kind)) {
		writeError(w, 400, errors.New("Choose My clubs or Discover, and Books or Films"))
		return
	}
	eligible, err := activityEligible(r.Context(), db, actor)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	clubs := []clubView{}
	if scope == "mine" || eligible {
		filter := ` AND EXISTS(SELECT 1 FROM matching.club_members m WHERE m.club_id=c.id AND m.user_id=$1::uuid AND m.status='active')`
		if scope == "discover" {
			filter = ` AND c.moderation_state='active' AND NOT EXISTS(SELECT 1 FROM matching.club_members m WHERE m.club_id=c.id AND m.user_id=$1::uuid AND m.status IN ('active','removed'))`
		}
		rows, e := db.QueryContext(r.Context(), clubSelect()+filter+` AND ($2='' OR c.kind=$2) ORDER BY c.created_at DESC,c.id DESC LIMIT 50`, actor, kind)
		if e != nil {
			writeActivityError(w, e, clubsUnavailable)
			return
		}
		for rows.Next() {
			c, scanErr := scanClub(rows)
			if scanErr != nil {
				rows.Close()
				writeActivityError(w, scanErr, clubsUnavailable)
				return
			}
			clubs = append(clubs, c)
		}
		e = rows.Err()
		rows.Close()
		if e != nil {
			writeActivityError(w, e, clubsUnavailable)
			return
		}
		for i := range clubs {
			if clubs[i], e = completeClub(r.Context(), db, clubs[i]); e != nil {
				writeActivityError(w, e, clubsUnavailable)
				return
			}
		}
	}
	writeJSON(w, 200, map[string]any{"clubs": clubs, "eligible": eligible})
}

func (s *Server) clubHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	clubID := chi.URLParam(r, "clubID")
	if !activityUUID(w, clubID) {
		return
	}
	if r.Method == http.MethodPut {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		c, err := saveClub(r.Context(), db, actor, clubID, body)
		if err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"club": c})
		return
	}
	c, err := readClub(r.Context(), db, actor, clubID)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	rows, err := db.QueryContext(r.Context(), `SELECT id::text FROM matching.club_selections WHERE club_id=$1 ORDER BY week_start DESC LIMIT 8`, clubID)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if err = rows.Scan(&id); err != nil {
			break
		}
		ids = append(ids, id)
	}
	if err == nil {
		err = rows.Err()
	}
	rows.Close()
	selections := []clubSelection{}
	for _, id := range ids {
		if err != nil {
			break
		}
		var sel clubSelection
		sel, err = readClubSelection(r.Context(), db, id)
		selections = append(selections, sel)
	}
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"club": c, "selections": selections})
}

func saveClub(ctx context.Context, db *sql.DB, actor, clubID string, body map[string]any) (clubView, error) {
	kind := toString(body["kind"])
	name := strings.TrimSpace(toString(body["name"]))
	description := strings.TrimSpace(toString(body["description"]))
	version, err := clubVersion(body, true)
	if err != nil {
		return clubView{}, err
	}
	if !validKind(kind) {
		return clubView{}, blogInputError("Choose Books or Films")
	}
	if runeLen(name) < 3 || runeLen(name) > 60 || runeLen(description) > 500 {
		return clubView{}, blogInputError("Use a name of 3–60 characters and a description up to 500")
	}
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return clubView{}, err
	}
	defer tx.Rollback()
	var owner, curKind, curName, curDesc, state string
	var curVersion int
	var deleted bool
	err = tx.QueryRowContext(ctx, `SELECT owner_id::text,kind,name,description,version,moderation_state,deleted_at IS NOT NULL FROM matching.clubs WHERE id=$1 FOR UPDATE`, clubID).
		Scan(&owner, &curKind, &curName, &curDesc, &curVersion, &state, &deleted)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		if version != 0 {
			return clubView{}, errDatingConflict
		}
		eligible, e := activityEligible(ctx, tx, actor)
		if e != nil {
			return clubView{}, e
		}
		if !eligible {
			return clubView{}, activityFail(403, activityEligibilityMessage)
		}
		var owned, joined int
		if e = tx.QueryRowContext(ctx, `SELECT (SELECT COUNT(*) FROM matching.clubs WHERE owner_id=$1 AND deleted_at IS NULL),
 (SELECT COUNT(*) FROM matching.club_members WHERE user_id=$1 AND status='active')`, actor).Scan(&owned, &joined); e != nil {
			return clubView{}, e
		}
		if owned >= clubMaxOwned {
			return clubView{}, activityFail(409, "You can run up to five clubs at a time.")
		}
		if joined >= clubMaxJoined {
			return clubView{}, activityFail(409, "You are in 20 clubs already. Leave one to start another.")
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO matching.clubs(id,kind,name,description,owner_id) VALUES($1,$2,$3,$4,$5)`, clubID, kind, name, description, actor); e != nil {
			return clubView{}, errDatingConflict
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO matching.club_members(club_id,user_id,role) VALUES($1,$2,'owner')`, clubID, actor); e != nil {
			return clubView{}, e
		}
	case err != nil:
		return clubView{}, err
	default:
		if owner != actor || deleted {
			return clubView{}, errDatePlanForbidden
		}
		if curVersion != version {
			if curVersion == version+1 && curKind == kind && curName == name && curDesc == description {
				c, e := readClub(ctx, tx, actor, clubID)
				return c, e
			}
			return clubView{}, errDatingConflict
		}
		if curKind != kind {
			return clubView{}, blogInputError("A club cannot switch between books and films")
		}
		if state != "active" {
			return clubView{}, blogInputError("This club was removed by moderation. Use your review notice to appeal.")
		}
		if _, e := tx.ExecContext(ctx, `UPDATE matching.clubs SET name=$2,description=$3,version=version+1,updated_at=NOW() WHERE id=$1`, clubID, name, description); e != nil {
			return clubView{}, e
		}
	}
	c, err := readClub(ctx, tx, actor, clubID)
	if err != nil {
		return c, err
	}
	return c, tx.Commit()
}

func (s *Server) clubMembershipHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	clubID := chi.URLParam(r, "clubID")
	if !activityUUID(w, clubID) {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	action := toString(body["action"])
	if action != "join" && action != "leave" {
		writeError(w, 400, errors.New("Choose join or leave"))
		return
	}
	result, err := changeMembership(r.Context(), db, actor, clubID, action)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, result)
}

func changeMembership(ctx context.Context, db *sql.DB, actor, clubID, action string) (map[string]any, error) {
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	c, err := readClub(ctx, tx, actor, clubID)
	if err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `SELECT 1 FROM matching.clubs WHERE id=$1 FOR UPDATE`, clubID); err != nil {
		return nil, err
	}
	var status, role string
	err = tx.QueryRowContext(ctx, `SELECT status,role FROM matching.club_members WHERE club_id=$1 AND user_id=$2`, clubID, actor).Scan(&status, &role)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}
	if action == "join" {
		switch status {
		case "active":
			return map[string]any{"club": c}, tx.Commit()
		case "removed":
			return nil, activityFail(403, "A club moderator removed you from this club.")
		}
		if c.Moderation != "active" {
			return nil, errDatePlanNotFound
		}
		eligible, e := activityEligible(ctx, tx, actor)
		if e != nil {
			return nil, e
		}
		if !eligible {
			return nil, activityFail(403, activityEligibilityMessage)
		}
		var joined int
		if e = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.club_members WHERE user_id=$1 AND status='active'`, actor).Scan(&joined); e != nil {
			return nil, e
		}
		if joined >= clubMaxJoined {
			return nil, activityFail(409, "You are in 20 clubs already. Leave one to join another.")
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO matching.club_members(club_id,user_id,role,status) VALUES($1,$2,'member','active')
 ON CONFLICT(club_id,user_id) DO UPDATE SET role='member',status='active',joined_at=NOW(),updated_at=NOW()`, clubID, actor); e != nil {
			return nil, e
		}
	} else {
		if status != "active" {
			return map[string]any{"club": c}, tx.Commit()
		}
		if role == "owner" {
			var others int
			if e := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.club_members WHERE club_id=$1 AND user_id<>$2 AND status='active'`, clubID, actor).Scan(&others); e != nil {
				return nil, e
			}
			if others > 0 {
				return nil, activityFail(409, "Make another member the owner first, or remove the other members before closing the club.")
			}
			if _, e := tx.ExecContext(ctx, `UPDATE matching.clubs SET deleted_at=NOW(),version=version+1,updated_at=NOW() WHERE id=$1`, clubID); e != nil {
				return nil, e
			}
			if _, e := tx.ExecContext(ctx, `UPDATE matching.club_members SET status='left',updated_at=NOW() WHERE club_id=$1 AND user_id=$2`, clubID, actor); e != nil {
				return nil, e
			}
			return map[string]any{"club": nil, "closed": true}, tx.Commit()
		}
		if _, e := tx.ExecContext(ctx, `UPDATE matching.club_members SET status='left',role='member',updated_at=NOW() WHERE club_id=$1 AND user_id=$2`, clubID, actor); e != nil {
			return nil, e
		}
	}
	c, err = readClub(ctx, tx, actor, clubID)
	if err != nil {
		return nil, err
	}
	return map[string]any{"club": c}, tx.Commit()
}

func readClubMembers(ctx context.Context, q blogQuerier, actor, clubID string) ([]clubMemberView, error) {
	rows, err := q.QueryContext(ctx, `SELECT m.user_id::text,COALESCE(u.name,''),m.role,m.joined_at FROM matching.club_members m
 JOIN user_management.users u ON u.id=m.user_id WHERE m.club_id=$2::uuid AND m.status='active' AND `+blogActive+`
 AND (m.user_id=$1::uuid OR `+activityNotBlocked("$1::uuid", "m.user_id")+`)
 ORDER BY CASE m.role WHEN 'owner' THEN 0 WHEN 'moderator' THEN 1 ELSE 2 END,m.joined_at,m.user_id`, actor, clubID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	members := []clubMemberView{}
	for rows.Next() {
		var m clubMemberView
		if err = rows.Scan(&m.UserID, &m.Name, &m.Role, &m.JoinedAt); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, rows.Err()
}

func (s *Server) clubMembersHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	clubID, target := chi.URLParam(r, "clubID"), chi.URLParam(r, "userID")
	if !activityUUID(w, clubID) || (target != "" && !activityUUID(w, target)) {
		return
	}
	if r.Method == http.MethodGet {
		if _, err := readClub(r.Context(), db, actor, clubID); err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		role, err := clubRole(r.Context(), db, clubID, actor)
		if err == nil && role == "" {
			err = activityFail(403, "Join this club to see its members.")
		}
		if err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		members, err := readClubMembers(r.Context(), db, actor, clubID)
		if err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"members": members})
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	members, err := manageClubMember(r.Context(), db, actor, clubID, target, toString(body["action"]))
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"members": members})
}

func manageClubMember(ctx context.Context, db *sql.DB, actor, clubID, target, action string) ([]clubMemberView, error) {
	if action != "make_moderator" && action != "make_member" && action != "remove" {
		return nil, blogInputError("Choose make_moderator, make_member or remove")
	}
	if target == actor {
		return nil, blogInputError("Use leave to change your own membership")
	}
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	if _, err = readClub(ctx, tx, actor, clubID); err != nil {
		return nil, err
	}
	if _, err = tx.ExecContext(ctx, `SELECT 1 FROM matching.clubs WHERE id=$1 FOR UPDATE`, clubID); err != nil {
		return nil, err
	}
	mine, err := clubRole(ctx, tx, clubID, actor)
	if err != nil {
		return nil, err
	}
	theirs, err := clubRole(ctx, tx, clubID, target)
	if err != nil {
		return nil, err
	}
	if theirs == "" {
		return nil, errDatePlanNotFound
	}
	allowed := false
	switch action {
	case "make_moderator", "make_member":
		allowed = mine == "owner" && theirs != "owner"
	case "remove":
		allowed = (mine == "owner" && theirs != "owner") || (mine == "moderator" && theirs == "member")
	}
	if !allowed {
		return nil, activityFail(403, "Only the club owner or a moderator with a higher role can do that.")
	}
	if action == "remove" {
		_, err = tx.ExecContext(ctx, `UPDATE matching.club_members SET status='removed',role='member',updated_at=NOW() WHERE club_id=$1 AND user_id=$2 AND status='active'`, clubID, target)
	} else {
		role := map[string]string{"make_moderator": "moderator", "make_member": "member"}[action]
		_, err = tx.ExecContext(ctx, `UPDATE matching.club_members SET role=$3,updated_at=NOW() WHERE club_id=$1 AND user_id=$2 AND status='active'`, clubID, target, role)
	}
	if err != nil {
		return nil, err
	}
	members, err := readClubMembers(ctx, tx, actor, clubID)
	if err != nil {
		return nil, err
	}
	return members, tx.Commit()
}

// ---------------------------------------------------------------------------
// Weekly picks and discussion
// ---------------------------------------------------------------------------

func (s *Server) clubSelectionHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	clubID := chi.URLParam(r, "clubID")
	if !activityUUID(w, clubID) {
		return
	}
	week, err := time.Parse("2006-01-02", chi.URLParam(r, "weekStart"))
	if err != nil || week.Weekday() != time.Monday {
		writeError(w, 400, errors.New("Use the Monday that starts the week, as YYYY-MM-DD"))
		return
	}
	now := time.Now().UTC()
	thisMonday := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC).AddDate(0, 0, -((int(now.Weekday()) + 6) % 7))
	if diff := week.Sub(thisMonday).Hours() / 24; diff < -clubPicksWindowDays || diff > clubPicksWindowDays {
		writeError(w, 400, errors.New("Picks can be set up to four weeks back or ahead"))
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	titleID := toString(body["title_id"])
	note := strings.TrimSpace(toString(body["note"]))
	if _, err = uuid.Parse(titleID); err != nil || runeLen(note) > 280 {
		writeError(w, 400, errors.New("Choose a title and keep the note under 280 characters"))
		return
	}
	sel, err := setClubSelection(r.Context(), db, actor, clubID, week.Format("2006-01-02"), titleID, note)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"selection": sel})
}

func setClubSelection(ctx context.Context, db *sql.DB, actor, clubID, week, titleID, note string) (clubSelection, error) {
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return clubSelection{}, err
	}
	defer tx.Rollback()
	c, err := readClub(ctx, tx, actor, clubID)
	if err != nil {
		return clubSelection{}, err
	}
	if !clubManager(c.MyRole) || c.Moderation != "active" {
		return clubSelection{}, activityFail(403, "Only the club owner or a moderator can set the weekly pick.")
	}
	var kind string
	if err = tx.QueryRowContext(ctx, `SELECT kind FROM matching.club_titles WHERE id=$1`, titleID).Scan(&kind); err != nil {
		return clubSelection{}, errDatePlanNotFound
	}
	if kind != c.Kind {
		return clubSelection{}, blogInputError("Pick a title of the same kind as the club")
	}
	var existingID, existingTitle string
	var posts int
	err = tx.QueryRowContext(ctx, `SELECT s.id::text,s.title_id::text,(SELECT COUNT(*) FROM matching.club_posts p WHERE p.selection_id=s.id AND p.deleted_at IS NULL)
 FROM matching.club_selections s WHERE s.club_id=$1 AND s.week_start=$2::date FOR UPDATE`, clubID, week).Scan(&existingID, &existingTitle, &posts)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		err = tx.QueryRowContext(ctx, `INSERT INTO matching.club_selections(club_id,title_id,week_start,note,chosen_by) VALUES($1,$2,$3::date,$4,$5) RETURNING id::text`, clubID, titleID, week, note, actor).Scan(&existingID)
		if err != nil {
			return clubSelection{}, errDatingConflict
		}
	case err != nil:
		return clubSelection{}, err
	default:
		if existingTitle != titleID && posts > 0 {
			return clubSelection{}, activityFail(409, "This week's pick already has a discussion. Choose a different week.")
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.club_selections SET title_id=$2,note=$3,chosen_by=$4,updated_at=NOW() WHERE id=$1`, existingID, titleID, note, actor); err != nil {
			return clubSelection{}, err
		}
	}
	sel, err := readClubSelection(ctx, tx, existingID)
	if err != nil {
		return sel, err
	}
	return sel, tx.Commit()
}

func (s *Server) clubPostsHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	clubID := chi.URLParam(r, "clubID")
	selectionID := r.URL.Query().Get("selection_id")
	cursor := r.URL.Query().Get("before")
	if cursor == "" {
		cursor = r.URL.Query().Get("after")
	}
	if !activityUUID(w, clubID, selectionID) || (cursor != "" && !activityUUID(w, cursor)) {
		return
	}
	if _, err := readClub(r.Context(), db, actor, clubID); err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	role, err := clubRole(r.Context(), db, clubID, actor)
	if err == nil && role == "" {
		err = activityFail(403, "Join this club to read the discussion.")
	}
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	// Oldest first: the cursor continues after the last post on the page.
	rows, err := db.QueryContext(r.Context(), clubPostColumns+clubPostVisible()+` AND p.selection_id=$4::uuid
 AND ($5='' OR (p.created_at,p.id) > (SELECT created_at,id FROM matching.club_posts WHERE id::text=$5))
 ORDER BY p.created_at,p.id LIMIT 31`, actor, clubID, clubManager(role), selectionID, cursor)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	defer rows.Close()
	posts := []clubPost{}
	for rows.Next() {
		p, scanErr := scanClubPost(rows)
		if scanErr != nil {
			writeActivityError(w, scanErr, clubsUnavailable)
			return
		}
		posts = append(posts, p)
	}
	if err = rows.Err(); err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	next := ""
	if len(posts) > 30 {
		posts = posts[:30]
		next = posts[29].ID
	}
	writeJSON(w, 200, map[string]any{"posts": posts, "next_cursor": next})
}

func (s *Server) clubPostHandler(w http.ResponseWriter, r *http.Request) {
	s.serveClubPost(w, r, false)
}

func (s *Server) clubPostVisibilityHandler(w http.ResponseWriter, r *http.Request) {
	s.serveClubPost(w, r, true)
}

func (s *Server) serveClubPost(w http.ResponseWriter, r *http.Request, visibility bool) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	clubID, postID := chi.URLParam(r, "clubID"), chi.URLParam(r, "postID")
	if !activityUUID(w, clubID, postID) {
		return
	}
	var body map[string]any
	if r.Method != http.MethodDelete {
		if body, ok = readJSON(w, r); !ok {
			return
		}
	}
	post, err := changeClubPost(r.Context(), db, actor, clubID, postID, r.Method, visibility, body)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	if r.Method == http.MethodDelete {
		writeJSON(w, 200, map[string]any{"deleted": true})
		return
	}
	writeJSON(w, 200, map[string]any{"post": post})
}

func changeClubPost(ctx context.Context, db *sql.DB, actor, clubID, postID, method string, visibility bool, body map[string]any) (clubPost, error) {
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return clubPost{}, err
	}
	defer tx.Rollback()
	c, err := readClub(ctx, tx, actor, clubID)
	if err != nil {
		return clubPost{}, err
	}
	if c.MyRole == "" {
		return clubPost{}, activityFail(403, "Join this club to take part in the discussion.")
	}
	manager := clubManager(c.MyRole)
	switch {
	case method == http.MethodDelete:
		result, e := tx.ExecContext(ctx, `UPDATE matching.club_posts SET deleted_at=NOW(),body='',version=version+1 WHERE id=$1 AND club_id=$2 AND author_id=$3 AND deleted_at IS NULL`, postID, clubID, actor)
		if e != nil {
			return clubPost{}, e
		}
		if n, _ := result.RowsAffected(); n != 1 {
			return clubPost{}, errDatePlanNotFound
		}
		return clubPost{}, tx.Commit()
	case visibility:
		hidden, isBool := body["hidden"].(bool)
		if !isBool {
			return clubPost{}, blogInputError("hidden must be true or false")
		}
		if !manager {
			return clubPost{}, activityFail(403, "Only the club owner or a moderator can hide posts.")
		}
		if _, e := readClubPost(ctx, tx, actor, clubID, postID, true); e != nil {
			return clubPost{}, e
		}
		if _, e := tx.ExecContext(ctx, `UPDATE matching.club_posts SET hidden_at=CASE WHEN $3 THEN COALESCE(hidden_at,NOW()) ELSE NULL END,
 hidden_by=CASE WHEN $3 THEN $4::uuid ELSE NULL END,version=version+1 WHERE id=$1 AND club_id=$2`, postID, clubID, hidden, actor); e != nil {
			return clubPost{}, e
		}
	default:
		selectionID := toString(body["selection_id"])
		text := strings.TrimSpace(toString(body["body"]))
		spoilers, _ := body["has_spoilers"].(bool)
		if _, e := uuid.Parse(selectionID); e != nil {
			return clubPost{}, blogInputError("Choose which pick this post is about")
		}
		if runeLen(text) < 1 || runeLen(text) > 2000 {
			return clubPost{}, blogInputError("Write 1–2,000 characters")
		}
		var author, existingSel, existingBody string
		var existingSpoilers bool
		e := tx.QueryRowContext(ctx, `SELECT author_id::text,selection_id::text,body,has_spoilers FROM matching.club_posts WHERE id=$1`, postID).Scan(&author, &existingSel, &existingBody, &existingSpoilers)
		if e == nil {
			if author == actor && existingSel == selectionID && existingBody == text && existingSpoilers == spoilers {
				return readClubPost(ctx, tx, actor, clubID, postID, manager)
			}
			return clubPost{}, errDatingConflict
		}
		if !errors.Is(e, sql.ErrNoRows) {
			return clubPost{}, e
		}
		if c.Moderation != "active" {
			return clubPost{}, activityFail(403, "This club is paused by moderation.")
		}
		var belongs bool
		if e = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.club_selections WHERE id=$1 AND club_id=$2)`, selectionID, clubID).Scan(&belongs); e != nil {
			return clubPost{}, e
		}
		if !belongs {
			return clubPost{}, errDatePlanNotFound
		}
		var today int
		if e = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.club_posts WHERE author_id=$1 AND club_id=$2 AND created_at>NOW()-interval '1 day'`, actor, clubID).Scan(&today); e != nil {
			return clubPost{}, e
		}
		if today >= clubMaxPostsPerDay {
			return clubPost{}, activityFail(429, "You have posted a lot today. Give the conversation a little room and come back tomorrow.")
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO matching.club_posts(id,club_id,selection_id,author_id,body,has_spoilers) VALUES($1,$2,$3,$4,$5,$6)`, postID, clubID, selectionID, actor, text, spoilers); e != nil {
			return clubPost{}, errDatingConflict
		}
	}
	p, err := readClubPost(ctx, tx, actor, clubID, postID, manager)
	if err != nil {
		return p, err
	}
	return p, tx.Commit()
}

// ---------------------------------------------------------------------------
// Titles and reviews
// ---------------------------------------------------------------------------

func (s *Server) clubTitlesHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	q := strings.TrimSpace(r.URL.Query().Get("q"))
	kind := r.URL.Query().Get("kind")
	if runeLen(q) < 2 || runeLen(q) > 100 || (kind != "" && !validKind(kind)) {
		writeError(w, 400, errors.New("Search with at least two characters"))
		return
	}
	var active bool
	if err := db.QueryRowContext(r.Context(), `SELECT `+activityActive("$1::uuid"), actor).Scan(&active); err != nil || !active {
		writeActivityError(w, errDatePlanForbidden, clubsUnavailable)
		return
	}
	escaped := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(normalizeTitleText(q))
	rows, err := db.QueryContext(r.Context(), `SELECT `+clubTitleColumns+` FROM matching.club_titles t
 WHERE ($1='' OR t.kind=$1) AND (lower(t.title) LIKE '%'||$2||'%' OR lower(t.creator) LIKE '%'||$2||'%')
 ORDER BY (lower(t.title) LIKE $2||'%') DESC,t.title,t.release_year NULLS LAST LIMIT 20`, kind, escaped)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	defer rows.Close()
	titles := []clubTitle{}
	for rows.Next() {
		t, scanErr := scanClubTitle(rows)
		if scanErr != nil {
			writeActivityError(w, scanErr, clubsUnavailable)
			return
		}
		titles = append(titles, t)
	}
	if err = rows.Err(); err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"titles": titles})
}

func readClubTitle(ctx context.Context, q blogQuerier, titleID string) (clubTitle, error) {
	return scanClubTitle(q.QueryRowContext(ctx, `SELECT `+clubTitleColumns+` FROM matching.club_titles t WHERE t.id=$1::uuid`, titleID))
}

func (s *Server) clubTitleHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	titleID := chi.URLParam(r, "titleID")
	if !activityUUID(w, titleID) {
		return
	}
	if r.Method == http.MethodPut {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		t, err := createClubTitle(r.Context(), db, actor, titleID, body)
		if err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"title": t})
		return
	}
	var active bool
	if err := db.QueryRowContext(r.Context(), `SELECT `+activityActive("$1::uuid"), actor).Scan(&active); err != nil || !active {
		writeActivityError(w, errDatePlanForbidden, clubsUnavailable)
		return
	}
	t, err := readClubTitle(r.Context(), db, titleID)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	rows, err := db.QueryContext(r.Context(), reviewSelect()+` AND rv.title_id=$2::uuid ORDER BY rv.author_id=$1::uuid DESC,rv.updated_at DESC,rv.id LIMIT 50`, actor, titleID)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	defer rows.Close()
	var mine *titleReview
	reviews := []titleReview{}
	for rows.Next() {
		v, scanErr := scanReview(rows)
		if scanErr != nil {
			writeActivityError(w, scanErr, clubsUnavailable)
			return
		}
		if v.Mine {
			copied := v
			mine = &copied
			continue
		}
		reviews = append(reviews, v)
	}
	if err = rows.Err(); err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"title": t, "my_review": mine, "reviews": reviews})
}

func createClubTitle(ctx context.Context, db *sql.DB, actor, titleID string, body map[string]any) (clubTitle, error) {
	kind := toString(body["kind"])
	title := strings.Join(strings.Fields(toString(body["title"])), " ")
	creator := strings.Join(strings.Fields(toString(body["creator"])), " ")
	var year *int
	if raw, present := body["release_year"]; present && raw != nil {
		v, isNum := raw.(float64)
		if !isNum || v != float64(int(v)) || v < 1450 || v > 2100 {
			return clubTitle{}, blogInputError("Use a release year between 1450 and 2100")
		}
		y := int(v)
		year = &y
	}
	if !validKind(kind) || runeLen(title) < 1 || runeLen(title) > 200 || runeLen(creator) > 120 {
		return clubTitle{}, blogInputError("Add a book or film title (up to 200 characters) and an optional author or director")
	}
	key := kind + "|" + normalizeTitleText(title) + "|" + normalizeTitleText(creator) + "|"
	if year != nil {
		key += strconv.Itoa(*year)
	}
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return clubTitle{}, err
	}
	defer tx.Rollback()
	var existingID, existingKey string
	err = tx.QueryRowContext(ctx, `SELECT id::text,normalized_key FROM matching.club_titles WHERE id=$1 OR normalized_key=$2 ORDER BY id=$1 DESC LIMIT 1`, titleID, key).Scan(&existingID, &existingKey)
	switch {
	case err == nil:
		if existingID == titleID && existingKey != key {
			return clubTitle{}, errDatingConflict
		}
		titleID = existingID
	case errors.Is(err, sql.ErrNoRows):
		var today int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.club_titles WHERE created_by=$1 AND created_at>NOW()-interval '1 day'`, actor).Scan(&today); err != nil {
			return clubTitle{}, err
		}
		if today >= clubMaxTitlesPerDay {
			return clubTitle{}, activityFail(429, "You have added many titles today. Try again tomorrow.")
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.club_titles(id,kind,title,creator,release_year,normalized_key,created_by) VALUES($1,$2,$3,$4,$5,$6,$7)`, titleID, kind, title, creator, year, key, actor); err != nil {
			return clubTitle{}, errDatingConflict
		}
	default:
		return clubTitle{}, err
	}
	t, err := readClubTitle(ctx, tx, titleID)
	if err != nil {
		return t, err
	}
	return t, tx.Commit()
}

func (s *Server) clubReviewHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	titleID, reviewID := chi.URLParam(r, "titleID"), chi.URLParam(r, "reviewID")
	if !activityUUID(w, reviewID) || (titleID != "" && !activityUUID(w, titleID)) {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	if r.Method == http.MethodDelete {
		version, err := clubVersion(body, false)
		if err == nil {
			err = deleteOwned(r.Context(), db, actor, `UPDATE matching.title_reviews SET deleted_at=NOW(),body='',version=version+1 WHERE id=$1 AND author_id=$2 AND deleted_at IS NULL AND version=$3`, reviewID, version)
		}
		if err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"deleted": true})
		return
	}
	v, err := saveReview(r.Context(), db, actor, titleID, reviewID, body)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"review": v})
}

func deleteOwned(ctx context.Context, db *sql.DB, actor, query, id string, version int) error {
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	result, err := tx.ExecContext(ctx, query, id, actor, version)
	if err != nil {
		return err
	}
	if n, _ := result.RowsAffected(); n != 1 {
		return errDatingConflict
	}
	return tx.Commit()
}

func saveReview(ctx context.Context, db *sql.DB, actor, titleID, reviewID string, body map[string]any) (titleReview, error) {
	rating, isNum := body["rating"].(float64)
	text := strings.TrimSpace(toString(body["body"]))
	spoilers, _ := body["has_spoilers"].(bool)
	audience := toString(body["audience"])
	version, err := clubVersion(body, true)
	if err != nil {
		return titleReview{}, err
	}
	if !isNum || rating != float64(int(rating)) || rating < 1 || rating > 5 {
		return titleReview{}, blogInputError("Choose a rating from one to five stars")
	}
	if runeLen(text) > 4000 || !validAudience(audience) {
		return titleReview{}, blogInputError("Keep the review under 4,000 characters and choose who can see it")
	}
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return titleReview{}, err
	}
	defer tx.Rollback()
	if _, err = readClubTitle(ctx, tx, titleID); err != nil {
		return titleReview{}, err
	}
	if audience == "community" {
		eligible, e := activityEligible(ctx, tx, actor)
		if e != nil {
			return titleReview{}, e
		}
		if !eligible {
			return titleReview{}, activityFail(403, activityEligibilityMessage)
		}
	}
	var author, curTitle, curBody, curAudience, state string
	var curRating, curVersion int
	var curSpoilers, deleted bool
	err = tx.QueryRowContext(ctx, `SELECT author_id::text,title_id::text,rating,body,has_spoilers,audience,version,moderation_state,deleted_at IS NOT NULL
 FROM matching.title_reviews WHERE id=$1 FOR UPDATE`, reviewID).Scan(&author, &curTitle, &curRating, &curBody, &curSpoilers, &curAudience, &curVersion, &state, &deleted)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		if version != 0 {
			return titleReview{}, errDatingConflict
		}
		var other bool
		if err = tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM matching.title_reviews WHERE title_id=$1 AND author_id=$2 AND deleted_at IS NULL)`, titleID, actor).Scan(&other); err != nil {
			return titleReview{}, err
		}
		if other {
			return titleReview{}, activityFail(409, "You already reviewed this title. Edit that review instead.")
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.title_reviews(id,title_id,author_id,rating,body,has_spoilers,audience) VALUES($1,$2,$3,$4,$5,$6,$7)`, reviewID, titleID, actor, int(rating), text, spoilers, audience); err != nil {
			return titleReview{}, errDatingConflict
		}
	case err != nil:
		return titleReview{}, err
	default:
		if author != actor || curTitle != titleID || deleted {
			return titleReview{}, errDatePlanForbidden
		}
		if curVersion != version {
			if curVersion == version+1 && curRating == int(rating) && curBody == text && curSpoilers == spoilers && curAudience == audience {
				return scanReview(tx.QueryRowContext(ctx, reviewSelect()+` AND rv.id=$2::uuid`, actor, reviewID))
			}
			return titleReview{}, errDatingConflict
		}
		if state != "active" && audience != "private" {
			return titleReview{}, blogInputError("This review was removed by moderation. Keep edits to Only me and use your review notice to appeal.")
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.title_reviews SET rating=$2,body=$3,has_spoilers=$4,audience=$5,version=version+1,updated_at=NOW() WHERE id=$1`, reviewID, int(rating), text, spoilers, audience); err != nil {
			return titleReview{}, err
		}
	}
	v, err := scanReview(tx.QueryRowContext(ctx, reviewSelect()+` AND rv.id=$2::uuid`, actor, reviewID))
	if err != nil {
		return v, err
	}
	return v, tx.Commit()
}

// ---------------------------------------------------------------------------
// Lists
// ---------------------------------------------------------------------------

func (s *Server) clubListsHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	owner := r.URL.Query().Get("owner_id")
	if owner == "" {
		owner = actor
	}
	if !activityUUID(w, owner) {
		return
	}
	rows, err := db.QueryContext(r.Context(), listSelect()+` AND l.owner_id=$2::uuid ORDER BY l.created_at,l.id LIMIT 50`, actor, owner)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	lists := []memberList{}
	for rows.Next() {
		l, scanErr := scanList(rows)
		if scanErr != nil {
			rows.Close()
			writeActivityError(w, scanErr, clubsUnavailable)
			return
		}
		lists = append(lists, l)
	}
	err = rows.Err()
	rows.Close()
	for i := range lists {
		if err != nil {
			break
		}
		err = fillListItems(r.Context(), db, &lists[i])
	}
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"lists": lists})
}

func (s *Server) clubListHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	listID := chi.URLParam(r, "listID")
	if !activityUUID(w, listID) {
		return
	}
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	if r.Method == http.MethodDelete {
		version, err := clubVersion(body, false)
		if err == nil {
			err = deleteOwned(r.Context(), db, actor, `UPDATE matching.member_lists SET deleted_at=NOW(),name='',version=version+1 WHERE id=$1 AND owner_id=$2 AND deleted_at IS NULL AND version=$3`, listID, version)
		}
		if err != nil {
			writeActivityError(w, err, clubsUnavailable)
			return
		}
		writeJSON(w, 200, map[string]any{"deleted": true})
		return
	}
	l, err := saveList(r.Context(), db, actor, listID, body)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"list": l})
}

func saveList(ctx context.Context, db *sql.DB, actor, listID string, body map[string]any) (memberList, error) {
	name := strings.TrimSpace(toString(body["name"]))
	kind := toString(body["kind"])
	audience := toString(body["audience"])
	version, err := clubVersion(body, true)
	if err != nil {
		return memberList{}, err
	}
	if runeLen(name) < 1 || runeLen(name) > 60 || !validKind(kind) || !validAudience(audience) {
		return memberList{}, blogInputError("Name the list (up to 60 characters), choose Books or Films and who can see it")
	}
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return memberList{}, err
	}
	defer tx.Rollback()
	if audience == "community" {
		eligible, e := activityEligible(ctx, tx, actor)
		if e != nil {
			return memberList{}, e
		}
		if !eligible {
			return memberList{}, activityFail(403, activityEligibilityMessage)
		}
	}
	var owner, curName, curKind, curAudience, state string
	var curVersion int
	var deleted bool
	err = tx.QueryRowContext(ctx, `SELECT owner_id::text,name,kind,audience,version,moderation_state,deleted_at IS NOT NULL FROM matching.member_lists WHERE id=$1 FOR UPDATE`, listID).
		Scan(&owner, &curName, &curKind, &curAudience, &curVersion, &state, &deleted)
	switch {
	case errors.Is(err, sql.ErrNoRows):
		if version != 0 {
			return memberList{}, errDatingConflict
		}
		var count int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.member_lists WHERE owner_id=$1 AND deleted_at IS NULL`, actor).Scan(&count); err != nil {
			return memberList{}, err
		}
		if count >= clubMaxLists {
			return memberList{}, activityFail(409, "You can keep up to 20 lists. Delete one to start another.")
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.member_lists(id,owner_id,name,kind,audience) VALUES($1,$2,$3,$4,$5)`, listID, actor, name, kind, audience); err != nil {
			return memberList{}, errDatingConflict
		}
	case err != nil:
		return memberList{}, err
	default:
		if owner != actor || deleted {
			return memberList{}, errDatePlanForbidden
		}
		if curVersion != version {
			if curVersion == version+1 && curName == name && curKind == kind && curAudience == audience {
				return readList(ctx, tx, actor, listID)
			}
			return memberList{}, errDatingConflict
		}
		if curKind != kind {
			var items int
			if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.member_list_items WHERE list_id=$1`, listID).Scan(&items); err != nil {
				return memberList{}, err
			}
			if items > 0 {
				return memberList{}, blogInputError("Empty the list before switching between books and films")
			}
		}
		if state != "active" && audience != "private" {
			return memberList{}, blogInputError("This list was removed by moderation. Keep it to Only me and use your review notice to appeal.")
		}
		if _, err = tx.ExecContext(ctx, `UPDATE matching.member_lists SET name=$2,kind=$3,audience=$4,version=version+1,updated_at=NOW() WHERE id=$1`, listID, name, kind, audience); err != nil {
			return memberList{}, err
		}
	}
	l, err := readList(ctx, tx, actor, listID)
	if err != nil {
		return l, err
	}
	return l, tx.Commit()
}

func (s *Server) clubListItemHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, ok := s.clubsContext(w, r)
	if !ok {
		return
	}
	listID, titleID := chi.URLParam(r, "listID"), chi.URLParam(r, "titleID")
	if !activityUUID(w, listID, titleID) {
		return
	}
	note := ""
	if r.Method == http.MethodPut {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		note = strings.TrimSpace(toString(body["note"]))
		if runeLen(note) > 280 {
			writeError(w, 400, errors.New("Keep the note under 280 characters"))
			return
		}
	}
	l, err := changeListItem(r.Context(), db, actor, listID, titleID, note, r.Method == http.MethodDelete)
	if err != nil {
		writeActivityError(w, err, clubsUnavailable)
		return
	}
	writeJSON(w, 200, map[string]any{"list": l})
}

func changeListItem(ctx context.Context, db *sql.DB, actor, listID, titleID, note string, remove bool) (memberList, error) {
	tx, err := clubBegin(ctx, db, actor)
	if err != nil {
		return memberList{}, err
	}
	defer tx.Rollback()
	var owner, kind string
	if err = tx.QueryRowContext(ctx, `SELECT owner_id::text,kind FROM matching.member_lists WHERE id=$1 AND deleted_at IS NULL FOR UPDATE`, listID).Scan(&owner, &kind); err != nil {
		return memberList{}, errDatePlanNotFound
	}
	if owner != actor {
		return memberList{}, errDatePlanForbidden
	}
	if remove {
		if _, err = tx.ExecContext(ctx, `DELETE FROM matching.member_list_items WHERE list_id=$1 AND title_id=$2`, listID, titleID); err != nil {
			return memberList{}, err
		}
	} else {
		t, e := readClubTitle(ctx, tx, titleID)
		if e != nil {
			return memberList{}, e
		}
		if t.Kind != kind {
			return memberList{}, blogInputError("Add a title of the same kind as the list")
		}
		var count int
		if e = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.member_list_items WHERE list_id=$1 AND title_id<>$2`, listID, titleID).Scan(&count); e != nil {
			return memberList{}, e
		}
		if count >= clubMaxListItems {
			return memberList{}, activityFail(409, "A list holds up to 100 titles.")
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO matching.member_list_items(list_id,title_id,note,position)
 VALUES($1,$2,$3,(SELECT COALESCE(MAX(position),0)+1 FROM matching.member_list_items WHERE list_id=$1))
 ON CONFLICT(list_id,title_id) DO UPDATE SET note=EXCLUDED.note`, listID, titleID, note); e != nil {
			return memberList{}, e
		}
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.member_lists SET version=version+1,updated_at=NOW() WHERE id=$1`, listID); err != nil {
		return memberList{}, err
	}
	l, err := readList(ctx, tx, actor, listID)
	if err != nil {
		return l, err
	}
	return l, tx.Commit()
}

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

// readActivityForReport captures what the reporter can currently see. It is
// called from createBlogCase so every activity shares one queue and appeal
// flow. Photos are returned only for theme entries.
func readActivityForReport(ctx context.Context, q blogQuerier, actor, kind, id string) (string, any, []string, error) {
	switch kind {
	case "theme_entry":
		var theme string
		e, err := scanThemeEntry(q.QueryRowContext(ctx, themeEntrySelect()+` AND e.id=$2::uuid`, actor, id))
		if err != nil {
			return "", nil, nil, err
		}
		_ = q.QueryRowContext(ctx, `SELECT title FROM matching.photo_themes WHERE id=$1`, e.ThemeID).Scan(&theme)
		return e.AuthorID, map[string]any{"title": "Photo Theme · " + theme, "text": e.Caption, "alt_text": e.AltText}, []string{e.ID}, nil
	case "club":
		c, err := readClub(ctx, q, actor, id)
		if err != nil {
			return "", nil, nil, err
		}
		return c.OwnerID, map[string]any{"title": "Club · " + c.Name, "body": c.Description, "kind": c.Kind}, nil, nil
	case "club_post":
		var clubID string
		if err := q.QueryRowContext(ctx, `SELECT club_id::text FROM matching.club_posts WHERE id=$1`, id).Scan(&clubID); err != nil {
			return "", nil, nil, errDatePlanNotFound
		}
		c, err := readClub(ctx, q, actor, clubID)
		if err != nil {
			return "", nil, nil, err
		}
		if c.MyRole == "" {
			return "", nil, nil, errDatePlanNotFound
		}
		p, err := readClubPost(ctx, q, actor, clubID, id, clubManager(c.MyRole))
		if err != nil {
			return "", nil, nil, err
		}
		return p.AuthorID, map[string]any{"title": "Club post · " + c.Name, "text": p.Body, "has_spoilers": p.HasSpoilers}, nil, nil
	case "review":
		v, err := scanReview(q.QueryRowContext(ctx, reviewSelect()+` AND rv.id=$2::uuid`, actor, id))
		if err != nil {
			return "", nil, nil, err
		}
		t, err := readClubTitle(ctx, q, v.TitleID)
		if err != nil {
			return "", nil, nil, err
		}
		return v.AuthorID, map[string]any{"title": "Review · " + t.Title, "body": v.Body, "rating": v.Rating}, nil, nil
	case "list":
		l, err := readList(ctx, q, actor, id)
		if err != nil {
			return "", nil, nil, err
		}
		names := make([]string, 0, len(l.Items))
		for _, item := range l.Items {
			names = append(names, item.Title.Title)
		}
		return l.OwnerID, map[string]any{"title": "List · " + l.Name, "body": strings.Join(names, "\n")}, nil, nil
	case "comment":
		subject, snapshot, err := readCommentForReport(ctx, q, actor, id)
		return subject, snapshot, nil, err
	case "photo_comment":
		subject, snapshot, err := readPhotoCommentForReport(ctx, q, actor, id)
		return subject, snapshot, nil, err
	case "social_message":
		subject, snapshot, err := readSocialMessageForReport(ctx, q, actor, id)
		return subject, snapshot, nil, err
	case "group":
		// The cover photo the reporter sees becomes case evidence.
		return readGroupForReport(ctx, q, actor, id)
	}
	return "", nil, nil, blogInputError("Unknown report content")
}

// activityModerationTables maps report kinds to the table whose
// moderation_state a case decision changes.
var activityModerationTables = map[string]string{
	"theme_entry":   "photo_theme_entries",
	"club":          "clubs",
	"club_post":     "club_posts",
	"review":        "title_reviews",
	"list":          "member_lists",
	"comment":       "blog_comments",
	"photo_comment": "photo_entry_comments",
	// Friend, room and group chat messages (migration 115).
	"social_message": "social_messages",
	// A whole lifestyle or private group (migration 120).
	"group": "community_groups",
}
