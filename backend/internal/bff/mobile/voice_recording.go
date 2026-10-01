package mobile

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"path"

	"github.com/google/uuid"
)

const maxVoiceRecordingBytes = 8 << 20

func (s *Server) persistVoiceRecording(r *http.Request, icebreakerID, senderUserID string) (voiceRecordingMetadata, error) {
	file, _, err := r.FormFile("audio")
	if err != nil {
		return voiceRecordingMetadata{}, newMediaUploadError(http.StatusBadRequest, "A voice recording is required.")
	}
	defer file.Close()
	content, err := io.ReadAll(io.LimitReader(file, maxVoiceRecordingBytes+1))
	if err != nil {
		return voiceRecordingMetadata{}, errors.New("unable to read voice recording")
	}
	if len(content) == 0 {
		return voiceRecordingMetadata{}, newMediaUploadError(http.StatusBadRequest, "The voice recording is empty.")
	}
	if len(content) > maxVoiceRecordingBytes {
		return voiceRecordingMetadata{}, newMediaUploadError(http.StatusRequestEntityTooLarge, "Voice recording is too large (max 8 MB).")
	}
	mimeType, extension, ok := inspectVoiceRecording(content)
	if !ok {
		return voiceRecordingMetadata{}, newMediaUploadError(http.StatusUnsupportedMediaType, "Use a WebM, Ogg, M4A, or WAV voice recording.")
	}
	namespace := path.Join("private", "voice", sanitizePathSegment(senderUserID), sanitizePathSegment(icebreakerID))
	filename := uuid.NewString() + extension
	storagePath, err := s.storeMedia(r.Context(), namespace, filename, mimeType, content)
	if err != nil {
		return voiceRecordingMetadata{}, err
	}
	digest := sha256.Sum256(content)
	return voiceRecordingMetadata{
		StoragePath: storagePath,
		MimeType:    mimeType,
		SizeBytes:   int64(len(content)),
		SHA256:      hex.EncodeToString(digest[:]),
		Content:     content,
	}, nil
}

func inspectVoiceRecording(content []byte) (string, string, bool) {
	if len(content) >= 4 && content[0] == 0x1a && content[1] == 0x45 && content[2] == 0xdf && content[3] == 0xa3 {
		return "audio/webm", ".webm", true
	}
	if len(content) >= 4 && string(content[:4]) == "OggS" {
		return "audio/ogg", ".ogg", true
	}
	if len(content) >= 12 && string(content[4:8]) == "ftyp" {
		return "audio/mp4", ".m4a", true
	}
	if len(content) >= 12 && string(content[:4]) == "RIFF" && string(content[8:12]) == "WAVE" {
		return "audio/wav", ".wav", true
	}
	return "", "", false
}
