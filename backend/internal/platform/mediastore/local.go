package mediastore

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"mime"
	"os"
	"path"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

const (
	privateDirMode  os.FileMode = 0o700
	privateFileMode os.FileMode = 0o600
	tempPattern                 = ".upload-*"
)

// LocalStore keeps media on the local filesystem.
//
// Kinds layout (production, MEDIA_STORAGE_ROOT=/var/lib/connect/media):
//
//	<root>/public/profile_photos/<user>/<photo>.png        key approved/<user>/<photo>.png
//	<root>/public/legacy_profile_photos/<...>              keys from before namespacing
//	<root>/public/group_covers/<...>                       key group_covers/<...> (reserved)
//	<root>/quarantine/profile_photos/<user>/<photo>.png    key quarantine/<user>/<photo>.png
//	<root>/private/chapter_photos/<user>/<post>/<f>.jpg    key private/blog/<user>/<post>/<f>.jpg
//	<root>/private/theme_photos/<user>/<theme>/<f>.jpg     key private/themes/<user>/<theme>/<f>.jpg
//	<root>/private/voice/<user>/<icebreaker>/<f>.webm      key private/voice/<user>/<icebreaker>/<f>.webm
//	<root>/private/verification/<user>/<field>/<f>.png     key private/verification/<user>/<field>/<f>.png
//	<root>/private/support_attachments/<user>/<f>.jpg      key private/support/<user>/<f>.jpg
//	<root>/tmp/                                            in-progress uploads (same filesystem)
//
// Flat layout (development default) stores <root>/<key> with <root>/.tmp.
type LocalStore struct {
	root           string
	layout         string
	legacyRoots    []string
	minFreeBytes   int64
	publicDirMode  os.FileMode
	publicFileMode os.FileMode
	// freeSpace is replaceable in tests.
	freeSpace func(dir string) (uint64, error)
}

// NewLocal builds a local store. It does not touch the filesystem; call
// SelfCheck at startup.
func NewLocal(cfg config.LocalStorageConfig) (*LocalStore, error) {
	root := strings.TrimSpace(cfg.Root)
	layout := cfg.Layout
	if root == "" {
		root = strings.TrimSpace(cfg.LegacyUploadsDir)
		layout = config.LocalLayoutFlat
	}
	if root == "" {
		root = config.DefaultLegacyUploadsDir
	}
	if layout == "" {
		layout = config.LocalLayoutKinds
	}
	if layout != config.LocalLayoutKinds && layout != config.LocalLayoutFlat {
		return nil, fmt.Errorf("mediastore: unsupported local layout %q", layout)
	}
	absRoot, err := filepath.Abs(root)
	if err != nil {
		return nil, fmt.Errorf("mediastore: resolve media root %q: %w", root, err)
	}
	store := &LocalStore{
		root:           filepath.Clean(absRoot),
		layout:         layout,
		minFreeBytes:   cfg.MinFreeBytes,
		publicDirMode:  cfg.PublicDirMode,
		publicFileMode: cfg.PublicFileMode,
		freeSpace:      statfsAvailable,
	}
	if store.publicDirMode == 0 {
		store.publicDirMode = 0o750
	}
	if store.publicFileMode == 0 {
		store.publicFileMode = 0o640
	}
	if layout == config.LocalLayoutKinds && strings.TrimSpace(cfg.LegacyUploadsDir) != "" {
		legacy, err := filepath.Abs(cfg.LegacyUploadsDir)
		if err != nil {
			return nil, fmt.Errorf("mediastore: resolve MEDIA_UPLOADS_DIR: %w", err)
		}
		legacy = filepath.Clean(legacy)
		if legacy == store.root || strings.HasPrefix(legacy, store.root+string(os.PathSeparator)) || strings.HasPrefix(store.root, legacy+string(os.PathSeparator)) {
			return nil, fmt.Errorf("mediastore: MEDIA_UPLOADS_DIR %s overlaps MEDIA_STORAGE_ROOT %s", legacy, store.root)
		}
		store.legacyRoots = append(store.legacyRoots, legacy)
	}
	return store, nil
}

// Backend implements Store.
func (s *LocalStore) Backend() string { return config.StorageBackendLocalFS }

// Root returns the absolute media root.
func (s *LocalStore) Root() string { return s.root }

// Layout returns "kinds" or "flat".
func (s *LocalStore) Layout() string { return s.layout }

