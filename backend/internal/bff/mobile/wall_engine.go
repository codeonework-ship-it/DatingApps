package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// The wall engine powers likes, author-approved comments and tiered reach to
// other members' Today walls. Chapters (blog posts) and Photo Theme photos
// use the same rules through a wallSpec, so the two can never drift apart.
//
// Reach is tiered: by default 50 likes + 5 approved comments reach 50 walls
// and 100 likes + 10 comments reach 100 (BLOG_WALL_TIERS overrides this as
// "likes:comments:walls,..."). Deliveries are recorded per member so reach
// only grows. Content stays on walls only while the spec's Allowed rule holds
// (author opt-in, active, no open report) and for 14 days after it first
// qualified.

const (
	wallMaxLikesPerDay    = 300
	wallMaxCommentsPerDay = 30
	wallFeaturedDays      = 14
)

// Kept for existing callers.
const (
	blogMaxLikesPerDay    = wallMaxLikesPerDay
	blogMaxCommentsPerDay = wallMaxCommentsPerDay
	blogFeaturedDays      = wallFeaturedDays
)

type blogWallTier struct {
	Likes    int `json:"likes"`
	Comments int `json:"comments"`
	Reach    int `json:"reach"`
}

type blogNextTier struct {
	blogWallTier
	LikesNeeded    int `json:"likes_needed"`
	CommentsNeeded int `json:"comments_needed"`
}

var defaultBlogWallTiers = []blogWallTier{{50, 5, 50}, {100, 10, 100}}

// blogWallTiers parses BLOG_WALL_TIERS; anything malformed falls back to the
// defaults rather than silently opening or closing the wall.
func blogWallTiers() []blogWallTier {
	raw := strings.TrimSpace(os.Getenv("BLOG_WALL_TIERS"))
	if raw == "" {
		return defaultBlogWallTiers
	}
	tiers := []blogWallTier{}
	for _, part := range strings.Split(raw, ",") {
		fields := strings.Split(strings.TrimSpace(part), ":")
		if len(fields) != 3 {
			return defaultBlogWallTiers
		}
		var values [3]int
		for i, field := range fields {
			n, err := strconv.Atoi(strings.TrimSpace(field))
			if err != nil || n < 0 || n > 1000000 {
				return defaultBlogWallTiers
			}
			values[i] = n
		}
		if values[2] < 1 {
			return defaultBlogWallTiers
		}
		tier := blogWallTier{values[0], values[1], values[2]}
		if len(tiers) > 0 {
			last := tiers[len(tiers)-1]
			if tier.Likes < last.Likes || tier.Comments < last.Comments || tier.Reach <= last.Reach {
				return defaultBlogWallTiers
			}
		}
		tiers = append(tiers, tier)
	}
	return tiers
}

// blogTierReached returns the 1-based highest tier met, or 0.
func blogTierReached(tiers []blogWallTier, likes, comments int) int {
	reached := 0
	for i, t := range tiers {
		if likes >= t.Likes && comments >= t.Comments {
			reached = i + 1
		}
	}
	return reached
}

// wallSpec names the tables and rules for one kind of wall content. Every SQL
// fragment uses alias p for the content row.
type wallSpec struct {
	Noun        string // "chapter" or "photo", used in member-facing text and celebrations
	Content     string // content table
	Likes       string // likes table (FK, user_id)
	Comments    string // comments table (id, FK, author_id, OwnerCol, ...)
	Deliveries  string // deliveries table (FK, recipient_id, tier)
	FK          string // foreign key column naming the content in the three tables
	OwnerCol    string // comments column holding the content author
	TitleCol    string // content column used as the title in notices
	EventPrefix string // notification event prefix
	Route       string // app route opened by notices
	Allowed     func() string
}

// wallReactions are the empathetic reactions a member can leave (migration
// 114). Each counts as one like; "love" is the plain like.
var wallReactions = []string{"love", "hear_you", "me_too", "with_you", "hug", "proud"}

func validWallReaction(reaction string) bool {
	for _, r := range wallReactions {
		if r == reaction {
			return true
		}
	}
	return false
}

