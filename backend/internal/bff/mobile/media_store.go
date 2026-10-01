package mobile

// Media storage glue: every media kind (profile photos, chapter photos, Photo
// Theme entries, voice recordings, identity evidence, group covers) stores,
// reads and deletes bytes through one mediastore.Store, chosen by
// FILE_STORAGE_BACKEND (local_fs on the VPS, or aws_s3). Database rows keep
// logical storage keys, so existing rows work on either backend.

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/mediastore"
)

// mediaStorageConfigFor returns the storage section of cfg. A Config built
// without config.Load (tests, tools) falls back to the historical flat
// directory MEDIA_UPLOADS_DIR or the flat AWS_S3_* fields.
func mediaStorageConfigFor(cfg config.Config) config.MediaStorageConfig {
	if cfg.MediaStorage.Backend != "" {
		return cfg.MediaStorage
	}
	storage := config.MediaStorageConfig{
		Backend: config.StorageBackendLocalFS,
		Local: config.LocalStorageConfig{
			Layout:           config.LocalLayoutFlat,
			LegacyUploadsDir: strings.TrimSpace(cfg.MediaUploadsDir),
			MinFreeBytes:     500 << 20,
		},
	}
	if strings.EqualFold(strings.TrimSpace(cfg.FileStorageBackend), config.StorageBackendAWSS3) || cfg.UseAWSS3Storage {
		storage.Backend = config.StorageBackendAWSS3
		auth := config.S3AuthConfig{Mode: config.S3AuthDefaultChain, SessionName: "connect-media"}
		if cfg.AWSS3AccessKeyID != "" {
			auth = config.S3AuthConfig{Mode: config.S3AuthStatic, AccessKeyID: cfg.AWSS3AccessKeyID, SecretAccessKey: cfg.AWSS3SecretAccessKey}
		}
		storage.S3 = config.S3StorageConfig{
			Region:         cfg.AWSS3Region,
			Bucket:         cfg.AWSS3Bucket,
			Endpoint:       strings.TrimRight(strings.TrimSpace(cfg.AWSS3Endpoint), "/"),
			ForcePathStyle: cfg.AWSS3ForcePathStyle,
			Prefixes:       config.DefaultS3KindPrefixes(),
			LegacyPrefix:   strings.Trim(cfg.AWSS3ProfilePhotosPrefix, "/"),
			SendChecksums:  true,
			PresignTTL:     5 * time.Minute,
			ServeMode:      config.S3ServeProxy,
			PublicBaseURL:  strings.TrimRight(strings.TrimSpace(cfg.AWSS3PublicBaseURL), "/"),
			Auth:           auth,
		}
	}
	return storage
}

// initMediaStore opens the configured store at startup and fails fast with a
// clear message when directories are not writable or credentials are broken.
func (s *Server) initMediaStore(ctx context.Context) error {
	storageCfg := mediaStorageConfigFor(s.cfg)
	if s.cfg.MediaStorage.Backend == "" {
		// Not produced by config.Load: open lazily without touching disk.
		return nil
	}
	store, warnings, err := mediastore.Open(ctx, storageCfg)
	for _, warning := range warnings {
		s.log.Warn("media storage", zap.String("warning", warning))
	}
	if err != nil {
		return err
	}
	s.media = store
	s.log.Info("media storage ready", zap.String("storage", storageCfg.Summary()))
	return nil
}

// mediaStore returns the configured store.
func (s *Server) mediaStore() (mediastore.Store, error) {
	s.mediaOnce.Do(func() {
		if s.media != nil {
			return
		}
		storageCfg := mediaStorageConfigFor(s.cfg)
		switch storageCfg.Backend {
		case config.StorageBackendAWSS3:
			s.media, s.mediaErr = mediastore.NewS3(context.Background(), storageCfg.S3)
		default:
			s.media, s.mediaErr = mediastore.NewLocal(storageCfg.Local)
		}
	})
	if s.media == nil {
		if s.mediaErr == nil {
			s.mediaErr = errors.New("media storage is not configured")
		}
		return nil, s.mediaErr
	}
	return s.media, nil
}

func (s *Server) usesAWSS3Storage() bool {
	return mediaStorageConfigFor(s.cfg).Backend == config.StorageBackendAWSS3
}

