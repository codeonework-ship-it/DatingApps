// Command mediactl checks the media storage configuration and copies media
// between backends (legacy upload dir -> VPS layout, local -> AWS S3).
//
//	mediactl check [-probe]
//	mediactl copy -from legacy|local -to local|s3 [-apply] [-verify checksum|download] [-overwrite] [-kinds voice,verification]
//
// It reads the same environment as the API (systemd EnvironmentFile or
// STORAGE_CONFIG_FILE). copy is a dry run unless -apply is given, is
// idempotent (identical objects are skipped) and verifies every write by
// SHA-256. Database rows are not changed: storage keys are backend independent.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/mediastore"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := config.ApplyStorageConfigFile(); err != nil {
		fatal(err)
	}
	switch os.Args[1] {
	case "check":
		os.Exit(check(ctx, os.Args[2:]))
	case "copy":
		os.Exit(copyMedia(ctx, os.Args[2:]))
	default:
		usage()
		os.Exit(2)
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, `usage:
  mediactl check [-probe]
      validate the storage configuration, create/verify local directories or
      resolve S3 credentials; -probe also writes, reads and deletes a test object
  mediactl copy -from legacy|local -to local|s3 [-apply] [-verify checksum|download] [-overwrite] [-kinds k1,k2] [-legacy-dir DIR]
      copy media between backends (dry run unless -apply)
      legacy = flat MEDIA_UPLOADS_DIR, local = MEDIA_STORAGE_ROOT layout, s3 = AWS_S3_* bucket(s)
  kinds: profile_photos, profile_photos_quarantine, legacy_profile_photos, chapter_photos,
         theme_photos, group_covers, voice, verification`)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "mediactl:", err)
	os.Exit(1)
}

func environment() string {
	if value := strings.TrimSpace(os.Getenv("ENVIRONMENT")); value != "" {
		return value
	}
	return "development"
}

// loadAs validates the storage section as if backend were selected, so S3
// settings can be checked before FILE_STORAGE_BACKEND is switched.
func loadAs(backend string) (config.MediaStorageConfig, error) {
	previousBackend, hadBackend := os.LookupEnv("FILE_STORAGE_BACKEND")
	previousUseS3, hadUseS3 := os.LookupEnv("USE_AWS_S3_STORAGE")
	defer func() {
		restore("FILE_STORAGE_BACKEND", previousBackend, hadBackend)
		restore("USE_AWS_S3_STORAGE", previousUseS3, hadUseS3)
	}()
	_ = os.Setenv("FILE_STORAGE_BACKEND", backend)
	_ = os.Setenv("USE_AWS_S3_STORAGE", fmt.Sprint(backend == config.StorageBackendAWSS3))
	return config.LoadMediaStorage(environment())
}

func restore(key, value string, had bool) {
	if had {
		_ = os.Setenv(key, value)
	} else {
		_ = os.Unsetenv(key)
	}
}

