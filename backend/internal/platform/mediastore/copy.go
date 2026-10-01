package mediastore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"strings"
)

// CopyOptions control Copy.
type CopyOptions struct {
	// Apply performs writes; without it Copy is a dry run.
	Apply bool
	// Verify is "checksum" (compare the destination's SHA-256 from metadata or
	// S3 checksum, downloading only when unknown) or "download" (always read
	// the destination back and hash it).
	Verify string
	// Overwrite replaces destination objects whose bytes differ.
	Overwrite bool
	// Kinds limits the copy to these kinds (empty = all).
	Kinds []Kind
	// Logf receives one line per object that is not identical already.
	Logf func(format string, args ...any)
}

// CopyReport summarizes a Copy run.
type CopyReport struct {
	Scanned   int
	Identical int
	Copied    int
	WouldCopy int
	Conflicts int
	Failed    int
	Bytes     int64
}

func (r CopyReport) String() string {
	return fmt.Sprintf("scanned=%d identical=%d copied=%d would_copy=%d conflicts=%d failed=%d bytes=%d",
		r.Scanned, r.Identical, r.Copied, r.WouldCopy, r.Conflicts, r.Failed, r.Bytes)
}

// Copy copies every object of src (a walkable store) into dst under the same
// logical key. It is idempotent: objects already present with the same
// SHA-256 are skipped, and every write is verified. Database rows need no
// change because keys are backend independent.
func Copy(ctx context.Context, src, dst Store, opts CopyOptions) (CopyReport, error) {
	report := CopyReport{}
	logf := opts.Logf
	if logf == nil {
		logf = func(string, ...any) {}
	}
	allowed := map[Kind]bool{}
	for _, kind := range opts.Kinds {
		allowed[kind] = true
	}
	err := src.Walk(ctx, func(info ObjectInfo) error {
		spec, _, err := Classify(info.Key)
		if err != nil {
			return nil
		}
		if len(allowed) > 0 && !allowed[spec.Kind] {
			return nil
		}
		report.Scanned++
		body, sourceDigest, err := readAll(ctx, src, info.Key)
		if err != nil {
			report.Failed++
			logf("FAIL   %s: read source: %v", info.Key, err)
			return nil
		}
		existing, statErr := dst.Stat(ctx, info.Key)
		switch {
		case statErr == nil:
			digest := existing.SHA256
			if digest == "" {
				_, digest, err = readAll(ctx, dst, info.Key)
				if err != nil {
					report.Failed++
					logf("FAIL   %s: read destination: %v", info.Key, err)
					return nil
				}
			}
			if digest == sourceDigest {
				report.Identical++
				return nil
			}
			if !opts.Overwrite {
				report.Conflicts++
				logf("DIFFER %s: destination has different bytes (use -overwrite to replace)", info.Key)
				return nil
			}
		case !errors.Is(statErr, ErrNotFound):
			report.Failed++
			logf("FAIL   %s: stat destination: %v", info.Key, statErr)
			return nil
		}
		if !opts.Apply {
			report.WouldCopy++
			report.Bytes += int64(len(body))
			logf("COPY   %s (%d bytes) [dry-run]", info.Key, len(body))
			return nil
		}
		if err := dst.Put(ctx, info.Key, body, PutOptions{ContentType: contentTypeFor(info.Key)}); err != nil {
			report.Failed++
			logf("FAIL   %s: write destination: %v", info.Key, err)
			return nil
		}
		if err := verify(ctx, dst, info.Key, sourceDigest, opts.Verify); err != nil {
			report.Failed++
			logf("FAIL   %s: verify: %v", info.Key, err)
			return nil
		}
		report.Copied++
		report.Bytes += int64(len(body))
		logf("COPIED %s (%d bytes, sha256 verified)", info.Key, len(body))
		return nil
	})
	return report, err
}

func verify(ctx context.Context, store Store, key, want, mode string) error {
	if mode != "download" {
		info, err := store.Stat(ctx, key)
		if err != nil {
			return err
		}
		if info.SHA256 != "" {
			if info.SHA256 != want {
				return fmt.Errorf("sha256 mismatch: have %s want %s", info.SHA256, want)
			}
			return nil
		}
	}
	_, got, err := readAll(ctx, store, key)
	if err != nil {
		return err
	}
	if got != want {
		return fmt.Errorf("sha256 mismatch after download: have %s want %s", got, want)
	}
	return nil
}

func readAll(ctx context.Context, store Store, key string) ([]byte, string, error) {
	object, err := store.Open(ctx, key)
	if err != nil {
		return nil, "", err
	}
	defer object.Body.Close()
	body, err := io.ReadAll(io.LimitReader(object.Body, 64<<20))
	if err != nil {
		return nil, "", err
	}
	digest := sha256.Sum256(body)
	return body, hex.EncodeToString(digest[:]), nil
}

func contentTypeFor(key string) string {
	switch strings.ToLower(extensionOf(key)) {
	case ".png":
		return "image/png"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".webp":
		return "image/webp"
	case ".webm":
		return "audio/webm"
	case ".ogg":
		return "audio/ogg"
	case ".m4a":
		return "audio/mp4"
	case ".wav":
		return "audio/wav"
	}
	return "application/octet-stream"
}

func extensionOf(key string) string {
	for i := len(key) - 1; i >= 0 && key[i] != '/'; i-- {
		if key[i] == '.' {
			return key[i:]
		}
	}
	return ""
}
