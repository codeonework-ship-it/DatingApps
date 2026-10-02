package mobile

import (
	"context"
	"database/sql"
	"errors"
	"io"
	"net/http"
	"path"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediastore"
)

// Group cover photos (migration 121, matching.community_group_covers).
//
//   - Who: the group owner uploads, replaces and removes the cover (the same
//     rule as editing the group; moderators cannot). Not while the group is
//     removed after a review: the reviewed content stays as reviewed.
//   - Upload: PUT /v1/engagement/groups/{id}/cover, multipart "image" (JPEG or
//     PNG, at most 10 MB, 300–4096 px a side) and an optional client "cover_id"
//     UUID so a retried upload returns the saved result. The image is decoded
//     and re-encoded (sanitizeBlogPhoto, as Photo Themes) so EXIF and other
//     metadata, location included, never reach storage. At most 10 uploads per
//     group per day (rejections count).
//   - Moderation: the shared media moderator. approved: shown to everyone who
//     can see the group. review_required: stored as "pending", shown to the
//     owner only ("Under review") and queued for operators
//     (/v1/admin/moderation/group-covers). rejected: nothing is stored, the
//     previous cover stays, 422. An operator rejection hides the cover and
//     notifies the owner (group.cover.rejected).
//   - Serving: GET /v1/engagement/groups/{id}/cover streams the live cover to
//     viewers who may see it (groupCoverVisibleSQL), with an ETag (content
//     SHA-256) and Cache-Control "private, max-age=300" (pending: no-store).
//   - Storage: group_covers/<group>/<cover>.<ext> through the media store.
//     Replaced, removed, rejected and deleted-group covers are tombstoned and
//     their objects released right after the change, retried by the hourly
//     media worker; a cover held as report evidence or uploaded by a member on
//     legal hold is kept until released.

const (
	groupCoverUploadsPerDay = 10
	groupCoverMaxBytes      = maxProfilePhotoBytes
)

// groupCoverVisibleSQL: viewer $1 may see live cover cv of group g. The
// caller has already checked the viewer may see the group. Removed groups
// show no cover; pending covers are the owner's only; a cover uploaded by
// someone either side has blocked is hidden.
const groupCoverVisibleSQL = `g.moderation_state='active'
 AND (cv.moderation_status='approved' OR (cv.moderation_status='pending' AND g.created_by_user_id=$1::uuid))
 AND (cv.uploaded_by IS NULL OR cv.uploaded_by=$1::uuid OR NOT EXISTS(SELECT 1 FROM user_management.blocked_users cbl
  WHERE (cbl.user_id=$1::uuid AND cbl.blocked_user_id=cv.uploaded_by) OR (cbl.user_id=cv.uploaded_by AND cbl.blocked_user_id=$1::uuid)))`

// groupCoverURL is the API path of a group's cover. The cover id makes the
// URL change whenever the photo does, so clients can cache by URL.
func groupCoverURL(groupID, coverID string) string {
	return "/v1/engagement/groups/" + groupID + "/cover?v=" + coverID
}

var (
	errGroupCoverOwnerOnly = activityFail(http.StatusForbidden, "Only the group owner can change the cover photo.")
	errGroupCoverRateLimit = activityFail(http.StatusTooManyRequests, "This group's cover changed 10 times today. Try again tomorrow.")
	errGroupCoverRejected  = activityFail(http.StatusUnprocessableEntity, "This photo could not be approved. Your cover was not changed.")
)

// groupCoverPrecheck authorizes a cover change and detects a retried upload.
// It returns the earlier upload's moderation status when coverID was already
// used by the actor for this group ("" for a new upload).
func groupCoverPrecheck(ctx context.Context, q blogQuerier, actor, groupID, coverID string, uploading bool) (string, error) {
	g, err := readGroup(ctx, q, actor, groupID)
	if err != nil {
		return "", err
	}
	if !g.IsMember {
		return "", errDatePlanNotFound
	}
	if g.MyRole != "owner" {
		return "", errGroupCoverOwnerOnly
	}
	if uploading && coverID != "" {
		var group, uploader, status string
		err = q.QueryRowContext(ctx, `SELECT group_id::text,COALESCE(uploaded_by::text,''),moderation_status FROM matching.community_group_covers WHERE id=$1::uuid`, coverID).
			Scan(&group, &uploader, &status)
		switch {
		case err == nil && group == groupID && uploader == actor:
			return status, nil
		case err == nil:
			return "", errDatingConflict
		case !errors.Is(err, sql.ErrNoRows):
			return "", err
		}
	}
	if g.Removed {
		return "", errGroupRemoved
	}
	if uploading {
		var recent int
		if err = q.QueryRowContext(ctx, `SELECT COUNT(*) FROM matching.community_group_covers WHERE group_id=$1::uuid AND created_at>NOW()-interval '1 day'`, groupID).Scan(&recent); err != nil {
			return "", err
		}
		if recent >= groupCoverUploadsPerDay {
			return "", errGroupCoverRateLimit
		}
	}
	return "", nil
}