func check(ctx context.Context, args []string) int {
	flags := flag.NewFlagSet("check", flag.ExitOnError)
	probe := flags.Bool("probe", false, "write, read back and delete a test object")
	_ = flags.Parse(args)
	cfg, err := config.LoadMediaStorage(environment())
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	fmt.Println("storage:", cfg.Summary())
	store, warnings, err := mediastore.Open(ctx, cfg)
	for _, warning := range warnings {
		fmt.Println("warning:", warning)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	if local, ok := store.(*mediastore.LocalStore); ok {
		fmt.Printf("local root %s (layout %s) is ready\n", local.Root(), local.Layout())
	} else {
		fmt.Println("AWS credentials resolved")
	}
	if *probe {
		if err := mediastore.Probe(ctx, store); err != nil {
			fmt.Fprintln(os.Stderr, "probe failed:", err)
			return 1
		}
		fmt.Println("probe: put/get/delete OK")
	}
	return 0
}

func copyMedia(ctx context.Context, args []string) int {
	flags := flag.NewFlagSet("copy", flag.ExitOnError)
	from := flags.String("from", "", "source: legacy | local")
	to := flags.String("to", "", "destination: local | s3")
	apply := flags.Bool("apply", false, "perform the copy (default is a dry run)")
	verify := flags.String("verify", "checksum", "checksum | download")
	overwrite := flags.Bool("overwrite", false, "replace destination objects whose bytes differ")
	kinds := flags.String("kinds", "", "comma-separated kinds to copy (default all)")
	legacyDir := flags.String("legacy-dir", "", "legacy flat upload directory (default MEDIA_UPLOADS_DIR or .run/uploads/profile_photos)")
	quiet := flags.Bool("quiet", false, "print only the summary")
	_ = flags.Parse(args)
	if *verify != "checksum" && *verify != "download" {
		fatal(fmt.Errorf("-verify must be checksum or download"))
	}

	localCfg, err := loadAs(config.StorageBackendLocalFS)
	if err != nil {
		fatal(err)
	}
	var source mediastore.Store
	switch *from {
	case "legacy":
		dir := strings.TrimSpace(*legacyDir)
		if dir == "" {
			dir = strings.TrimSpace(os.Getenv("MEDIA_UPLOADS_DIR"))
		}
		if dir == "" {
			dir = config.DefaultLegacyUploadsDir
		}
		if _, err := os.Stat(dir); err != nil {
			fatal(fmt.Errorf("legacy directory %s: %w", dir, err))
		}
		source, err = mediastore.NewLocal(config.LocalStorageConfig{LegacyUploadsDir: dir, Layout: config.LocalLayoutFlat})
	case "local":
		source, err = mediastore.NewLocal(localCfg.Local)
	default:
		fatal(fmt.Errorf("-from must be legacy or local"))
	}
	if err != nil {
		fatal(err)
	}

	var destination mediastore.Store
	switch *to {
	case "local":
		if *from == "local" {
			fatal(fmt.Errorf("-from local -to local copies onto itself"))
		}
		if localCfg.Local.Root == "" {
			fatal(fmt.Errorf("set MEDIA_STORAGE_ROOT (e.g. %s) for the destination layout", config.DefaultProductionMediaRoot))
		}
		destinationCfg := localCfg
		destinationCfg.Local.LegacyUploadsDir = "" // write and verify the new layout only
		destinationCfg.Local.Layout = config.LocalLayoutKinds
		var warnings []string
		destination, warnings, err = mediastore.Open(ctx, destinationCfg)
		for _, warning := range warnings {
			fmt.Println("warning:", warning)
		}
	case "s3":
		s3Cfg, loadErr := loadAs(config.StorageBackendAWSS3)
		if loadErr != nil {
			fatal(loadErr)
		}
		fmt.Println("destination:", s3Cfg.Summary())
		destination, _, err = mediastore.Open(ctx, s3Cfg)
	default:
		fatal(fmt.Errorf("-to must be local or s3"))
	}
	if err != nil {
		fatal(err)
	}

	options := mediastore.CopyOptions{Apply: *apply, Verify: *verify, Overwrite: *overwrite}
	for _, kind := range strings.Split(*kinds, ",") {
		if kind = strings.TrimSpace(kind); kind != "" {
			if mediastore.SpecFor(mediastore.Kind(kind)).Kind == "" {
				fatal(fmt.Errorf("unknown kind %q", kind))
			}
			options.Kinds = append(options.Kinds, mediastore.Kind(kind))
		}
	}
	if !*quiet {
		options.Logf = func(format string, args ...any) { fmt.Printf(format+"\n", args...) }
	}
	if !*apply {
		fmt.Println("dry run: nothing is written (add -apply to copy)")
	}
	report, err := mediastore.Copy(ctx, source, destination, options)
	fmt.Println("summary:", report.String())
	if err != nil {
		fmt.Fprintln(os.Stderr, "copy stopped:", err)
		return 1
	}
	if report.Failed > 0 || report.Conflicts > 0 {
		return 1
	}
	return 0
}
