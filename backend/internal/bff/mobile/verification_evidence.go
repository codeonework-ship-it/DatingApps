package mobile

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"path"
	"strings"
)

const maxVerificationRequestBytes = 22 << 20

func (s *Server) persistVerificationEvidence(r *http.Request, userID string) (map[string]any, []string, verificationEvidenceBundle, error) {
	if err := r.ParseMultipartForm(maxVerificationRequestBytes); err != nil {
		return nil, nil, verificationEvidenceBundle{}, newMediaUploadError(http.StatusRequestEntityTooLarge, "Identity evidence exceeds the 20 MB upload limit.")
	}
	stored := make([]string, 0, 2)
	result := map[string]any{"evidence_version": 1}
	bundle := verificationEvidenceBundle{}
	for _, field := range []string{"id_document", "selfie"} {
		file, header, err := r.FormFile(field)
		if err != nil {
			for _, storagePath := range stored {
				_ = s.deleteStoredMedia(storagePath)
			}
			return nil, nil, verificationEvidenceBundle{}, newMediaUploadError(http.StatusBadRequest, strings.ReplaceAll(field, "_", " ")+" image is required.")
		}
		content, readErr := io.ReadAll(io.LimitReader(file, maxProfilePhotoBytes+1))
		_ = file.Close()
		if readErr != nil {
			return nil, stored, verificationEvidenceBundle{}, fmt.Errorf("read %s: %w", field, readErr)
		}
		upload, validateErr := validateProfilePhoto(header.Filename, content)
		if validateErr != nil {
			for _, storagePath := range stored {
				_ = s.deleteStoredMedia(storagePath)
			}
			return nil, nil, verificationEvidenceBundle{}, validateErr
		}
		namespace := path.Join("private", "verification", sanitizePathSegment(userID), field)
		filename := upload.ID + upload.Extension
		storagePath, err := s.storeMedia(r.Context(), namespace, filename, upload.MimeType, content)
		if err != nil {
			for _, existing := range stored {
				_ = s.deleteStoredMedia(existing)
			}
			return nil, nil, verificationEvidenceBundle{}, err
		}
		stored = append(stored, storagePath)
		result[field] = map[string]any{
			"storage_path":      storagePath,
			"original_filename": upload.OriginalFilename,
			"mime_type":         upload.MimeType,
			"size_bytes":        upload.SizeBytes,
			"content_sha256":    upload.ContentSHA256,
		}
		providerFile := providerEvidenceFile{Filename: upload.OriginalFilename, MimeType: upload.MimeType, Content: content}
		if field == "id_document" {
			bundle.IDDocument = providerFile
		} else {
			bundle.Selfie = providerFile
		}
	}
	if len(stored) != 2 {
		return nil, stored, verificationEvidenceBundle{}, errors.New("both identity document and selfie are required")
	}
	return result, stored, bundle, nil
}