// GET, PUT and DELETE /v1/engagement/groups/{groupID}/cover
func (s *Server) groupCoverHandler(w http.ResponseWriter, r *http.Request) {
	actor, db, groupID, ok := s.groupFromPath(w, r)
	if !ok {
		return
	}
	switch r.Method {
	case http.MethodPut:
		s.putGroupCover(w, r, db, actor, groupID)
	case http.MethodDelete:
		s.deleteGroupCover(w, r, db, actor, groupID)
	default:
		s.serveGroupCover(w, r, db, actor, groupID)
	}
}

func (s *Server) serveGroupCover(w http.ResponseWriter, r *http.Request, db *sql.DB, actor, groupID string) {
	if _, err := readGroup(r.Context(), db, actor, groupID); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	var key, mime, digest, status string
	err := db.QueryRowContext(r.Context(), `SELECT cv.storage_path,cv.mime_type,cv.content_sha256,cv.moderation_status
 FROM matching.community_group_covers cv JOIN matching.community_groups g ON g.id=cv.group_id
 WHERE cv.group_id=$2::uuid AND cv.deleted_at IS NULL AND `+groupCoverVisibleSQL, actor, groupID).Scan(&key, &mime, &digest, &status)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("This group has no cover photo."))
		return
	}
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	cache := mediastore.ResponseCacheControl(mediastore.VisibilityPublic)
	if status != "approved" {
		cache = "private, no-store"
	}
	etag := `"` + digest + `"`
	header := w.Header()
	header.Set("Cache-Control", cache)
	header.Set("ETag", etag)
	header.Set("X-Content-Type-Options", "nosniff")
	if etagMatches(r.Header.Get("If-None-Match"), etag) {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	store, err := s.mediaStore()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("Photo storage is temporarily unavailable."))
		return
	}
	object, err := store.Open(r.Context(), key)
	if err != nil {
		header.Del("ETag")
		header.Set("Cache-Control", "private, no-store")
		if errors.Is(err, mediastore.ErrNotFound) {
			writeError(w, http.StatusNotFound, errors.New("This group has no cover photo."))
			return
		}
		writeError(w, http.StatusServiceUnavailable, errors.New("Photo storage is temporarily unavailable."))
		return
	}
	defer object.Body.Close()
	header.Set("Content-Type", mime)
	header.Set("Content-Disposition", "inline; filename=group-cover")
	if object.Size > 0 {
		header.Set("Content-Length", strconv.FormatInt(object.Size, 10))
	}
	w.WriteHeader(http.StatusOK)
	if r.Method == http.MethodHead {
		return
	}
	if _, err = io.Copy(w, object.Body); err != nil && s.log != nil {
		s.log.Warn("stream group cover failed", zap.Error(err))
	}
}

// etagMatches implements If-None-Match for a strong ETag.
func etagMatches(header, etag string) bool {
	for _, candidate := range strings.Split(header, ",") {
		candidate = strings.TrimPrefix(strings.TrimSpace(candidate), "W/")
		if candidate == "*" || candidate == etag {
			return true
		}
	}
	return false
}

