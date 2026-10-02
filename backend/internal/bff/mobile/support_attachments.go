package mobile

import (
	"bytes"
	"compress/zlib"
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"mime/multipart"
	"net/http"
	"path"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/mediastore"
)

// Support ticket attachments (migration 126): screenshots and PDFs a member
// adds to a request. Stored under the private media kind
// support_attachments (key prefix private/support/<member>/...), never served
// by nginx or a CDN; every read goes through the API and is authorised against
// the ticket. Images are decoded and re-encoded so EXIF, GPS and any trailing
// payload are dropped; PDFs are accepted only when they carry no active
// content (JavaScript, launch actions, embedded files).

const (
	supportImageMaxBytes      = 8 << 20
	supportPDFMaxBytes        = 10 << 20
	supportUploadMaxBytes     = supportPDFMaxBytes + 64<<10
	supportImageMaxPixels     = 8000
	supportPendingUploadTTL   = 24 * time.Hour
	supportUploadsPerHour     = 30
	supportMaxPendingUploads  = 20
	supportAttachmentFileName = 120
)

// supportPDFActiveContent are PDF name objects that run code or open other
// content. Ticket attachments never need them, so a file using one is refused.
var supportPDFActiveContent = []string{"/JavaScript", "/JS", "/Launch", "/EmbeddedFile", "/OpenAction", "/AA", "/RichMedia", "/XFA", "/SubmitForm", "/ImportData"}

type supportUpload struct {
	ContentType string
	Extension   string
	Width       int
	Height      int
	Content     []byte
}

// sanitizeSupportUpload sniffs the real type (the declared type and name are
// ignored), enforces limits and strips metadata.
func sanitizeSupportUpload(content []byte) (supportUpload, error) {
	if len(content) == 0 {
		return supportUpload{}, newMediaUploadError(http.StatusBadRequest, "The file is empty.")
	}
	switch {
	case isJPEG(content) || isPNG(content):
		if len(content) > supportImageMaxBytes {
			return supportUpload{}, newMediaUploadError(http.StatusRequestEntityTooLarge, "Images can be up to 8 MB.")
		}
		cfg, format, err := image.DecodeConfig(bytes.NewReader(content))
		if err != nil || (format != "jpeg" && format != "png") {
			return supportUpload{}, newMediaUploadError(http.StatusUnsupportedMediaType, "This image could not be read. Use a JPEG or PNG.")
		}
		if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > supportImageMaxPixels || cfg.Height > supportImageMaxPixels {
			return supportUpload{}, newMediaUploadError(http.StatusUnprocessableEntity, fmt.Sprintf("Images can be at most %d × %d pixels.", supportImageMaxPixels, supportImageMaxPixels))
		}
		decoded, _, err := image.Decode(bytes.NewReader(content))
		if err != nil {
			return supportUpload{}, newMediaUploadError(http.StatusUnsupportedMediaType, "This image could not be read. Use a JPEG or PNG.")
		}
		var clean bytes.Buffer
		upload := supportUpload{Width: cfg.Width, Height: cfg.Height}
		if format == "png" {
			err = png.Encode(&clean, decoded)
			upload.ContentType, upload.Extension = "image/png", ".png"
		} else {
			err = jpeg.Encode(&clean, decoded, &jpeg.Options{Quality: 88})
			upload.ContentType, upload.Extension = "image/jpeg", ".jpg"
		}
		if err != nil {
			return supportUpload{}, newMediaUploadError(http.StatusUnprocessableEntity, "This image could not be processed.")
		}
		if clean.Len() > supportPDFMaxBytes {
			return supportUpload{}, newMediaUploadError(http.StatusRequestEntityTooLarge, "Images can be up to 8 MB.")
		}
		upload.Content = clean.Bytes()
		return upload, nil
	case bytes.HasPrefix(content, []byte("%PDF-")):
		if len(content) > supportPDFMaxBytes {
			return supportUpload{}, newMediaUploadError(http.StatusRequestEntityTooLarge, "PDFs can be up to 10 MB.")
		}
		if !bytes.Contains(content[max(0, len(content)-2048):], []byte("%%EOF")) {
			return supportUpload{}, newMediaUploadError(http.StatusUnsupportedMediaType, "This PDF looks incomplete.")
		}
		if pdfHasActiveContent(content) {
			return supportUpload{}, newMediaUploadError(http.StatusUnsupportedMediaType, "PDFs with scripts, forms or embedded files are not accepted. Please send a screenshot instead.")
		}
		return supportUpload{ContentType: "application/pdf", Extension: ".pdf", Content: content}, nil
	default:
		return supportUpload{}, newMediaUploadError(http.StatusUnsupportedMediaType, "Attach a JPEG or PNG screenshot, or a PDF.")
	}
}