// storeMedia writes content under namespace/filename and returns the logical
// storage key to persist in the database.
func (s *Server) storeMedia(ctx context.Context, namespace, filename, contentType string, content []byte) (string, error) {
	key, err := mediastore.CleanKey(strings.Trim(namespace, "/") + "/" + filename)
	if err != nil {
		return "", errors.New("invalid upload target")
	}
	store, err := s.mediaStore()
	if err != nil {
		return "", newMediaUploadError(http.StatusServiceUnavailable, "Media storage is temporarily unavailable.")
	}
	if contentType == "" {
		contentType = http.DetectContentType(content)
	}
	if err := store.Put(ctx, key, content, mediastore.PutOptions{ContentType: contentType}); err != nil {
		if errors.Is(err, mediastore.ErrInsufficientSpace) {
			return "", newMediaUploadError(http.StatusInsufficientStorage, "Photo storage is temporarily full.")
		}
		// Log the backend detail (bucket, errno); clients get a generic message.
		s.log.Error("media storage write failed", zap.Error(err))
		return "", newMediaUploadError(http.StatusServiceUnavailable, "Media storage is temporarily unavailable. Please retry.")
	}
	return key, nil
}

// persistUploadedPhotoToLocalFS is kept for callers written before the store
// abstraction; it writes through the configured backend (local or S3).
//
// Deprecated: use storeMedia.
func (s *Server) persistUploadedPhotoToLocalFS(r *http.Request, namespace, filename string, content []byte) (string, string, error) {
	key, err := s.storeMedia(r.Context(), namespace, filename, "", content)
	if err != nil {
		return "", "", err
	}
	return s.mediaURLForStoragePath(r, key), key, nil
}

// persistUploadedPhotoToS3 is kept for callers written before the store
// abstraction; it writes through the configured backend (local or S3).
//
// Deprecated: use storeMedia.
func (s *Server) persistUploadedPhotoToS3(ctx context.Context, namespace, filename, contentType string, content []byte) (string, string, error) {
	key, err := s.storeMedia(ctx, namespace, filename, contentType, content)
	return "", key, err
}

// legacyS3Prefix is the prefix earlier releases stored inside S3 keys.
func (s *Server) legacyS3Prefix() string {
	storageCfg := mediaStorageConfigFor(s.cfg)
	if storageCfg.Backend != config.StorageBackendAWSS3 {
		return ""
	}
	return strings.Trim(storageCfg.S3.LegacyPrefix, "/")
}

// mediaURLForStoragePath is the authorized API URL of a profile photo.
func (s *Server) mediaURLForStoragePath(r *http.Request, storagePath string) string {
	relativePath := strings.Trim(strings.ReplaceAll(storagePath, "\\", "/"), "/")
	if prefix := s.legacyS3Prefix(); prefix != "" {
		relativePath = strings.TrimPrefix(relativePath, prefix+"/")
	}
	return s.resolveMediaPublicBaseURL(r) + s.cfg.APIPrefix + "/media/" + escapeURLPath(relativePath)
}

// profileMediaStorageKeys lists the database keys a /media/<path> URL may
// refer to: the logical key, then the pre-abstraction S3 key.
func (s *Server) profileMediaStorageKeys(relativePath string) []string {
	keys := []string{relativePath}
	if prefix := s.legacyS3Prefix(); prefix != "" {
		keys = append(keys, prefix+"/"+relativePath)
	}
	return keys
}