func (s *Server) putGroupCover(w http.ResponseWriter, r *http.Request, db *sql.DB, actor, groupID string) {
	r.Body = http.MaxBytesReader(w, r.Body, groupCoverMaxBytes+(1<<20))
	if err := r.ParseMultipartForm(1 << 20); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("Invalid image upload (maximum 10 MB)"))
		return
	}
	defer r.MultipartForm.RemoveAll()
	coverID := strings.TrimSpace(r.FormValue("cover_id"))
	if coverID == "" {
		coverID = uuid.NewString()
	} else if _, err := uuid.Parse(coverID); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("cover_id must be a UUID"))
		return
	}
	coverID = strings.ToLower(coverID)
	ctx := r.Context()
	// Authorize and detect retries before decoding untrusted bytes.
	replayed, err := groupCoverPrecheck(ctx, db, actor, groupID, coverID, true)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if replayed != "" {
		s.writeGroupCoverResult(w, ctx, db, actor, groupID, coverID, replayed)
		return
	}
	file, _, err := r.FormFile("image")
	if err != nil {
		writeError(w, http.StatusBadRequest, errors.New("Choose a JPEG or PNG photo"))
		return
	}
	defer file.Close()
	content, err := io.ReadAll(io.LimitReader(file, groupCoverMaxBytes+1))
	if err != nil {
		writeError(w, http.StatusBadRequest, errors.New("Invalid image upload (maximum 10 MB)"))
		return
	}
	upload, err := sanitizeBlogPhoto(content)
	if err != nil {
		writeError(w, mediaUploadHTTPStatus(err), err)
		return
	}
	if s.mediaModerator == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("Photo moderation is unavailable"))
		return
	}
	moderation, err := s.mediaModerator.Moderate(ctx, upload)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("Photo moderation is unavailable; please retry"))
		return
	}
	status := ""
	switch moderation.Status {
	case mediaModerationApproved:
		status = "approved"
	case mediaModerationReviewRequired:
		status = "pending"
	default:
		status = "rejected"
	}
	reason := moderation.Reason
	if utf8.RuneCountInString(reason) > 200 {
		reason = string([]rune(reason)[:200])
	}

	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	defer tx.Rollback()
	if _, _, _, _, err = lockGroup(ctx, tx, groupID); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if replayed, err = groupCoverPrecheck(ctx, tx, actor, groupID, coverID, true); err != nil || replayed != "" {
		if err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
		_ = tx.Rollback()
		s.writeGroupCoverResult(w, ctx, db, actor, groupID, coverID, replayed)
		return
	}
	if status == "rejected" {
		// Recorded without bytes: it counts towards the daily limit and lets a
		// retry of the same cover_id get the same answer.
		if _, err = tx.ExecContext(ctx, `INSERT INTO matching.community_group_covers(id,group_id,uploaded_by,mime_type,width_px,height_px,size_bytes,content_sha256,
 moderation_status,moderation_reason,moderation_provider,deleted_at,delete_reason,storage_released_at)
 VALUES($1,$2,$3,$4,$5,$6,$7,$8,'rejected',$9,$10,NOW(),'rejected',NOW())`,
			coverID, groupID, actor, upload.MimeType, upload.WidthPx, upload.HeightPx, upload.SizeBytes, upload.ContentSHA256, reason, moderation.Provider); err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
		if err = tx.Commit(); err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
		s.recordGroupActivity(actor, "community_group_cover_rejected", groupID, map[string]any{"cover_id": coverID})
		writeActivityError(w, errGroupCoverRejected, groupsUnavailable)
		return
	}
	stored, err := s.storeMedia(ctx, path.Join("group_covers", groupID), coverID+upload.Extension, upload.MimeType, upload.Content)
	if err != nil {
		writeError(w, mediaUploadHTTPStatus(err), errors.New("Photo storage is unavailable"))
		return
	}
	committed := false
	defer func() {
		if !committed {
			_ = s.deleteStoredMedia(stored)
		}
	}()
	if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_covers SET deleted_at=NOW(),delete_reason='replaced' WHERE group_id=$1::uuid AND deleted_at IS NULL`, groupID); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if _, err = tx.ExecContext(ctx, `INSERT INTO matching.community_group_covers(id,group_id,uploaded_by,storage_path,mime_type,width_px,height_px,size_bytes,content_sha256,
 moderation_status,moderation_reason,moderation_provider) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
		coverID, groupID, actor, stored, upload.MimeType, upload.WidthPx, upload.HeightPx, upload.SizeBytes, upload.ContentSHA256, status, reason, moderation.Provider); err != nil {
		writeActivityError(w, errDatingConflict, groupsUnavailable)
		return
	}
	if _, err = tx.ExecContext(ctx, `UPDATE matching.community_groups SET updated_at=NOW() WHERE id=$1::uuid`, groupID); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	g, err := readGroupDetail(ctx, tx, actor, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if err = tx.Commit(); err != nil {
		// The outcome is uncertain; keep the object for the worker to reconcile.
		committed = true
		writeError(w, http.StatusServiceUnavailable, errors.New("Upload confirmation is pending; reload the group"))
		return
	}
	committed = true
	s.releaseGroupCoverMedia(context.WithoutCancel(ctx), groupID)
	s.recordGroupActivity(actor, "community_group_cover_uploaded", groupID, map[string]any{"cover_id": coverID, "status": status})
	writeJSON(w, http.StatusOK, map[string]any{"group": g, "cover": map[string]any{"id": coverID, "status": status}})
}