var (
	supportPDFName   = regexp.MustCompile(`/[^\x00\t\n\f\r /()<>\[\]{}%]+`)
	supportPDFStream = regexp.MustCompile(`stream\r?\n`)
	supportPDFEscape = regexp.MustCompile(`#([0-9A-Fa-f]{2})`)
)

// pdfHasActiveContent reports whether a PDF uses any of the refused name
// objects, in the file itself or inside its Flate-compressed streams (object
// streams hide dictionaries there). "#xx" escapes in names are decoded first,
// the usual way to disguise /JavaScript.
func pdfHasActiveContent(content []byte) bool {
	if pdfNamesActive(content) {
		return true
	}
	budget := 32 << 20 // total inflated bytes inspected
	for _, loc := range supportPDFStream.FindAllIndex(content, 2000) {
		start := loc[1]
		end := bytes.Index(content[start:], []byte("endstream"))
		if end < 0 || budget <= 0 {
			continue
		}
		reader, err := zlib.NewReader(bytes.NewReader(content[start : start+end]))
		if err != nil {
			continue
		}
		inflated, _ := io.ReadAll(io.LimitReader(reader, int64(budget)))
		_ = reader.Close()
		budget -= len(inflated)
		if pdfNamesActive(inflated) {
			return true
		}
	}
	return false
}

func pdfNamesActive(content []byte) bool {
	for _, raw := range supportPDFName.FindAll(content, -1) {
		name := string(raw)
		if strings.Contains(name, "#") {
			name = supportPDFEscape.ReplaceAllStringFunc(name, func(esc string) string {
				value, err := strconv.ParseUint(esc[1:], 16, 8)
				if err != nil {
					return esc
				}
				return string(rune(value))
			})
		}
		for _, refused := range supportPDFActiveContent {
			if name == refused {
				return true
			}
		}
	}
	return false
}

func supportAttachmentName(original, extension string) string {
	base := strings.TrimSuffix(path.Base(strings.ReplaceAll(original, "\\", "/")), path.Ext(original))
	base = strings.Trim(disallowedSegmentChars.ReplaceAllString(strings.TrimSpace(base), "_"), "._-")
	if base == "" || base == "." {
		base = "attachment"
	}
	return truncateRunes(base, supportAttachmentFileName) + extension
}