// LegacyRoots returns the read/delete fallback directories.
func (s *LocalStore) LegacyRoots() []string { return append([]string(nil), s.legacyRoots...) }

func (s *LocalStore) tempDir() string {
	if s.layout == config.LocalLayoutFlat {
		return filepath.Join(s.root, ".tmp")
	}
	return filepath.Join(s.root, "tmp")
}

func (s *LocalStore) modes(spec KindSpec) (os.FileMode, os.FileMode) {
	if s.layout == config.LocalLayoutKinds && spec.Visibility == VisibilityPublic {
		return s.publicDirMode, s.publicFileMode
	}
	return privateDirMode, privateFileMode
}

// relativePath maps a logical key to its path below the root.
func (s *LocalStore) relativePath(key string) (KindSpec, string, error) {
	spec, rest, err := Classify(key)
	if err != nil {
		return KindSpec{}, "", err
	}
	if s.layout == config.LocalLayoutFlat {
		cleaned, _ := CleanKey(key)
		return spec, cleaned, nil
	}
	return spec, path.Join(spec.LocalDir, rest), nil
}

// contained joins rel to base and refuses anything that escapes base.
func contained(base, rel string) (string, error) {
	target := filepath.Clean(filepath.Join(base, filepath.FromSlash(rel)))
	if target == base || !strings.HasPrefix(target, base+string(os.PathSeparator)) {
		return "", ErrInvalidKey
	}
	return target, nil
}

// candidates lists where key may live: the primary location first, then the
// legacy flat directories (read/delete fallback).
func (s *LocalStore) candidates(key string) (KindSpec, []string, string, error) {
	spec, rel, err := s.relativePath(key)
	if err != nil {
		return KindSpec{}, nil, "", err
	}
	primary, err := contained(s.root, rel)
	if err != nil {
		return KindSpec{}, nil, "", err
	}
	paths := []string{primary}
	cleaned, _ := CleanKey(key)
	for _, legacy := range s.legacyRoots {
		if candidate, err := contained(legacy, cleaned); err == nil {
			paths = append(paths, candidate)
		}
	}
	return spec, paths, rel, nil
}