// writeGroupCoverResult answers a retried upload with the saved outcome.
func (s *Server) writeGroupCoverResult(w http.ResponseWriter, ctx context.Context, db *sql.DB, actor, groupID, coverID, status string) {
	if status == "rejected" {
		writeActivityError(w, errGroupCoverRejected, groupsUnavailable)
		return
	}
	g, err := readGroupDetail(ctx, db, actor, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"group": g, "cover": map[string]any{"id": coverID, "status": status}})
}

func (s *Server) deleteGroupCover(w http.ResponseWriter, r *http.Request, db *sql.DB, actor, groupID string) {
	ctx := r.Context()
	tx, err := groupBegin(ctx, db, actor)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	defer tx.Rollback()
	if _, _, _, _, err = lockGroup(ctx, tx, groupID); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if _, err = groupCoverPrecheck(ctx, tx, actor, groupID, "", false); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	result, err := tx.ExecContext(ctx, `UPDATE matching.community_group_covers SET deleted_at=NOW(),delete_reason='removed' WHERE group_id=$1::uuid AND deleted_at IS NULL`, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	removed, _ := result.RowsAffected()
	// Removing also dismisses a "not approved" notice.
	if _, err = tx.ExecContext(ctx, `UPDATE matching.community_group_covers SET delete_reason='rejected_seen' WHERE group_id=$1::uuid AND delete_reason='rejected'`, groupID); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if removed > 0 {
		if _, err = tx.ExecContext(ctx, `UPDATE matching.community_groups SET updated_at=NOW() WHERE id=$1::uuid`, groupID); err != nil {
			writeActivityError(w, err, groupsUnavailable)
			return
		}
	}
	g, err := readGroupDetail(ctx, tx, actor, groupID)
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if err = tx.Commit(); err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	s.releaseGroupCoverMedia(context.WithoutCancel(ctx), groupID)
	if removed > 0 {
		s.recordGroupActivity(actor, "community_group_cover_removed", groupID, nil)
	}
	writeJSON(w, http.StatusOK, map[string]any{"group": g, "removed": removed > 0})
}

// releaseGroupCoverMedia deletes the objects of covers that are no longer
// live (replaced, removed, rejected, group deleted, erased) and marks them
// released. A cover held as report evidence, or uploaded by a member on legal
// hold, is kept. groupID limits the sweep to one group ("" for all, which
// also purges release records older than 30 days). Failures are retried by
// the hourly media worker.
func (s *Server) releaseGroupCoverMedia(ctx context.Context, groupID string) {
	db, err := s.growthDB()
	if err != nil {
		return
	}
	rows, err := db.QueryContext(ctx, `SELECT c.id::text,c.storage_path FROM matching.community_group_covers c
 WHERE c.deleted_at IS NOT NULL AND c.storage_released_at IS NULL AND ($1='' OR c.group_id::text=$1)
 AND (c.uploaded_by IS NULL OR NOT platform.member_on_legal_hold(c.uploaded_by))
 AND NOT EXISTS(SELECT 1 FROM matching.blog_evidence_photos ev WHERE ev.storage_path=c.storage_path)
 ORDER BY c.deleted_at LIMIT 100`, groupID)
	if err != nil {
		return
	}
	type candidate struct{ id, key string }
	items := []candidate{}
	for rows.Next() {
		var item candidate
		if rows.Scan(&item.id, &item.key) != nil {
			rows.Close()
			return
		}
		items = append(items, item)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return
	}
	for _, item := range items {
		if item.key != "" {
			if err := s.deleteStoredMedia(item.key); err != nil {
				if s.log != nil {
					s.log.Warn("group cover release failed", zap.String("cover_id", item.id), zap.Error(err))
				}
				continue
			}
		}
		_, _ = db.ExecContext(ctx, `UPDATE matching.community_group_covers SET storage_released_at=NOW() WHERE id=$1::uuid AND deleted_at IS NOT NULL`, item.id)
	}
	if groupID == "" {
		_, _ = db.ExecContext(ctx, `DELETE FROM matching.community_group_covers WHERE storage_released_at<NOW()-interval '30 days'`)
	}
}

// ---------------------------------------------------------------------------
// Operator review of covers the moderation provider sent to a human.
// ---------------------------------------------------------------------------

type groupCoverReviewItem struct {
	CoverID    string `json:"cover_id"`
	GroupID    string `json:"group_id"`
	GroupName  string `json:"group_name"`
	GroupKind  string `json:"group_kind"`
	OwnerID    string `json:"owner_user_id"`
	UploadedBy string `json:"uploaded_by"`
	Status     string `json:"status"`
	Reason     string `json:"reason"`
	Provider   string `json:"provider"`
	MimeType   string `json:"mime_type"`
	WidthPx    int    `json:"width_px"`
	HeightPx   int    `json:"height_px"`
	SizeBytes  int64  `json:"size_bytes"`
	UploadedAt string `json:"uploaded_at"`
	ContentURL string `json:"content_url"`
}

var adminGroupCoversSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 200,
	Sorts:       map[string]string{"created_at": "cv.created_at"},
	DefaultSort: "created_at", DefaultOrder: "asc", TieBreak: "cv.id",
}