// readWallReaction reads the optional {"reaction": "..."} body of a like. An
// empty body means a plain like (or keep the current reaction).
func readWallReaction(w http.ResponseWriter, r *http.Request) (string, bool) {
	if r.Method != http.MethodPut || r.Body == nil {
		return "", true
	}
	defer r.Body.Close()
	var body struct {
		Reaction *string `json:"reaction"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil && !errors.Is(err, io.EOF) {
		writeError(w, http.StatusBadRequest, errors.New("Send a reaction or no body"))
		return "", false
	}
	if body.Reaction == nil || *body.Reaction == "" {
		return "", true
	}
	if !validWallReaction(*body.Reaction) {
		writeError(w, http.StatusBadRequest, errors.New("Choose one of: "+strings.Join(wallReactions, ", ")))
		return "", false
	}
	return *body.Reaction, true
}

type wallEngagement struct {
	ViewCount           int
	LikeCount           int
	LikedByMe           bool
	MyReaction          string
	Reactions           map[string]int
	CommentCount        int
	PendingCommentCount int
	AllowFeaturing      bool
	Featured            bool
	WallReach           int
	NextTier            *blogNextTier
}

func (w wallSpec) likesSQL(id string) string {
	return `(SELECT COUNT(*) FROM ` + w.Likes + ` l JOIN user_management.users u ON u.id=l.user_id WHERE l.` + w.FK + `=` + id + ` AND ` + blogActive + `)`
}

// viewsSQL counts unique members who opened the content (migration 112).
func (w wallSpec) viewsSQL(id string) string {
	return `(SELECT COUNT(*) FROM matching.content_views v WHERE v.kind='` + w.Noun + `' AND v.content_id=` + id + `)`
}

func (w wallSpec) approvedCommentsSQL(id string) string {
	return `(SELECT COUNT(*) FROM ` + w.Comments + ` c JOIN user_management.users u ON u.id=c.author_id
 WHERE c.` + w.FK + `=` + id + ` AND c.status='approved' AND c.moderation_state='active' AND c.deleted_at IS NULL AND ` + blogActive + `)`
}

func (w wallSpec) featuredSQL() string {
	return fmt.Sprintf(`(p.wall_tier>0 AND p.featured_at>NOW()-interval '%d days' AND %s)`, wallFeaturedDays, w.Allowed())
}

// deliveredToSQL: content alias p is on viewer $1's wall.
func (w wallSpec) deliveredToSQL() string {
	return `EXISTS(SELECT 1 FROM ` + w.Deliveries + ` d WHERE d.` + w.FK + `=p.id AND d.recipient_id=$1::uuid)`
}

func (w wallSpec) deliveredAtSQL() string {
	return `(SELECT d.delivered_at FROM ` + w.Deliveries + ` d WHERE d.` + w.FK + `=p.id AND d.recipient_id=$1::uuid)`
}

// engagement reads counts, reach and (for the author) the next tier.
func (w wallSpec) engagement(ctx context.Context, q blogQuerier, actor, id string) (wallEngagement, error) {
	var e wallEngagement
	var allowed bool
	var owner string
	err := q.QueryRowContext(ctx, `SELECT p.author_id::text,`+w.likesSQL("p.id")+`,
 COALESCE((SELECT reaction FROM `+w.Likes+` WHERE `+w.FK+`=p.id AND user_id=$1::uuid),''),
 `+w.approvedCommentsSQL("p.id")+`,
 CASE WHEN p.author_id=$1::uuid THEN (SELECT COUNT(*) FROM `+w.Comments+` c WHERE c.`+w.FK+`=p.id AND c.status='pending' AND c.deleted_at IS NULL) ELSE 0 END,
 p.allow_featuring, `+w.featuredSQL()+`, `+w.Allowed()+`,
 (SELECT COUNT(*) FROM `+w.Deliveries+` d WHERE d.`+w.FK+`=p.id), `+w.viewsSQL("p.id")+`
 FROM `+w.Content+` p WHERE p.id=$2::uuid`, actor, id).
		Scan(&owner, &e.LikeCount, &e.MyReaction, &e.CommentCount, &e.PendingCommentCount, &e.AllowFeaturing, &e.Featured, &allowed, &e.WallReach, &e.ViewCount)
	if errors.Is(err, sql.ErrNoRows) {
		return e, errDatePlanNotFound
	}
	if err != nil {
		return e, err
	}
	if !allowed {
		e.WallReach = 0
	}
	e.LikedByMe = e.MyReaction != ""
	if e.Reactions, err = w.reactionCounts(ctx, q, id); err != nil {
		return e, err
	}
	if owner == actor && allowed {
		tiers := blogWallTiers()
		if reached := blogTierReached(tiers, e.LikeCount, e.CommentCount); reached < len(tiers) {
			next := tiers[reached]
			e.NextTier = &blogNextTier{
				blogWallTier:   next,
				LikesNeeded:    max(0, next.Likes-e.LikeCount),
				CommentsNeeded: max(0, next.Comments-e.CommentCount),
			}
		}
	}
	return e, nil
}

// advance moves content to the highest tier it has reached and delivers it to
// more walls: the author's friends first, then members in the same city, then
// a stable pseudo-random order. The author is told once per new tier.
func (w wallSpec) advance(ctx context.Context, tx *sql.Tx, id string) error {
	var author, title string
	var allowed bool
	var likes, comments, current int
	err := tx.QueryRowContext(ctx, `SELECT p.author_id::text,p.`+w.TitleCol+`,`+w.Allowed()+`,`+w.likesSQL("p.id")+`,`+w.approvedCommentsSQL("p.id")+`,p.wall_tier
 FROM `+w.Content+` p WHERE p.id=$1::uuid`, id).Scan(&author, &title, &allowed, &likes, &comments, &current)
	if errors.Is(err, sql.ErrNoRows) || (err == nil && !allowed) {
		return nil
	}
	if err != nil {
		return err
	}
	tiers := blogWallTiers()
	reached := blogTierReached(tiers, likes, comments)
	if reached == 0 {
		return nil
	}
	reach := tiers[reached-1].Reach
	if _, err = tx.ExecContext(ctx, `INSERT INTO `+w.Deliveries+`(`+w.FK+`,recipient_id,tier)
 SELECT $1::uuid,u.id,$3 FROM user_management.users u
 WHERE u.id<>$2::uuid AND `+blogActive+` AND `+activityCommunity("u.id")+` AND `+activityNotBlocked("u.id", "$2::uuid")+`
  AND NOT EXISTS(SELECT 1 FROM `+w.Deliveries+` d WHERE d.`+w.FK+`=$1::uuid AND d.recipient_id=u.id)
 ORDER BY matching.accepted_friends(u.id,$2::uuid) DESC,
  (u.city IS NOT NULL AND u.city=(SELECT a.city FROM user_management.users a WHERE a.id=$2::uuid)) DESC,
  md5($1::text||u.id::text)
 LIMIT GREATEST($4-(SELECT COUNT(*) FROM `+w.Deliveries+` d WHERE d.`+w.FK+`=$1::uuid),0)
 ON CONFLICT DO NOTHING`, id, author, reached, reach); err != nil {
		return err
	}
	if reached <= current {
		return nil
	}
	if _, err = tx.ExecContext(ctx, `UPDATE `+w.Content+` SET wall_tier=$2,featured_at=COALESCE(featured_at,NOW()) WHERE id=$1`, id, reached); err != nil {
		return err
	}
	var delivered int
	if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM `+w.Deliveries+` WHERE `+w.FK+`=$1`, id).Scan(&delivered); err != nil {
		return err
	}
	if runeLen(title) > 60 {
		title = string([]rune(title)[:57]) + "…"
	}
	if err = queueReward(ctx, tx, author, "wall_tier_reached", w.Noun+":"+id+":"+strconv.Itoa(reached)); err != nil {
		return err
	}
	// One rose rain per new tier, played on the author's next open.
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.wall_celebrations(author_id,kind,content_id,tier,reach,title)
 VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(kind,content_id,tier) DO NOTHING`, author, w.Noun, id, reached, delivered, title); err != nil {
		return err
	}
	// A system event, not the author's own action, so it has no actor.
	return enqueueNotificationTx(ctx, tx, author, "", w.EventPrefix+".featured", "system", id,
		w.EventPrefix+"-wall:"+id+":"+strconv.Itoa(reached),
		"Your "+w.Noun+" reached "+strconv.Itoa(reach)+" walls",
		"Members loved “"+title+"”. It is now on "+strconv.Itoa(delivered)+" members’ Today walls. You can turn this off any time.",
		w.Route, map[string]any{w.FK: id, "tier": reached, "reach": reach}, 3)
}

// like adds or removes the actor's like. The caller has already checked that
// the actor can see and react to the content.
// reactionCounts tallies reactions from active members, like likesSQL.
func (w wallSpec) reactionCounts(ctx context.Context, q blogQuerier, id string) (map[string]int, error) {
	rows, err := q.QueryContext(ctx, `SELECT l.reaction,COUNT(*) FROM `+w.Likes+` l JOIN user_management.users u ON u.id=l.user_id
 WHERE l.`+w.FK+`=$1::uuid AND `+blogActive+` GROUP BY l.reaction`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	counts := map[string]int{}
	for rows.Next() {
		var reaction string
		var n int
		if err = rows.Scan(&reaction, &n); err != nil {
			return nil, err
		}
		counts[reaction] = n
	}
	return counts, rows.Err()
}

// like adds, changes or removes the actor's reaction. Changing the reaction
// on an existing like keeps it one like: no daily limit, reward or reach.
func (w wallSpec) like(ctx context.Context, tx *sql.Tx, actor, id string, like bool, reaction string) error {
	if !like {
		_, err := tx.ExecContext(ctx, `DELETE FROM `+w.Likes+` WHERE `+w.FK+`=$1 AND user_id=$2`, id, actor)
		return err
	}
	var current string
	err := tx.QueryRowContext(ctx, `SELECT reaction FROM `+w.Likes+` WHERE `+w.FK+`=$1 AND user_id=$2 FOR UPDATE`, id, actor).Scan(&current)
	if err == nil {
		if reaction == "" || reaction == current {
			return nil
		}
		_, err = tx.ExecContext(ctx, `UPDATE `+w.Likes+` SET reaction=$3,updated_at=NOW() WHERE `+w.FK+`=$1 AND user_id=$2`, id, actor, reaction)
		return err
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return err
	}
	if reaction == "" {
		reaction = "love"
	}
	var today int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM `+w.Likes+` WHERE user_id=$1 AND created_at>NOW()-interval '1 day'`, actor).Scan(&today); err != nil {
		return err
	}
	if today >= wallMaxLikesPerDay {
		return activityFail(429, "You have liked a lot today. Come back tomorrow.")
	}
	result, err := tx.ExecContext(ctx, `INSERT INTO `+w.Likes+`(`+w.FK+`,user_id,reaction) VALUES($1,$2,$3) ON CONFLICT DO NOTHING`, id, actor, reaction)
	if err != nil {
		return err
	}
	if n, _ := result.RowsAffected(); n == 1 {
		var owner string
		if err = tx.QueryRowContext(ctx, `SELECT author_id::text FROM `+w.Content+` WHERE id=$1`, id).Scan(&owner); err != nil {
			return err
		}
		if err = queueReward(ctx, tx, owner, "like_received", w.Noun+":"+id+":"+actor); err != nil {
			return err
		}
	}
	return w.advance(ctx, tx, id)
}

