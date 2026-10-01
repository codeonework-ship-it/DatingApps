package mediastore

import (
	"context"
	"io"
	"time"
)

// PutOptions describe an object being stored.
type PutOptions struct {
	ContentType string
}

// Object is an opened stored object. Callers must close Body.
type Object struct {
	Body        io.ReadCloser
	Size        int64
	ContentType string
	ModTime     time.Time
	// SHA256 is the hex digest when the backend knows it (S3 metadata).
	SHA256 string
}

// ObjectInfo is returned by Stat and Walk.
type ObjectInfo struct {
	Key     string
	Size    int64
	ModTime time.Time
	// SHA256 is the hex digest when cheaply known (S3 checksum/metadata).
	SHA256 string
}

// Store is the storage abstraction used by every media kind.
type Store interface {
	// Backend returns "local_fs" or "aws_s3".
	Backend() string
	// Put stores body under key atomically (readers never see partial data).
	Put(ctx context.Context, key string, body []byte, opts PutOptions) error
	// Open returns the object or ErrNotFound.
	Open(ctx context.Context, key string) (Object, error)
	// Stat returns object metadata or ErrNotFound.
	Stat(ctx context.Context, key string) (ObjectInfo, error)
	// Exists reports whether key is stored.
	Exists(ctx context.Context, key string) (bool, error)
	// Delete removes key; deleting a missing object is not an error.
	Delete(ctx context.Context, key string) error
	// Presign returns a time-limited GET URL, or ErrPresignUnsupported.
	Presign(ctx context.Context, key string, ttl time.Duration) (string, error)
	// Walk visits every stored object (local backend; S3 returns an error).
	Walk(ctx context.Context, fn func(ObjectInfo) error) error
}

// LocalPather is implemented by the local backend so HTTP handlers can use
// http.ServeContent / nginx X-Accel-Redirect for files on disk.
type LocalPather interface {
	// LocalPath resolves key to an existing file and returns its absolute path
	// and the path relative to the media root (slash separated).
	LocalPath(key string) (absolute string, relative string, err error)
}