// supportUploadAttachment stores an unattached upload for uploaderID.
func (s *Server) supportUploadAttachment(ctx context.Context, db *sql.DB, uploaderKind, uploaderID, filename string, content []byte, now time.Time) (map[string]any, error) {
	var recent, pending int
	if err := db.QueryRowContext(ctx, `SELECT
		  COUNT(*) FILTER (WHERE created_at > $2),
		  COUNT(*) FILTER (WHERE message_id IS NULL AND deleted_at IS NULL)
		FROM support.ticket_attachments WHERE uploader_id=$1::uuid`, uploaderID, now.Add(-time.Hour)).Scan(&recent, &pending); err != nil {
		return nil, err
	}
	if recent >= supportUploadsPerHour || pending >= supportMaxPendingUploads {
		e := newSupportError(http.StatusTooManyRequests, "SUPPORT_RATE_LIMITED", "You've uploaded a lot of files recently. Please wait a little.")
		e.retryAfter = 10 * time.Minute
		return nil, e
	}
	upload, err := sanitizeSupportUpload(content)
	if err != nil {
		return nil, err
	}
	id := uuid.NewString()
	key, err := mediastore.Key(mediastore.KindSupportAttachment, uploaderID, id+upload.Extension)
	if err != nil {
		return nil, err
	}
	stored, err := s.storeMedia(ctx, path.Dir(key), path.Base(key), upload.ContentType, upload.Content)
	if err != nil {
		return nil, err
	}
	digest := sha256.Sum256(upload.Content)
	name := supportAttachmentName(filename, upload.Extension)
	var width, height sql.NullInt64
	if upload.Width > 0 {
		width, height = sql.NullInt64{Int64: int64(upload.Width), Valid: true}, sql.NullInt64{Int64: int64(upload.Height), Valid: true}
	}
	if _, err = db.ExecContext(ctx, `
		INSERT INTO support.ticket_attachments (id, uploader_kind, uploader_id, filename, content_type, size_bytes, sha256,
		  width_px, height_px, storage_path, expires_at)
		VALUES ($1, $2, $3::uuid, $4, $5, $6, $7, $8, $9, $10, $11)`,
		id, uploaderKind, uploaderID, name, upload.ContentType, len(upload.Content), hex.EncodeToString(digest[:]),
		width, height, stored, now.Add(supportPendingUploadTTL)); err != nil {
		_ = s.deleteStoredMediaFromStore(stored)
		return nil, err
	}
	return map[string]any{"id": id, "filename": name, "content_type": upload.ContentType, "size_bytes": len(upload.Content)}, nil
}

func readSupportUpload(w http.ResponseWriter, r *http.Request) (string, []byte, error) {
	r.Body = http.MaxBytesReader(w, r.Body, supportUploadMaxBytes+1<<20)
	if err := r.ParseMultipartForm(1 << 20); err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			return "", nil, newMediaUploadError(http.StatusRequestEntityTooLarge, "Files can be up to 10 MB.")
		}
		return "", nil, newMediaUploadError(http.StatusBadRequest, "Send the file as multipart/form-data in a field named file.")
	}
	defer func() {
		if r.MultipartForm != nil {
			_ = r.MultipartForm.RemoveAll()
		}
	}()
	file, header, err := r.FormFile("file")
	if err != nil {
		return "", nil, newMediaUploadError(http.StatusBadRequest, "Send the file in a field named file.")
	}
	defer func(f multipart.File) { _ = f.Close() }(file)
	content, err := io.ReadAll(io.LimitReader(file, supportUploadMaxBytes+1))
	if err != nil {
		return "", nil, newMediaUploadError(http.StatusBadRequest, "The file could not be read.")
	}
	if len(content) > supportUploadMaxBytes {
		return "", nil, newMediaUploadError(http.StatusRequestEntityTooLarge, "Files can be up to 10 MB.")
	}
	return header.Filename, content, nil
}

func (s *Server) supportUploadHandler(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	filename, content, err := readSupportUpload(w, r)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	attachment, err := s.supportUploadAttachment(r.Context(), db, "member", memberID, filename, content, time.Now().UTC())
	if err != nil {
		writeSupportError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"success": true, "attachment": attachment})
}

// serveSupportAttachment streams one stored attachment.
func (s *Server) serveSupportAttachment(w http.ResponseWriter, r *http.Request, storagePath, contentType, filename string) {
	store, err := s.mediaStore()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media storage is unavailable"))
		return
	}
	object, err := store.Open(r.Context(), storagePath)
	if err != nil {
		writeError(w, http.StatusNotFound, errors.New("attachment not found"))
		return
	}
	defer object.Body.Close()
	disposition := "inline"
	if contentType == "application/pdf" {
		disposition = "attachment"
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Disposition", fmt.Sprintf("%s; filename=%q", disposition, filename))
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Content-Security-Policy", "default-src 'none'; sandbox")
	if object.Size > 0 {
		w.Header().Set("Content-Length", strconv.FormatInt(object.Size, 10))
	}
	w.WriteHeader(http.StatusOK)
	if _, err := io.Copy(w, object.Body); err != nil && s.log != nil {
		s.log.Warn("stream support attachment failed", zap.Error(err))
	}
}