// Put implements Store with write-to-tmp + fsync + rename.
func (s *LocalStore) Put(_ context.Context, key string, body []byte, _ PutOptions) error {
	spec, rel, err := s.relativePath(key)
	if err != nil {
		return err
	}
	target, err := contained(s.root, rel)
	if err != nil {
		return err
	}
	if s.minFreeBytes > 0 && s.freeSpace != nil {
		if available, err := s.freeSpace(s.root); err == nil && available < uint64(s.minFreeBytes)+uint64(len(body)) {
			return ErrInsufficientSpace
		}
	}
	dirMode, fileMode := s.modes(spec)
	if err := s.ensureTree(filepath.Dir(target), dirMode); err != nil {
		return fmt.Errorf("mediastore: create media directory: %w", err)
	}
	tmpDir := s.tempDir()
	if err := s.ensureTree(tmpDir, privateDirMode); err != nil {
		return fmt.Errorf("mediastore: create temp directory: %w", err)
	}
	tmp, err := os.CreateTemp(tmpDir, tempPattern)
	if err != nil {
		return fmt.Errorf("mediastore: create temp file: %w", err)
	}
	tmpName := tmp.Name()
	committed := false
	defer func() {
		if !committed {
			_ = tmp.Close()
			_ = os.Remove(tmpName)
		}
	}()
	if _, err := tmp.Write(body); err != nil {
		return fmt.Errorf("mediastore: write temp file: %w", err)
	}
	if err := tmp.Chmod(fileMode); err != nil {
		return fmt.Errorf("mediastore: chmod temp file: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		return fmt.Errorf("mediastore: fsync temp file: %w", err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("mediastore: close temp file: %w", err)
	}
	if err := os.Rename(tmpName, target); err != nil {
		return fmt.Errorf("mediastore: publish media file: %w", err)
	}
	committed = true
	syncDir(filepath.Dir(target))
	return nil
}

// ensureTree creates missing directories between the root and dir with mode
// (umask-independent). Existing directories are left alone.
func (s *LocalStore) ensureTree(dir string, mode os.FileMode) error {
	dir = filepath.Clean(dir)
	if dir != s.root && !strings.HasPrefix(dir, s.root+string(os.PathSeparator)) {
		return ErrInvalidKey
	}
	if info, err := os.Lstat(dir); err == nil {
		if !info.IsDir() {
			return fmt.Errorf("%s exists and is not a directory", dir)
		}
		return nil
	}
	if dir == s.root {
		return os.MkdirAll(dir, mode)
	}
	{
		parentMode := mode
		if filepath.Dir(dir) == s.root {
			parentMode = s.rootMode()
		}
		if err := s.ensureTree(filepath.Dir(dir), parentMode); err != nil {
			return err
		}
	}
	if err := os.Mkdir(dir, mode); err != nil && !errors.Is(err, fs.ErrExist) {
		return err
	}
	return os.Chmod(dir, mode)
}

func (s *LocalStore) rootMode() os.FileMode {
	if s.layout == config.LocalLayoutKinds {
		// The group (e.g. www-data via the connect group) may traverse to
		// public/; private/, quarantine/ and tmp/ are 0700 below it.
		return s.publicDirMode
	}
	return privateDirMode
}

// Open implements Store.
func (s *LocalStore) Open(_ context.Context, key string) (Object, error) {
	_, paths, _, err := s.candidates(key)
	if err != nil {
		return Object{}, err
	}
	for _, candidate := range paths {
		file, err := openNoFollow(candidate)
		if err != nil {
			if isNotFound(err) {
				continue
			}
			return Object{}, err
		}
		info, err := file.Stat()
		if err != nil || !info.Mode().IsRegular() {
			_ = file.Close()
			if err == nil {
				err = ErrNotFound
			}
			return Object{}, err
		}
		return Object{
			Body:        file,
			Size:        info.Size(),
			ContentType: mime.TypeByExtension(strings.ToLower(filepath.Ext(candidate))),
			ModTime:     info.ModTime(),
		}, nil
	}
	return Object{}, ErrNotFound
}

// OpenFile is Open returning the *os.File (for http.ServeContent).
func (s *LocalStore) OpenFile(ctx context.Context, key string) (*os.File, os.FileInfo, error) {
	object, err := s.Open(ctx, key)
	if err != nil {
		return nil, nil, err
	}
	file := object.Body.(*os.File)
	info, err := file.Stat()
	if err != nil {
		_ = file.Close()
		return nil, nil, err
	}
	return file, info, nil
}

// Stat implements Store.
func (s *LocalStore) Stat(_ context.Context, key string) (ObjectInfo, error) {
	_, paths, _, err := s.candidates(key)
	if err != nil {
		return ObjectInfo{}, err
	}
	for _, candidate := range paths {
		info, err := os.Lstat(candidate)
		if err != nil {
			if isNotFound(err) {
				continue
			}
			return ObjectInfo{}, err
		}
		if !info.Mode().IsRegular() {
			return ObjectInfo{}, ErrNotFound
		}
		cleaned, _ := CleanKey(key)
		return ObjectInfo{Key: cleaned, Size: info.Size(), ModTime: info.ModTime()}, nil
	}
	return ObjectInfo{}, ErrNotFound
}

// Exists implements Store.
func (s *LocalStore) Exists(ctx context.Context, key string) (bool, error) {
	_, err := s.Stat(ctx, key)
	if errors.Is(err, ErrNotFound) {
		return false, nil
	}
	return err == nil, err
}

// Delete implements Store; it removes the primary and any legacy copy.
func (s *LocalStore) Delete(_ context.Context, key string) error {
	_, paths, _, err := s.candidates(key)
	if err != nil {
		return err
	}
	var firstErr error
	for _, candidate := range paths {
		if err := os.Remove(candidate); err != nil && !isNotFound(err) && firstErr == nil {
			firstErr = err
		}
	}
	return firstErr
}

// Presign implements Store.
func (s *LocalStore) Presign(context.Context, string, time.Duration) (string, error) {
	return "", ErrPresignUnsupported
}

// LocalPath implements LocalPather. relative is empty when the file was found
// in a legacy directory outside the root.
func (s *LocalStore) LocalPath(key string) (string, string, error) {
	_, paths, rel, err := s.candidates(key)
	if err != nil {
		return "", "", err
	}
	for index, candidate := range paths {
		info, err := os.Lstat(candidate)
		if err != nil || !info.Mode().IsRegular() {
			continue
		}
		if index == 0 {
			return candidate, rel, nil
		}
		return candidate, "", nil
	}
	return "", "", ErrNotFound
}

// Visibility returns the visibility of key (for nginx X-Accel decisions).
func (s *LocalStore) Visibility(key string) (Visibility, error) {
	spec, _, err := Classify(key)
	return spec.Visibility, err
}

// Walk implements Store. Every stored object is visited once per location;
// files that do not map back to a valid key of their directory are skipped.
func (s *LocalStore) Walk(ctx context.Context, fn func(ObjectInfo) error) error {
	type tree struct {
		dir       string
		keyPrefix string
		kind      Kind
		skipTop   string
	}
	var trees []tree
	if s.layout == config.LocalLayoutFlat {
		trees = append(trees, tree{dir: s.root, skipTop: ".tmp"})
	} else {
		for _, spec := range Specs {
			trees = append(trees, tree{dir: filepath.Join(s.root, filepath.FromSlash(spec.LocalDir)), keyPrefix: spec.KeyPrefix, kind: spec.Kind})
		}
	}
	for _, legacy := range s.legacyRoots {
		trees = append(trees, tree{dir: legacy, skipTop: ".tmp"})
	}
	for _, t := range trees {
		err := filepath.WalkDir(t.dir, func(current string, entry fs.DirEntry, walkErr error) error {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			if walkErr != nil {
				if current == t.dir && isNotFound(walkErr) {
					return filepath.SkipDir
				}
				return nil
			}
			if entry.IsDir() {
				if t.skipTop != "" && current == filepath.Join(t.dir, t.skipTop) {
					return filepath.SkipDir
				}
				return nil
			}
			if !entry.Type().IsRegular() {
				return nil
			}
			rel, err := filepath.Rel(t.dir, current)
			if err != nil {
				return nil
			}
			key := filepath.ToSlash(rel)
			if t.keyPrefix != "" {
				key = t.keyPrefix + "/" + key
			}
			spec, _, err := Classify(key)
			if err != nil || (t.kind != "" && spec.Kind != t.kind) {
				return nil
			}
			info, err := entry.Info()
			if err != nil {
				return nil
			}
			return fn(ObjectInfo{Key: key, Size: info.Size(), ModTime: info.ModTime()})
		})
		if err != nil && !errors.Is(err, filepath.SkipDir) {
			return err
		}
	}
	return nil
}

// SweepTemp removes abandoned in-progress uploads older than maxAge.
func (s *LocalStore) SweepTemp(maxAge time.Duration) int {
	entries, err := os.ReadDir(s.tempDir())
	if err != nil {
		return 0
	}
	cutoff := time.Now().Add(-maxAge)
	removed := 0
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasPrefix(entry.Name(), ".upload-") && !strings.HasPrefix(entry.Name(), ".probe-") {
			continue
		}
		info, err := entry.Info()
		if err == nil && info.ModTime().Before(cutoff) {
			if os.Remove(filepath.Join(s.tempDir(), entry.Name())) == nil {
				removed++
			}
		}
	}
	return removed
}