type wallComment struct {
	ID          string    `json:"id"`
	PostID      string    `json:"post_id,omitempty"`
	EntryID     string    `json:"entry_id,omitempty"`
	AuthorID    string    `json:"author_id"`
	AuthorName  string    `json:"author_name"`
	Body        string    `json:"body"`
	Status      string    `json:"status"`
	Mine        bool      `json:"mine"`
	CanModerate bool      `json:"can_moderate"`
	Moderation  string    `json:"moderation_state"`
	Created     time.Time `json:"created_at"`
}

// commentSelect: viewer $1, content $2, comment alias c. Pending and declined
// comments are seen only by their writer and the content author; removed ones
// only by their writer.
func (w wallSpec) commentSelect() string {
	return `SELECT c.id::text,c.` + w.FK + `::text,c.author_id::text,COALESCE(u.name,''),c.body,c.status,c.author_id=$1::uuid,c.` + w.OwnerCol + `=$1::uuid,c.moderation_state,c.created_at
 FROM ` + w.Comments + ` c JOIN user_management.users u ON u.id=c.author_id
 WHERE c.` + w.FK + `=$2::uuid AND c.deleted_at IS NULL AND ` + blogActive + ` AND ` + activityNotBlocked("$1::uuid", "c.author_id") + `
 AND (c.author_id=$1::uuid OR (c.moderation_state='active' AND (c.status='approved' OR c.` + w.OwnerCol + `=$1::uuid)))`
}