func (s *Server) supportAttachmentHandler(w http.ResponseWriter, r *http.Request) {
	memberID, db, ok := s.supportMember(w, r)
	if !ok {
		return
	}
	ticketID, attachmentID := chi.URLParam(r, "ticketID"), chi.URLParam(r, "attachmentID")
	for _, id := range []string{ticketID, attachmentID} {
		if _, err := uuid.Parse(id); err != nil {
			writeSupportError(w, errSupportNotFound)
			return
		}
	}
	// Only attachments on public messages of the member's own ticket.
	var storagePath, contentType, filename string
	err := db.QueryRowContext(r.Context(), `SELECT a.storage_path, a.content_type, a.filename
		FROM support.ticket_attachments a
		JOIN support.tickets t ON t.id=a.ticket_id
		JOIN support.ticket_messages m ON m.id=a.message_id
		WHERE a.id=$1 AND a.ticket_id=$2 AND t.requester_member_id=$3::uuid
		  AND m.visibility='public' AND a.deleted_at IS NULL`, attachmentID, ticketID, memberID).Scan(&storagePath, &contentType, &filename)
	if err != nil {
		writeSupportError(w, err)
		return
	}
	s.serveSupportAttachment(w, r, storagePath, contentType, filename)
}

func (s *Server) adminSupportAttachmentHandler(w http.ResponseWriter, r *http.Request) {
	if _, ok := s.supportOperator(w, r); !ok {
		return
	}
	db, err := s.supportDB()
	if err != nil {
		writeSupportError(w, err)
		return
	}
	attachmentID := chi.URLParam(r, "attachmentID")
	if _, err := uuid.Parse(attachmentID); err != nil {
		writeSupportError(w, errSupportNotFound)
		return
	}
	var storagePath, contentType, filename string
	if err := db.QueryRowContext(r.Context(), `SELECT storage_path, content_type, filename FROM support.ticket_attachments
		WHERE id=$1 AND ticket_id IS NOT NULL AND deleted_at IS NULL`, attachmentID).Scan(&storagePath, &contentType, &filename); err != nil {
		writeSupportError(w, err)
		return
	}
	s.serveSupportAttachment(w, r, storagePath, contentType, filename)
}

// releaseSupportAttachments deletes the bytes of attachments marked deleted
// (erasure, retention) and of uploads never attached to a message, then the
// rows. A failed delete leaves the row for the next run.
func (s *Server) releaseSupportAttachments(ctx context.Context, db *sql.DB, now time.Time, limit int) (int, error) {
	if _, err := db.ExecContext(ctx, `UPDATE support.ticket_attachments SET deleted_at=$1
		WHERE message_id IS NULL AND deleted_at IS NULL AND expires_at < $1`, now); err != nil {
		return 0, err
	}
	rows, err := db.QueryContext(ctx, `SELECT id::text, storage_path FROM support.ticket_attachments
		WHERE deleted_at IS NOT NULL ORDER BY deleted_at LIMIT $1`, limit)
	if err != nil {
		return 0, err
	}
	type pending struct{ id, path string }
	var items []pending
	for rows.Next() {
		var p pending
		if err := rows.Scan(&p.id, &p.path); err != nil {
			rows.Close()
			return 0, err
		}
		items = append(items, p)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, err
	}
	released := 0
	for _, item := range items {
		if err := s.deleteStoredMediaFromStore(item.path); err != nil && !errors.Is(err, mediastore.ErrNotFound) {
			if s.log != nil {
				s.log.Warn("release support attachment failed", zap.String("attachment_id", item.id), zap.Error(err))
			}
			continue
		}
		if _, err := db.ExecContext(ctx, `DELETE FROM support.ticket_attachments WHERE id=$1`, item.id); err != nil {
			return released, err
		}
		released++
	}
	return released, nil
}