// GET /v1/admin/moderation/group-covers?status=pending|approved&limit=&offset=&q=&from=&to=&order=
func (s *Server) adminGroupCoversHandler(w http.ResponseWriter, r *http.Request) {
	if _, err := blogModerator(r); err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	if status == "" {
		status = "pending"
	}
	if status != "pending" && status != "approved" {
		writeError(w, http.StatusBadRequest, errors.New("status must be pending or approved"))
		return
	}
	// The pending queue reads oldest first; the approved history newest first.
	spec := adminGroupCoversSpec
	if status == "approved" {
		spec.DefaultOrder = "desc"
	}
	page, err := parseAdminListParams(r, spec)
	if err != nil {
		writeAdminListParamError(w, err)
		return
	}
	filter := newSQLFilter("cv.deleted_at IS NULL")
	filter.Eq("cv.moderation_status", status)
	filter.Search(page.Q, "g.name")
	filter.TimeRange("cv.created_at", page)
	items := []groupCoverReviewItem{}
	total, err := queryAdminPage(r.Context(), db, `cv.id::text,cv.group_id::text,COALESCE(g.name,''),COALESCE(g.kind,''),COALESCE(g.created_by_user_id::text,''),
 COALESCE(cv.uploaded_by::text,''),cv.moderation_status,cv.moderation_reason,cv.moderation_provider,cv.mime_type,cv.width_px,cv.height_px,cv.size_bytes,
 to_char(cv.created_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"')`,
		` FROM matching.community_group_covers cv LEFT JOIN matching.community_groups g ON g.id=cv.group_id`, filter, page,
		func(rows *sql.Rows) error {
			var item groupCoverReviewItem
			if err := rows.Scan(&item.CoverID, &item.GroupID, &item.GroupName, &item.GroupKind, &item.OwnerID, &item.UploadedBy, &item.Status, &item.Reason,
				&item.Provider, &item.MimeType, &item.WidthPx, &item.HeightPx, &item.SizeBytes, &item.UploadedAt); err != nil {
				return err
			}
			item.ContentURL = "/v1/admin/moderation/group-covers/" + item.CoverID + "/content"
			items = append(items, item)
			return nil
		})
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, page.Page(map[string]any{"items": items, "count": len(items), "status": status}, total))
}

// GET /v1/admin/moderation/group-covers/{coverID}/content
func (s *Server) adminGroupCoverContentHandler(w http.ResponseWriter, r *http.Request) {
	if _, err := blogModerator(r); err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	coverID := chi.URLParam(r, "coverID")
	if !activityUUID(w, coverID) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var key, mime string
	if err = db.QueryRowContext(r.Context(), `SELECT storage_path,mime_type FROM matching.community_group_covers WHERE id=$1::uuid AND storage_path<>'' AND storage_released_at IS NULL`, coverID).Scan(&key, &mime); err != nil {
		writeError(w, http.StatusNotFound, errors.New("cover not found"))
		return
	}
	s.streamStoredObject(w, r, key, mime, "private, no-store")
}

