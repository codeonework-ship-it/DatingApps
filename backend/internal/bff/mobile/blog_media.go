package mobile

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"net/http"
	"path"
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// Tombstones hide media immediately; the existing lifecycle worker releases
// private objects with retries. Legal holds retain the underlying evidence.
func (s *Server) cleanupDeletedBlogMedia(ctx context.Context) {
	s.cleanupBlogEvidence(ctx)
	db, err := s.growthDB()
	if err != nil {
		return
	}
	rows, err := db.QueryContext(ctx, `SELECT id::text,storage_path FROM matching.blog_photos WHERE deleted_at IS NOT NULL AND NOT platform.member_on_legal_hold(author_id) AND NOT EXISTS(SELECT 1 FROM matching.blog_evidence_photos e WHERE e.storage_path=blog_photos.storage_path) LIMIT 100`)
	if err != nil {
		return
	}
	type candidate struct{ id, path string }
	items := []candidate{}
	for rows.Next() {
		var item candidate
		if err = rows.Scan(&item.id, &item.path); err != nil {
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
		if s.deleteStoredMedia(item.path) == nil {
			_, _ = db.ExecContext(ctx, `DELETE FROM matching.blog_photos WHERE id=$1 AND deleted_at IS NOT NULL`, item.id)
		}
	}
	_, _ = db.ExecContext(ctx, `UPDATE matching.blog_posts SET title='',body='',invitation='' WHERE deleted_at IS NOT NULL AND (title<>'' OR body<>'' OR invitation<>'') AND NOT platform.member_on_legal_hold(author_id)`)
}

// Decode and encode again so image metadata (including EXIF location) never
// becomes part of a journal. Limits are checked before allocating decoded pixels.
func sanitizeBlogPhoto(content []byte) (validatedPhotoUpload, error) {
	upload, err := validateProfilePhoto("chapter-photo", content)
	if err != nil {
		return upload, err
	}
	if upload.MimeType != "image/jpeg" && upload.MimeType != "image/png" {
		return upload, errors.New("Use a JPEG or PNG photo")
	}
	decoded, _, err := image.Decode(bytes.NewReader(content))
	if err != nil {
		return upload, errors.New("This image could not be decoded")
	}
	var clean bytes.Buffer
	if upload.MimeType == "image/png" {
		err = png.Encode(&clean, decoded)
	} else {
		err = jpeg.Encode(&clean, decoded, &jpeg.Options{Quality: 88})
	}
	if err != nil {
		return upload, err
	}
	return validateProfilePhoto("chapter-photo"+upload.Extension, clean.Bytes())
}

func (s *Server) blogPhotoHandler(w http.ResponseWriter, r *http.Request) {
	actor, err := requestPrincipal(r)
	if err != nil {
		writeError(w, 401, err)
		return
	}
	postID, photoID := chi.URLParam(r, "postID"), chi.URLParam(r, "photoID")
	for _, id := range []string{postID, photoID} {
		if _, err = uuid.Parse(id); err != nil {
			writeError(w, 404, errDatePlanNotFound)
			return
		}
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, 503, err)
		return
	}
	w.Header().Set("Cache-Control", "private, no-store")
	if r.Method == http.MethodGet {
		var storage, mime string
		err = db.QueryRowContext(r.Context(), `SELECT ph.storage_path,ph.mime_type FROM matching.blog_photos ph JOIN matching.blog_posts p ON p.id=ph.post_id WHERE `+blogVisible+` AND p.id=$2 AND ph.id=$3 AND ph.deleted_at IS NULL AND ph.moderation_status='approved'`, actor.UserID, postID, photoID).Scan(&storage, &mime)
		if err != nil {
			writeError(w, 404, errDatePlanNotFound)
			return
		}
		var content bytes.Buffer
		if err = s.copyPrivateMedia(r.Context(), &content, storage); err != nil {
			writeError(w, 404, errDatePlanNotFound)
			return
		}
		w.Header().Set("Content-Type", mime)
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Content-Disposition", "inline; filename=chapter-photo")
		_, _ = w.Write(content.Bytes())
		return
	}
	var version int
	var upload validatedPhotoUpload
	alt := ""
	if r.Method == http.MethodPut {
		r.Body = http.MaxBytesReader(w, r.Body, 11<<20)
		if err = r.ParseMultipartForm(1 << 20); err != nil {
			writeError(w, 400, errors.New("Invalid image upload (maximum 10 MB)"))
			return
		}
		defer r.MultipartForm.RemoveAll()
		version, err = strconv.Atoi(r.FormValue("expected_version"))
		if err != nil || version < 1 || version > 2147483646 {
			writeError(w, 400, errors.New("expected_version is required"))
			return
		}
		alt = strings.TrimSpace(r.FormValue("alt_text"))
		if utf8.RuneCountInString(alt) < 1 || utf8.RuneCountInString(alt) > 160 {
			writeError(w, 400, errors.New("Describe the image in 1–160 characters"))
			return
		}
		// Authorize before decoding or calling moderation on untrusted input.
		current, e := readBlog(r.Context(), db, actor.UserID, postID)
		if e != nil || current.AuthorID != actor.UserID {
			writeError(w, 404, errDatePlanNotFound)
			return
		}
		if current.Audience != "private" {
			writeError(w, 409, errors.New("Save as Only me before changing photos"))
			return
		}
		file, _, e := r.FormFile("image")
		if e != nil {
			writeError(w, 400, errors.New("Choose a JPEG or PNG photo"))
			return
		}
		defer file.Close()
		content, e := io.ReadAll(io.LimitReader(file, maxProfilePhotoBytes+1))
		if e != nil {
			writeError(w, 400, e)
			return
		}
		upload, err = sanitizeBlogPhoto(content)
		if err != nil {
			writeError(w, mediaUploadHTTPStatus(err), err)
			return
		}
		if s.mediaModerator == nil {
			writeError(w, 503, errors.New("Photo moderation is unavailable"))
			return
		}
		upload.Moderation, err = s.mediaModerator.Moderate(r.Context(), upload)
		if err != nil {
			writeError(w, 503, errors.New("Photo moderation is unavailable; please retry"))
			return
		}
		if upload.Moderation.Status != mediaModerationApproved {
			writeError(w, 422, errors.New("This photo could not be approved. It has not been added to your chapter"))
			return
		}
	} else {
		body, ok := readJSON(w, r)
		if !ok {
			return
		}
		v, ok := body["expected_version"].(float64)
		if !ok || v < 1 || v > 2147483646 || v != float64(int(v)) {
			writeError(w, 400, errors.New("expected_version is required"))
			return
		}
		version = int(v)
	}
	tx, err := db.BeginTx(r.Context(), nil)
	if err != nil {
		writeError(w, 503, err)
		return
	}
	defer tx.Rollback()
	if err = lockBlogAuthor(r.Context(), tx, actor.UserID); err != nil {
		writeBlogError(w, err)
		return
	}
	current, err := readBlog(r.Context(), tx, actor.UserID, postID)
	if err != nil || current.AuthorID != actor.UserID {
		writeError(w, 404, errDatePlanNotFound)
		return
	}
	if current.Audience != "private" {
		writeError(w, 409, errors.New("Save as Only me before changing photos"))
		return
	}
	var existingHash, existingAlt, existingPost string
	err = tx.QueryRowContext(r.Context(), `SELECT content_sha256,alt_text,post_id::text FROM matching.blog_photos WHERE id=$1 AND author_id=$2 AND deleted_at IS NULL`, photoID, actor.UserID).Scan(&existingHash, &existingAlt, &existingPost)
	if r.Method == http.MethodPut && err == nil {
		hash := sha256.Sum256(upload.Content)
		if existingPost == postID && existingHash == hex.EncodeToString(hash[:]) && existingAlt == alt {
			writeJSON(w, 200, map[string]any{"post": current})
			return
		}
		writeBlogError(w, errDatingConflict)
		return
	}
	if current.Version != version {
		writeBlogError(w, errDatingConflict)
		return
	}
	stored := ""
	if r.Method == http.MethodPut {
		if len(current.Photos) >= 6 {
			writeError(w, 400, errors.New("Use up to six photos per chapter"))
			return
		}
		var total int64
		if err = tx.QueryRowContext(r.Context(), `SELECT COALESCE(SUM(size_bytes),0) FROM matching.blog_photos WHERE author_id=$1`, actor.UserID).Scan(&total); err != nil {
			writeError(w, 503, err)
			return
		}
		if total+upload.SizeBytes > 100<<20 {
			writeError(w, 400, errors.New("Your journal photo storage is full (100 MB)"))
			return
		}
		namespace := path.Join("private", "blog", actor.UserID, postID)
		// A separate random storage key prevents concurrent retries from replacing
		// a committed object's bytes before the database resolves UUID ownership.
		filename := uuid.NewString() + upload.Extension
		stored, err = s.storeMedia(r.Context(), namespace, filename, upload.MimeType, upload.Content)
		if err != nil {
			writeError(w, 503, errors.New("Photo storage is unavailable"))
			return
		}
		committed := false
		defer func() {
			if !committed {
				_ = s.deleteStoredMedia(stored)
			}
		}()
		_, err = tx.ExecContext(r.Context(), `INSERT INTO matching.blog_photos(id,post_id,author_id,alt_text,storage_path,mime_type,size_bytes,content_sha256,moderation_status,moderation_provider) VALUES($1,$2,$3,$4,$5,$6,$7,$8,'approved',$9)`, photoID, postID, actor.UserID, alt, stored, upload.MimeType, upload.SizeBytes, upload.ContentSHA256, upload.Moderation.Provider)
		if err != nil {
			writeBlogError(w, errDatingConflict)
			return
		}
		if _, err = tx.ExecContext(r.Context(), `UPDATE matching.blog_posts SET version=version+1,updated_at=NOW() WHERE id=$1`, postID); err != nil {
			writeError(w, 503, err)
			return
		}
		updated, e := readBlog(r.Context(), tx, actor.UserID, postID)
		if e != nil {
			writeError(w, 503, e)
			return
		}
		if err = tx.Commit(); err != nil {
			// Commit outcome may be uncertain; retain the object for authoritative
			// reconciliation instead of deleting bytes that might now be referenced.
			committed = true
			writeError(w, 503, errors.New("Upload confirmation is pending; reload your chapter"))
			return
		}
		committed = true
		writeJSON(w, 200, map[string]any{"post": updated})
		return
	}
	result, err := tx.ExecContext(r.Context(), `UPDATE matching.blog_photos SET deleted_at=NOW() WHERE id=$1 AND post_id=$2 AND author_id=$3 AND deleted_at IS NULL`, photoID, postID, actor.UserID)
	if err != nil {
		writeError(w, 503, err)
		return
	}
	n, _ := result.RowsAffected()
	if n != 1 {
		writeError(w, 404, errDatePlanNotFound)
		return
	}
	if _, err = tx.ExecContext(r.Context(), `UPDATE matching.blog_posts SET version=version+1,updated_at=NOW() WHERE id=$1`, postID); err != nil {
		writeError(w, 503, err)
		return
	}
	updated, err := readBlog(r.Context(), tx, actor.UserID, postID)
	if err != nil {
		writeError(w, 503, err)
		return
	}
	if err = tx.Commit(); err != nil {
		writeError(w, 503, err)
		return
	}
	writeJSON(w, 200, map[string]any{"post": updated})
}
