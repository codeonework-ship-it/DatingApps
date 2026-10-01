package mediastore

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

// Open builds the configured store and runs its startup checks: the local
// backend creates/validates its directories and proves they are writable; the
// S3 backend resolves credentials. Warnings are safe to log.
func Open(ctx context.Context, cfg config.MediaStorageConfig) (Store, []string, error) {
	switch cfg.Backend {
	case config.StorageBackendAWSS3:
		store, err := NewS3(ctx, cfg.S3)
		if err != nil {
			return nil, nil, err
		}
		verifyCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
		defer cancel()
		if err := store.VerifyCredentials(verifyCtx); err != nil {
			return nil, nil, err
		}
		return store, nil, nil
	case config.StorageBackendLocalFS, "":
		store, err := NewLocal(cfg.Local)
		if err != nil {
			return nil, nil, err
		}
		warnings, err := store.SelfCheck()
		if err != nil {
			return nil, warnings, err
		}
		return store, warnings, nil
	default:
		return nil, nil, fmt.Errorf("mediastore: unsupported backend %q", cfg.Backend)
	}
}

// Probe writes, reads back and deletes a small object under the quarantine
// kind (covered by the least-privilege IAM policy) to prove end-to-end access.
func Probe(ctx context.Context, store Store) error {
	suffix := make([]byte, 8)
	_, _ = rand.Read(suffix)
	key := "quarantine/_healthcheck/probe-" + hex.EncodeToString(suffix) + ".txt"
	payload := []byte("connect media storage probe " + time.Now().UTC().Format(time.RFC3339))
	if err := store.Put(ctx, key, payload, PutOptions{ContentType: "text/plain"}); err != nil {
		return fmt.Errorf("probe put: %w", err)
	}
	defer func() { _ = store.Delete(context.Background(), key) }()
	object, err := store.Open(ctx, key)
	if err != nil {
		return fmt.Errorf("probe get: %w", err)
	}
	defer object.Body.Close()
	read, err := io.ReadAll(object.Body)
	if err != nil {
		return fmt.Errorf("probe read: %w", err)
	}
	if !bytes.Equal(read, payload) {
		return errors.New("probe read back different bytes")
	}
	if err := store.Delete(ctx, key); err != nil {
		return fmt.Errorf("probe delete: %w", err)
	}
	if exists, err := store.Exists(ctx, key); err != nil || exists {
		return fmt.Errorf("probe object still present after delete (err=%v)", err)
	}
	return nil
}
