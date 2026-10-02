package postgresdata

import (
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"
)

func TestSQLConfigRunsSessionsInUTCUnlessTheURLChoosesAZone(t *testing.T) {
	config, err := sqlConfig("postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable", Options{})
	if err != nil {
		t.Fatal(err)
	}
	if got := config.RuntimeParams["timezone"]; got != "UTC" {
		t.Fatalf("timezone=%q, want UTC", got)
	}
	explicit, err := sqlConfig("postgresql://dating_app@127.0.0.1:55433/dating_app?sslmode=disable&TimeZone=Europe/Paris", Options{})
	if err != nil {
		t.Fatal(err)
	}
	if _, overridden := explicit.RuntimeParams["timezone"]; overridden {
		t.Fatalf("explicit TimeZone overridden: %v", explicit.RuntimeParams)
	}
}

// API-05: timestamps read through either connection type serialise as UTC,
// whatever the database server's zone, both when decoded into time.Time and
// when rendered as text by SQL.
func TestTimestamptzIsUTCOnBothConnectionTypesPostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	ctx := context.Background()
	const query = `SELECT TIMESTAMPTZ '2026-10-01 23:51:01+05:30', (TIMESTAMPTZ '2026-10-01 23:51:01+05:30')::text, current_setting('TimeZone')`
	check := func(name string, ts time.Time, text, zone string) {
		t.Helper()
		if ts.Location() != time.UTC {
			t.Fatalf("%s: decoded in %v, want UTC", name, ts.Location())
		}
		encoded, _ := json.Marshal(ts)
		if string(encoded) != `"2026-10-01T18:21:01Z"` {
			t.Fatalf("%s: JSON %s", name, encoded)
		}
		if !strings.HasSuffix(text, "+00") || zone != "UTC" {
			t.Fatalf("%s: text=%q TimeZone=%q", name, text, zone)
		}
	}

	db, err := OpenSQL(dsn, Options{MaxConns: 1, PoolName: "utc_test_sql"})
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	var ts time.Time
	var text, zone string
	if err := db.QueryRowContext(ctx, query).Scan(&ts, &text, &zone); err != nil {
		t.Fatal(err)
	}
	check("database/sql", ts, text, zone)

	client, err := Open(ctx, dsn, Options{MaxConns: 1, PoolName: "utc_test_pool"})
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	if err := client.pool.QueryRow(ctx, query).Scan(&ts, &text, &zone); err != nil {
		t.Fatal(err)
	}
	check("pgx pool", ts, text, zone)
}