// POST /v1/admin/moderation/group-covers/{coverID}/decision {decision, reason}
func (s *Server) adminGroupCoverDecisionHandler(w http.ResponseWriter, r *http.Request) {
	operator, err := blogModerator(r)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	coverID := chi.URLParam(r, "coverID")
	if !activityUUID(w, coverID) {
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	body, ok := readJSON(w, r)
	if !ok {
		return
	}
	status, groupID, err := decideGroupCover(r.Context(), db, operator, coverID, toString(body["decision"]), toString(body["reason"]))
	if err != nil {
		writeActivityError(w, err, groupsUnavailable)
		return
	}
	if status == "rejected" {
		s.releaseGroupCoverMedia(context.WithoutCancel(r.Context()), groupID)
	}
	writeJSON(w, http.StatusOK, map[string]any{"cover_id": coverID, "group_id": groupID, "status": status})
}

// decideGroupCover approves or rejects a pending cover. Repeating the same
// decision is a no-op; a cover that is no longer pending cannot be decided
// differently (409). A rejection hides the cover at once and tells the owner.
func decideGroupCover(ctx context.Context, db *sql.DB, operator, coverID, decision, reason string) (string, string, error) {
	switch strings.ToLower(strings.TrimSpace(decision)) {
	case "approve", "approved":
		decision = "approved"
	case "reject", "rejected":
		decision = "rejected"
	default:
		return "", "", blogInputError("Choose approved or rejected")
	}
	reason = strings.TrimSpace(reason)
	if utf8.RuneCountInString(reason) > 200 {
		return "", "", blogInputError("Keep the reason under 200 characters")
	}
	if decision == "rejected" && reason == "" {
		reason = "Did not meet the photo guidelines"
	}
	reviewer := ""
	if _, err := uuid.Parse(operator); err == nil {
		reviewer = operator
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback()
	var groupID, status, deleteReason string
	var live bool
	err = tx.QueryRowContext(ctx, `SELECT group_id::text,moderation_status,COALESCE(delete_reason,''),deleted_at IS NULL FROM matching.community_group_covers WHERE id=$1::uuid FOR UPDATE`, coverID).
		Scan(&groupID, &status, &deleteReason, &live)
	if errors.Is(err, sql.ErrNoRows) {
		return "", "", errDatePlanNotFound
	}
	if err != nil {
		return "", "", err
	}
	if !live || status != "pending" {
		if (decision == "approved" && live && status == "approved") || (decision == "rejected" && status == "rejected") {
			return status, groupID, tx.Commit()
		}
		return "", "", activityFail(http.StatusConflict, "This cover is no longer waiting for review.")
	}
	if decision == "approved" {
		_, err = tx.ExecContext(ctx, `UPDATE matching.community_group_covers SET moderation_status='approved',reviewed_by=NULLIF($2,'')::uuid,reviewed_at=NOW() WHERE id=$1::uuid`, coverID, reviewer)
	} else {
		_, err = tx.ExecContext(ctx, `UPDATE matching.community_group_covers SET moderation_status='rejected',moderation_reason=$3,reviewed_by=NULLIF($2,'')::uuid,reviewed_at=NOW(),
 deleted_at=NOW(),delete_reason='rejected' WHERE id=$1::uuid`, coverID, reviewer, reason)
	}
	if err != nil {
		return "", "", err
	}
	var owner, name string
	err = tx.QueryRowContext(ctx, `UPDATE matching.community_groups SET updated_at=NOW() WHERE id=$1::uuid RETURNING created_by_user_id::text,name`, groupID).Scan(&owner, &name)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return "", "", err
	}
	if decision == "rejected" && owner != "" {
		// A system notice (no actor), like other review outcomes.
		if err = enqueueNotificationTx(ctx, tx, owner, "", "group.cover.rejected", "system", groupID, "group-cover-rejected:"+coverID,
			"Your cover photo for "+name+" wasn't approved",
			"It didn't meet our photo guidelines, so the group shows its emoji cover. You can choose a different photo.", "/groups",
			map[string]any{"group_id": groupID, "cover_id": coverID}, 4); err != nil {
			return "", "", err
		}
	}
	return decision, groupID, tx.Commit()
}
