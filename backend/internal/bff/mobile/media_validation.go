package mobile

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

const (
	maxProfilePhotos       = 5
	maxProfilePhotoBytes   = 10 << 20
	maxProfileStorageBytes = 50 << 20
	minProfilePhotoPixels  = 300
	maxProfilePhotoPixels  = 4096
)

func newProfilePhotoID() string { return uuid.NewString() }

type mediaUploadError struct {
	status  int
	message string
}

func (e *mediaUploadError) Error() string { return e.message }

func newMediaUploadError(status int, message string) error {
	return &mediaUploadError{status: status, message: message}
}

func mediaUploadHTTPStatus(err error) int {
	var uploadErr *mediaUploadError
	if errors.As(err, &uploadErr) {
		return uploadErr.status
	}
	return http.StatusBadRequest
}

type validatedPhotoUpload struct {
	ID               string
	OriginalFilename string
	MimeType         string
	Extension        string
	WidthPx          int
	HeightPx         int
	SizeBytes        int64
	ContentSHA256    string
	Content          []byte
	PhotoURL         string
	StoragePath      string
	Moderation       mediaModerationResult
	ModerationLabels []byte
	MaxConfidence    float32
}

func validateProfilePhoto(filename string, content []byte) (validatedPhotoUpload, error) {
	if len(content) == 0 {
		return validatedPhotoUpload{}, newMediaUploadError(http.StatusBadRequest, "Invalid photo file.")
	}
	if len(content) > maxProfilePhotoBytes {
		return validatedPhotoUpload{}, newMediaUploadError(http.StatusRequestEntityTooLarge, "Photo too large (max 10 MB).")
	}

	mimeType, extension, width, height, err := inspectProfileImage(content)
	if err != nil {
		return validatedPhotoUpload{}, newMediaUploadError(http.StatusUnsupportedMediaType, "Unsupported photo format.")
	}
	if width < minProfilePhotoPixels || height < minProfilePhotoPixels {
		return validatedPhotoUpload{}, newMediaUploadError(
			http.StatusUnprocessableEntity,
			fmt.Sprintf("Photo must be at least %d × %d pixels.", minProfilePhotoPixels, minProfilePhotoPixels),
		)
	}
	if width > maxProfilePhotoPixels || height > maxProfilePhotoPixels {
		return validatedPhotoUpload{}, newMediaUploadError(
			http.StatusUnprocessableEntity,
			fmt.Sprintf("Photo dimensions cannot exceed %d × %d pixels.", maxProfilePhotoPixels, maxProfilePhotoPixels),
		)
	}

	digest := sha256.Sum256(content)
	return validatedPhotoUpload{
		ID:               uuid.NewString(),
		OriginalFilename: sanitizeOriginalFilename(filename),
		MimeType:         mimeType,
		Extension:        extension,
		WidthPx:          width,
		HeightPx:         height,
		SizeBytes:        int64(len(content)),
		ContentSHA256:    hex.EncodeToString(digest[:]),
		Content:          content,
	}, nil
}

func sanitizeOriginalFilename(filename string) string {
	base := strings.TrimSpace(filepath.Base(filename))
	if base == "" || base == "." {
		return "photo"
	}
	cleaned := disallowedSegmentChars.ReplaceAllString(base, "_")
	if len(cleaned) > 255 {
		cleaned = cleaned[:255]
	}
	return cleaned
}

func inspectProfileImage(content []byte) (string, string, int, int, error) {
	switch {
	case isJPEG(content):
		width, height, err := jpegDimensions(content)
		return "image/jpeg", ".jpg", width, height, err
	case isPNG(content):
		if len(content) < 24 {
			return "", "", 0, 0, errors.New("truncated png")
		}
		return "image/png", ".png", int(binary.BigEndian.Uint32(content[16:20])), int(binary.BigEndian.Uint32(content[20:24])), nil
	case isWebP(content):
		width, height, err := webPDimensions(content)
		return "image/webp", ".webp", width, height, err
	case isHEIC(content):
		width, height, err := heicDimensions(content)
		return "image/heic", ".heic", width, height, err
	default:
		return "", "", 0, 0, errors.New("unsupported image signature")
	}
}