// SelfCheck creates the directory layout and proves it is writable, on one
// filesystem, and not exposed. It fails fast with an actionable message.
func (s *LocalStore) SelfCheck() (warnings []string, err error) {
	fail := func(format string, args ...any) ([]string, error) {
		return warnings, fmt.Errorf("media storage self-check failed: "+format+
			"\n  hint: run deploy/scripts/setup_media_storage.sh (creates the connect user and %s with the right owner/permissions)", append(args, s.root)...)
	}
	if err := os.MkdirAll(s.root, s.rootMode()); err != nil {
		return fail("cannot create media root %s: %v", s.root, err)
	}
	info, err := os.Lstat(s.root)
	if err != nil || !info.IsDir() {
		return fail("media root %s is not a directory", s.root)
	}
	if info.Mode().Perm()&0o002 != 0 {
		return fail("media root %s is world-writable (%#o)", s.root, info.Mode().Perm())
	}
	type dirSpec struct {
		rel  string
		mode os.FileMode
	}
	var dirs []dirSpec
	if s.layout == config.LocalLayoutKinds {
		dirs = append(dirs,
			dirSpec{"public", s.publicDirMode},
			dirSpec{"private", privateDirMode},
			dirSpec{"quarantine", privateDirMode},
			dirSpec{"tmp", privateDirMode},
		)
		for _, spec := range Specs {
			dirMode, _ := s.modes(spec)
			dirs = append(dirs, dirSpec{spec.LocalDir, dirMode})
		}
	} else {
		dirs = append(dirs, dirSpec{".tmp", privateDirMode})
	}
	for _, d := range dirs {
		abs := filepath.Join(s.root, filepath.FromSlash(d.rel))
		if err := s.ensureTree(abs, d.mode); err != nil {
			return fail("cannot create %s: %v", abs, err)
		}
		info, err := os.Lstat(abs)
		if err != nil {
			return fail("cannot stat %s: %v", abs, err)
		}
		if info.Mode()&os.ModeSymlink != 0 || !info.IsDir() {
			return fail("%s must be a real directory (symlinks are refused)", abs)
		}
		perm := info.Mode().Perm()
		if d.mode&0o077 == 0 && perm&0o077 != 0 {
			// Private trees must never be readable by nginx or other users.
			if err := os.Chmod(abs, d.mode); err != nil {
				return fail("%s is %#o but must be %#o and chmod failed: %v", abs, perm, d.mode, err)
			}
			warnings = append(warnings, fmt.Sprintf("tightened %s from %#o to %#o", abs, perm, d.mode))
		} else if perm&0o002 != 0 {
			return fail("%s is world-writable (%#o)", abs, perm)
		}
	}
	// Probe: write in tmp, rename into every leaf directory, remove. This proves
	// write access and that tmp/ shares a filesystem with each kind directory
	// (rename is the atomic publish step).
	leaves := []string{"."}
	if s.layout == config.LocalLayoutKinds {
		leaves = leaves[:0]
		for _, spec := range Specs {
			leaves = append(leaves, spec.LocalDir)
		}
	}
	for _, leaf := range leaves {
		probe, err := os.CreateTemp(s.tempDir(), ".probe-*")
		if err != nil {
			return fail("%s is not writable by uid %d: %v", s.tempDir(), os.Getuid(), err)
		}
		probeName := probe.Name()
		_, writeErr := probe.Write([]byte("ok"))
		syncErr := probe.Sync()
		_ = probe.Close()
		if writeErr != nil || syncErr != nil {
			_ = os.Remove(probeName)
			return fail("cannot write to %s: %v", s.tempDir(), errors.Join(writeErr, syncErr))
		}
		destination := filepath.Join(s.root, filepath.FromSlash(leaf), filepath.Base(probeName))
		if err := os.Rename(probeName, destination); err != nil {
			_ = os.Remove(probeName)
			if errors.Is(err, syscall.EXDEV) {
				return fail("%s and %s are on different filesystems; tmp/ must share the media filesystem for atomic uploads", s.tempDir(), filepath.Dir(destination))
			}
			return fail("%s is not writable by uid %d: %v", filepath.Dir(destination), os.Getuid(), err)
		}
		if err := os.Remove(destination); err != nil {
			return fail("cannot remove probe %s: %v", destination, err)
		}
	}
	if s.minFreeBytes > 0 && s.freeSpace != nil {
		if available, err := s.freeSpace(s.root); err == nil && available < uint64(s.minFreeBytes) {
			warnings = append(warnings, fmt.Sprintf("only %d MiB free on the media filesystem; uploads are refused below MEDIA_MIN_FREE_MB=%d", available>>20, s.minFreeBytes>>20))
		}
	}
	for _, legacy := range s.legacyRoots {
		if _, err := os.Stat(legacy); err == nil {
			warnings = append(warnings, fmt.Sprintf("legacy uploads directory %s is still read as a fallback; copy it with `mediactl copy --from legacy --to local --apply` and then unset MEDIA_UPLOADS_DIR", legacy))
		}
	}
	return warnings, nil
}

func statfsAvailable(dir string) (uint64, error) {
	var stat syscall.Statfs_t
	if err := syscall.Statfs(dir, &stat); err != nil {
		return 0, err
	}
	return uint64(stat.Bavail) * uint64(stat.Bsize), nil
}

func openNoFollow(name string) (*os.File, error) {
	return os.OpenFile(name, os.O_RDONLY|syscall.O_NOFOLLOW, 0)
}

func isNotFound(err error) bool {
	return errors.Is(err, fs.ErrNotExist) || errors.Is(err, syscall.ENOTDIR)
}

func syncDir(dir string) {
	if handle, err := os.Open(dir); err == nil {
		_ = handle.Sync()
		_ = handle.Close()
	}
}
