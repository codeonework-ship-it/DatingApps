package mobile

import (
	"encoding/binary"
	"net/http"
	"strings"
	"testing"
)

func TestValidateProfilePhotoCanonicalizesSupportedFormats(t *testing.T) {
	tests := []struct {
		name      string
		content   []byte
		mimeType  string
		extension string
	}{
		{name: "png", content: testPNG(640, 480), mimeType: "image/png", extension: ".png"},
		{name: "jpeg", content: testJPEG(640, 480), mimeType: "image/jpeg", extension: ".jpg"},
		{name: "webp", content: testWebP(640, 480), mimeType: "image/webp", extension: ".webp"},
		{name: "heic", content: testHEIC(640, 480), mimeType: "image/heic", extension: ".heic"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			upload, err := validateProfilePhoto("../../portrait.exe", tt.content)
			if err != nil {
				t.Fatalf("validate photo: %v", err)
			}
			if upload.MimeType != tt.mimeType || upload.Extension != tt.extension {
				t.Fatalf("canonical format = %s %s", upload.MimeType, upload.Extension)
			}
			if upload.WidthPx != 640 || upload.HeightPx != 480 {
				t.Fatalf("dimensions = %dx%d", upload.WidthPx, upload.HeightPx)
			}
			if strings.Contains(upload.OriginalFilename, "/") {
				t.Fatalf("unsafe original filename %q", upload.OriginalFilename)
			}
			if len(upload.ContentSHA256) != 64 {
				t.Fatalf("sha256 length = %d", len(upload.ContentSHA256))
			}
		})
	}
}

func TestValidateProfilePhotoRejectsInvalidMedia(t *testing.T) {
	tests := []struct {
		name   string
		bytes  []byte
		status int
	}{
		{name: "empty", bytes: nil, status: http.StatusBadRequest},
		{name: "unsupported", bytes: []byte("not an image"), status: http.StatusUnsupportedMediaType},
		{name: "too small", bytes: testPNG(299, 600), status: http.StatusUnprocessableEntity},
		{name: "too large dimensions", bytes: testPNG(4097, 600), status: http.StatusUnprocessableEntity},
		{name: "too many bytes", bytes: make([]byte, maxProfilePhotoBytes+1), status: http.StatusRequestEntityTooLarge},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := validateProfilePhoto("photo.jpg", tt.bytes)
			if err == nil {
				t.Fatal("expected validation error")
			}
			if got := mediaUploadHTTPStatus(err); got != tt.status {
				t.Fatalf("status = %d, want %d (%v)", got, tt.status, err)
			}
		})
	}
}

func testPNG(width, height int) []byte {
	content := make([]byte, 24)
	copy(content, []byte("\x89PNG\r\n\x1a\n"))
	binary.BigEndian.PutUint32(content[16:20], uint32(width))
	binary.BigEndian.PutUint32(content[20:24], uint32(height))
	return content
}

func testJPEG(width, height int) []byte {
	content := make([]byte, 11)
	copy(content, []byte{0xff, 0xd8, 0xff, 0xc0})
	binary.BigEndian.PutUint16(content[4:6], 7)
	content[6] = 8
	binary.BigEndian.PutUint16(content[7:9], uint16(height))
	binary.BigEndian.PutUint16(content[9:11], uint16(width))
	return content
}

func testWebP(width, height int) []byte {
	content := make([]byte, 30)
	copy(content[0:4], "RIFF")
	copy(content[8:12], "WEBP")
	copy(content[12:16], "VP8X")
	w := width - 1
	h := height - 1
	content[24], content[25], content[26] = byte(w), byte(w>>8), byte(w>>16)
	content[27], content[28], content[29] = byte(h), byte(h>>8), byte(h>>16)
	return content
}

func testHEIC(width, height int) []byte {
	content := make([]byte, 44)
	binary.BigEndian.PutUint32(content[0:4], 24)
	copy(content[4:8], "ftyp")
	copy(content[8:12], "heic")
	copy(content[16:20], "heic")
	binary.BigEndian.PutUint32(content[24:28], 20)
	copy(content[28:32], "ispe")
	binary.BigEndian.PutUint32(content[36:40], uint32(width))
	binary.BigEndian.PutUint32(content[40:44], uint32(height))
	return content
}