func isJPEG(content []byte) bool {
	return len(content) >= 3 && content[0] == 0xff && content[1] == 0xd8 && content[2] == 0xff
}

func isPNG(content []byte) bool {
	return len(content) >= 8 && string(content[:8]) == "\x89PNG\r\n\x1a\n"
}

func isWebP(content []byte) bool {
	return len(content) >= 16 && string(content[:4]) == "RIFF" && string(content[8:12]) == "WEBP"
}

func isHEIC(content []byte) bool {
	if len(content) < 16 || string(content[4:8]) != "ftyp" {
		return false
	}
	brands := []string{"heic", "heix", "hevc", "hevx", "heim", "heis", "mif1", "msf1"}
	limit := len(content)
	if limit > 64 {
		limit = 64
	}
	header := string(content[8:limit])
	for _, brand := range brands {
		if strings.Contains(header, brand) {
			return true
		}
	}
	return false
}

func jpegDimensions(content []byte) (int, int, error) {
	for offset := 2; offset+9 <= len(content); {
		if content[offset] != 0xff {
			offset++
			continue
		}
		for offset < len(content) && content[offset] == 0xff {
			offset++
		}
		if offset >= len(content) {
			break
		}
		marker := content[offset]
		offset++
		if marker == 0xd8 || marker == 0xd9 || (marker >= 0xd0 && marker <= 0xd7) {
			continue
		}
		if offset+2 > len(content) {
			break
		}
		length := int(binary.BigEndian.Uint16(content[offset : offset+2]))
		if length < 2 || offset+length > len(content) {
			break
		}
		if marker >= 0xc0 && marker <= 0xcf && marker != 0xc4 && marker != 0xc8 && marker != 0xcc {
			if length < 7 {
				break
			}
			height := int(binary.BigEndian.Uint16(content[offset+3 : offset+5]))
			width := int(binary.BigEndian.Uint16(content[offset+5 : offset+7]))
			return width, height, nil
		}
		offset += length
	}
	return 0, 0, errors.New("jpeg dimensions not found")
}

func webPDimensions(content []byte) (int, int, error) {
	if len(content) < 30 {
		return 0, 0, errors.New("truncated webp")
	}
	switch string(content[12:16]) {
	case "VP8X":
		width := 1 + int(content[24]) + (int(content[25]) << 8) + (int(content[26]) << 16)
		height := 1 + int(content[27]) + (int(content[28]) << 8) + (int(content[29]) << 16)
		return width, height, nil
	case "VP8 ":
		if len(content) < 30 || content[23] != 0x9d || content[24] != 0x01 || content[25] != 0x2a {
			return 0, 0, errors.New("invalid vp8 frame")
		}
		return int(binary.LittleEndian.Uint16(content[26:28]) & 0x3fff), int(binary.LittleEndian.Uint16(content[28:30]) & 0x3fff), nil
	case "VP8L":
		if content[20] != 0x2f {
			return 0, 0, errors.New("invalid vp8l frame")
		}
		bits := binary.LittleEndian.Uint32(content[21:25])
		return int(bits&0x3fff) + 1, int((bits>>14)&0x3fff) + 1, nil
	default:
		return 0, 0, errors.New("unsupported webp encoding")
	}
}

func heicDimensions(content []byte) (int, int, error) {
	for offset := 4; offset+16 <= len(content); offset++ {
		if string(content[offset:offset+4]) != "ispe" {
			continue
		}
		boxStart := offset - 4
		boxSize := int(binary.BigEndian.Uint32(content[boxStart:offset]))
		if boxSize < 20 || offset+16 > len(content) {
			continue
		}
		width := int(binary.BigEndian.Uint32(content[offset+8 : offset+12]))
		height := int(binary.BigEndian.Uint32(content[offset+12 : offset+16]))
		if width > 0 && height > 0 {
			return width, height, nil
		}
	}
	return 0, 0, errors.New("heic dimensions not found")
}
