package mobile

import (
	"context"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/mediastore"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func (s *Server) startMediaLifecycleCleanup() {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return
	}
	ctx, cancel := context.WithCancel(context.Background())
	s.mediaCleanupCancel = cancel
	s.mediaCleanupDone = make(chan struct{})
	go func() {
		defer close(s.mediaCleanupDone)
		s.runMediaLifecycleCleanup(ctx)
		ticker := time.NewTicker(mediaCleanupInterval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				s.runMediaLifecycleCleanup(ctx)
			}
		}
	}()
}

func (s *Server) runMediaLifecycleCleanup(ctx context.Context) {
	run := observability.NewHeartbeat(workerMediaCleanup, mediaCleanupInterval).Begin()
	var runErr error
	deleted, failed := 0, 0
	defer func() {
		run.Items("processed", deleted)
		run.Items("failed", failed)
		run.End(runErr)
	}()
	repo := s.store.profileRepo
	s.cleanupDeletedBlogMedia(ctx)
	s.cleanupDeletedThemeMedia(ctx)
	s.releaseGroupCoverMedia(ctx, "")
	items, err := repo.listMediaCleanupCandidatesPostgres(ctx, 200)
	if err != nil {
		runErr = err
		s.log.Warn("media cleanup candidate query failed")
		return
	}
	for _, item := range items {
		if err := s.deleteStoredMedia(item.StoragePath); err != nil {
			failed++
			s.log.Warn("media cleanup file delete failed")
			continue
		}
		deleted++
		_ = repo.markExpiredStagedPhotoDeletedPostgres(ctx, item.PhotoID)
	}
	_, _ = repo.purgeExpiredDraftSnapshotsPostgres(ctx)
	if !s.usesAWSS3Storage() {
		s.cleanupUnreferencedLocalFiles(ctx)
	}
}

func (s *Server) cleanupUnreferencedLocalFiles(ctx context.Context) {
	referenced, err := s.store.profileRepo.referencedMediaPathsPostgres(ctx)
	if err != nil {
		return
	}
	privateReferenced, err := s.privateMediaReferences(ctx)
	if err != nil {
		// Fail closed: never delete private evidence when its reference scan is
		// unavailable or the schema is between migrations.
		return
	}
	for storagePath := range privateReferenced {
		referenced[storagePath] = struct{}{}
	}
	store, err := s.mediaStore()
	if err != nil {
		return
	}
	local, ok := store.(*mediastore.LocalStore)
	if !ok {
		return
	}
	local.SweepTemp(time.Hour)
	cutoff := time.Now().Add(-24 * time.Hour)
	var orphans []string
	_ = local.Walk(ctx, func(info mediastore.ObjectInfo) error {
		if _, ok := referenced[info.Key]; ok {
			return nil
		}
		if info.ModTime.Before(cutoff) {
			orphans = append(orphans, info.Key)
		}
		return nil
	})
	for _, key := range orphans {
		_ = local.Delete(ctx, key)
	}
}

func (s *Server) privateMediaReferences(ctx context.Context) (map[string]struct{}, error) {
	result := make(map[string]struct{})
	rows, err := s.store.profileRepo.pg.QueryContext(ctx, `
		SELECT path FROM (
			SELECT details->'id_document'->>'storage_path' AS path
			FROM matching.verification_states
			UNION ALL
			SELECT details->'selfie'->>'storage_path' AS path
			FROM matching.verification_states
			UNION ALL
			SELECT audio_storage_path AS path
			FROM matching.voice_icebreakers
			UNION ALL
			SELECT storage_path AS path FROM matching.blog_photos
 UNION ALL SELECT storage_path AS path FROM matching.blog_evidence_photos
 UNION ALL SELECT storage_path AS path FROM matching.photo_theme_entries
 UNION ALL SELECT storage_path AS path FROM matching.community_group_covers WHERE storage_released_at IS NULL
		) media_refs
		WHERE path IS NOT NULL AND BTRIM(path) <> ''`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var storagePath string
		if err := rows.Scan(&storagePath); err != nil {
			return nil, err
		}
		result[strings.TrimSpace(storagePath)] = struct{}{}
	}
	return result, rows.Err()
}

// deleteStoredMedia releases one stored object through the configured
// backend (also used by the erasure and retention workers).
func (s *Server) deleteStoredMedia(storagePath string) error {
	return s.deleteStoredMediaFromStore(storagePath)
}