// serveStoredMedia streams an authorized profile photo.
func (s *Server) serveStoredMedia(w http.ResponseWriter, r *http.Request, record mediaAccessRecord) {
	store, err := s.mediaStore()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media storage is unavailable"))
		return
	}
	spec, _, err := mediastore.Classify(record.StoragePath)
	if err != nil {
		writeError(w, http.StatusNotFound, errors.New("media not found"))
		return
	}
	w.Header().Set("X-Content-Type-Options", "nosniff")
	switch backend := store.(type) {
	case *mediastore.LocalStore:
		absolute, relative, err := backend.LocalPath(record.StoragePath)
		if err != nil {
			writeError(w, http.StatusNotFound, errors.New("media not found"))
			return
		}
		w.Header().Set("Cache-Control", mediastore.ResponseCacheControl(spec.Visibility))
		if record.MimeType != "" {
			w.Header().Set("Content-Type", record.MimeType)
		}
		// nginx serves public files from an internal location after this
		// authorization; private/quarantine bytes never leave through nginx.
		if prefix := mediaStorageConfigFor(s.cfg).Local.AccelRedirectPrefix; prefix != "" &&
			spec.Visibility == mediastore.VisibilityPublic && strings.HasPrefix(relative, "public/") {
			w.Header().Set("X-Accel-Redirect", prefix+relative)
			w.WriteHeader(http.StatusOK)
			return
		}
		file, info, err := backend.OpenFile(r.Context(), record.StoragePath)
		if err != nil {
			writeError(w, http.StatusNotFound, errors.New("media not found"))
			return
		}
		defer file.Close()
		http.ServeContent(w, r, absolute, info.ModTime(), file)
	case *mediastore.S3Store:
		if backend.ServeMode() == config.S3ServeRedirect {
			target, ok := "", false
			if spec.Visibility == mediastore.VisibilityPublic {
				target, ok = backend.PublicURL(record.StoragePath)
			}
			if !ok {
				target, err = backend.Presign(r.Context(), record.StoragePath, backend.PresignTTL())
				if err != nil {
					s.log.Warn("presign media failed", zap.Error(err), zap.String("photo_id", record.PhotoID))
					writeError(w, http.StatusServiceUnavailable, errors.New("media storage is unavailable"))
					return
				}
			}
			w.Header().Set("Cache-Control", "private, no-store")
			http.Redirect(w, r, target, http.StatusFound)
			return
		}
		s.streamStoredObject(w, r, record.StoragePath, record.MimeType, mediastore.ResponseCacheControl(spec.Visibility))
	default:
		s.streamStoredObject(w, r, record.StoragePath, record.MimeType, mediastore.ResponseCacheControl(spec.Visibility))
	}
}

func (s *Server) streamStoredObject(w http.ResponseWriter, r *http.Request, key, mimeType, cacheControl string) {
	store, err := s.mediaStore()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media storage is unavailable"))
		return
	}
	object, err := store.Open(r.Context(), key)
	if err != nil {
		writeError(w, http.StatusNotFound, errors.New("media not found"))
		return
	}
	defer object.Body.Close()
	contentType := strings.TrimSpace(object.ContentType)
	if contentType == "" || contentType == "application/octet-stream" {
		contentType = mimeType
	}
	if contentType != "" {
		w.Header().Set("Content-Type", contentType)
	}
	if object.Size > 0 {
		w.Header().Set("Content-Length", strconv.FormatInt(object.Size, 10))
	}
	w.Header().Set("Cache-Control", cacheControl)
	if _, err := io.Copy(w, object.Body); err != nil {
		s.log.Warn("stream stored media failed", zap.Error(err))
	}
}

// copyPrivateMediaFromStore copies a stored object into destination.
func (s *Server) copyPrivateMediaFromStore(ctx context.Context, destination io.Writer, storagePath string) error {
	cleaned := strings.Trim(strings.ReplaceAll(strings.TrimSpace(storagePath), "\\", "/"), "/")
	if cleaned == "" {
		return errors.New("private media is unavailable")
	}
	store, err := s.mediaStore()
	if err != nil {
		return errors.New("private storage is unavailable")
	}
	object, err := store.Open(ctx, cleaned)
	if err != nil {
		return err
	}
	defer object.Body.Close()
	_, err = io.Copy(destination, object.Body)
	return err
}

// deleteStoredMediaFromStore removes an object; missing objects are fine.
func (s *Server) deleteStoredMediaFromStore(storagePath string) error {
	trimmed := strings.Trim(strings.ReplaceAll(strings.TrimSpace(storagePath), "\\", "/"), "/")
	if trimmed == "" {
		return nil
	}
	store, err := s.mediaStore()
	if err != nil {
		return err
	}
	if _, err := mediastore.CleanKey(trimmed); err != nil {
		return errors.New("invalid media cleanup path")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	return store.Delete(ctx, trimmed)
}