func (w wallSpec) scanComment(row interface{ Scan(...any) error }) (wallComment, error) {
	var c wallComment
	var parent string
	err := row.Scan(&c.ID, &parent, &c.AuthorID, &c.AuthorName, &c.Body, &c.Status, &c.Mine, &c.CanModerate, &c.Moderation, &c.Created)
	if errors.Is(err, sql.ErrNoRows) {
		return c, errDatePlanNotFound
	}
	if w.FK == "entry_id" {
		c.EntryID = parent
	} else {
		c.PostID = parent
	}
	return c, err
}

func (w wallSpec) readComment(ctx context.Context, q blogQuerier, actor, id, commentID string) (wallComment, error) {
	return w.scanComment(q.QueryRowContext(ctx, w.commentSelect()+` AND c.id=$3::uuid`, actor, id, commentID))
}

func (w wallSpec) listComments(ctx context.Context, q blogQuerier, actor, id string) ([]wallComment, error) {
	rows, err := q.QueryContext(ctx, w.commentSelect()+` ORDER BY c.created_at,c.id LIMIT 200`, actor, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	comments := []wallComment{}
	for rows.Next() {
		c, scanErr := w.scanComment(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		comments = append(comments, c)
	}
	return comments, rows.Err()
}

// changeComment creates, decides or deletes a comment inside the caller's
// transaction. owner and title describe content the actor can already see;
// canEngage is checked before a new comment is written.
func (w wallSpec) changeComment(ctx context.Context, tx *sql.Tx, actor, id, commentID, method, decision string, body map[string]any, owner, title string, canEngage func() error) (wallComment, error) {
	switch {
	case method == http.MethodDelete:
		result, err := tx.ExecContext(ctx, `UPDATE `+w.Comments+` SET deleted_at=NOW(),body='',version=version+1
 WHERE id=$1 AND `+w.FK+`=$2 AND deleted_at IS NULL AND (author_id=$3 OR `+w.OwnerCol+`=$3)`, commentID, id, actor)
		if err != nil {
			return wallComment{}, err
		}
		if n, _ := result.RowsAffected(); n != 1 {
			return wallComment{}, errDatePlanNotFound
		}
		return wallComment{}, nil
	case decision != "":
		if decision != "approve" && decision != "decline" {
			return wallComment{}, blogInputError("Choose approve or decline")
		}
		if owner != actor {
			return wallComment{}, activityFail(403, "Only the "+w.Noun+"'s author can approve comments.")
		}
		status := map[string]string{"approve": "approved", "decline": "declined"}[decision]
		result, err := tx.ExecContext(ctx, `UPDATE `+w.Comments+` SET status=$3,decided_at=NOW(),version=version+1
 WHERE id=$1 AND `+w.FK+`=$2 AND deleted_at IS NULL AND moderation_state='active'`, commentID, id, status)
		if err != nil {
			return wallComment{}, err
		}
		if n, _ := result.RowsAffected(); n != 1 {
			return wallComment{}, errDatePlanNotFound
		}
		if status == "approved" {
			var commenter string
			if err = tx.QueryRowContext(ctx, `SELECT author_id::text FROM `+w.Comments+` WHERE id=$1`, commentID).Scan(&commenter); err != nil {
				return wallComment{}, err
			}
			if err = queueReward(ctx, tx, commenter, "comment_approved", w.Noun+":"+commentID); err != nil {
				return wallComment{}, err
			}
			if err = queueReward(ctx, tx, owner, "comment_received", w.Noun+":"+commentID); err != nil {
				return wallComment{}, err
			}
			if err = w.advance(ctx, tx, id); err != nil {
				return wallComment{}, err
			}
		}
	default:
		text := strings.TrimSpace(toString(body["body"]))
		if n := runeLen(text); n < 1 || n > 500 {
			return wallComment{}, blogInputError("Write a comment of 1–500 characters")
		}
		var author, existing string
		err := tx.QueryRowContext(ctx, `SELECT author_id::text,body FROM `+w.Comments+` WHERE id=$1`, commentID).Scan(&author, &existing)
		if err == nil {
			if author == actor && existing == text {
				return w.readComment(ctx, tx, actor, id, commentID)
			}
			return wallComment{}, errDatingConflict
		}
		if !errors.Is(err, sql.ErrNoRows) {
			return wallComment{}, err
		}
		if err = canEngage(); err != nil {
			return wallComment{}, err
		}
		var today int
		if err = tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM `+w.Comments+` WHERE author_id=$1 AND created_at>NOW()-interval '1 day'`, actor).Scan(&today); err != nil {
			return wallComment{}, err
		}
		if today >= wallMaxCommentsPerDay {
			return wallComment{}, activityFail(429, "You have commented a lot today. Come back tomorrow.")
		}
		if _, err = tx.ExecContext(ctx, `INSERT INTO `+w.Comments+`(id,`+w.FK+`,author_id,`+w.OwnerCol+`,body) VALUES($1,$2,$3,$4,$5)`, commentID, id, actor, owner, text); err != nil {
			return wallComment{}, errDatingConflict
		}
		if runeLen(title) > 60 {
			title = string([]rune(title)[:57]) + "…"
		}
		if err = enqueueNotificationTx(ctx, tx, owner, actor, w.EventPrefix+".comment.pending", "system", commentID, w.EventPrefix+"-comment:"+commentID,
			"A new comment is waiting for you", "Someone commented on your "+w.Noun+" “"+title+"”. Approve it to show it to everyone.",
			w.Route, map[string]any{w.FK: id, "comment_id": commentID}, 4); err != nil {
			return wallComment{}, err
		}
	}
	return w.readComment(ctx, tx, actor, id, commentID)
}
