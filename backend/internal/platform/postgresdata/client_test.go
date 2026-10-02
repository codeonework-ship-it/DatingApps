package postgresdata

import (
	"errors"
	"net/url"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
)

func TestNormalizeValue_UUIDArray(t *testing.T) {
	raw := [16]uint8{0xe7, 0x7f, 0xd1, 0x79, 0xf7, 0xf2, 0x4c, 0xb7, 0x8a, 0x8f, 0x2a, 0x2b, 0x61, 0xd4, 0xb7, 0x5e}
	if got := normalizeValue(raw); got != "e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e" {
		t.Fatalf("normalizeValue() = %v", got)
	}
}

func TestSetRuntimeTimeout_UsesMillisecondsAndIgnoresDisabled(t *testing.T) {
	params := map[string]string{}
	setRuntimeTimeout(params, "statement_timeout", 1500*time.Millisecond)
	setRuntimeTimeout(params, "lock_timeout", 0)
	if params["statement_timeout"] != "1500" {
		t.Fatalf("statement_timeout=%q", params["statement_timeout"])
	}
	if _, exists := params["lock_timeout"]; exists {
		t.Fatal("disabled timeout should not be installed")
	}
}

func TestSQLConfigAppliesRuntimeTimeouts(t *testing.T) {
	config, err := sqlConfig("postgresql://dating_app@127.0.0.1:55432/dating_app?sslmode=disable", Options{
		StatementTimeout:       4 * time.Second,
		LockTimeout:            900 * time.Millisecond,
		IdleTransactionTimeout: 12 * time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	if got := config.RuntimeParams["statement_timeout"]; got != "4000" {
		t.Fatalf("statement_timeout=%q", got)
	}
	if got := config.RuntimeParams["lock_timeout"]; got != "900" {
		t.Fatalf("lock_timeout=%q", got)
	}
	if got := config.RuntimeParams["idle_in_transaction_session_timeout"]; got != "12000" {
		t.Fatalf("idle_in_transaction_session_timeout=%q", got)
	}
}

func TestClassifyQueryError_TagsTimeoutAndDeadlockSQLStates(t *testing.T) {
	for code, kind := range map[string]string{
		"57014": "statement_timeout",
		"55P03": "lock_timeout",
		"40P01": "deadlock",
	} {
		pgErr := &pgconn.PgError{Code: code, Message: "injected"}
		got := classifyQueryError(pgErr)
		if !errors.Is(got, pgErr) || !strings.Contains(got.Error(), "kind="+kind) {
			t.Fatalf("code %s classified as %v", code, got)
		}
	}
}

func TestBuildWhere_UsesBoundArguments(t *testing.T) {
	params := url.Values{}
	params.Set("user_id", "eq.e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e")
	params.Set("status", "in.(active,pending)")
	params.Set("or", "(sender_id.eq.e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e,receiver_id.eq.e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e)")

	where, args, err := buildWhere(params, 1)
	if err != nil {
		t.Fatal(err)
	}
	want := ` WHERE ("sender_id" = $1 OR "receiver_id" = $2) AND "status" IN ($3, $4) AND "user_id" = $5`
	if where != want {
		t.Fatalf("where = %q, want %q", where, want)
	}
	if !reflect.DeepEqual(args, []any{
		"e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e",
		"e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e",
		"active",
		"pending",
		"e77fd179-f7f2-4cb7-8a8f-2a2b61d4b75e",
	}) {
		t.Fatalf("args = %#v", args)
	}
}

func TestUpdateAndDeleteRejectMissingFilters(t *testing.T) {
	client := &Client{}
	if _, err := client.Update(t.Context(), "matching", "messages", map[string]any{"text": "x"}, nil); err == nil {
		t.Fatal("expected unfiltered update to be rejected")
	}
	if _, err := client.Delete(t.Context(), "matching", "messages", nil); err == nil {
		t.Fatal("expected unfiltered delete to be rejected")
	}
}

func TestSQLPoolLimitsKeepIdleConnectionsUpToTheCap(t *testing.T) {
	cases := []struct {
		settings         Options
		maxOpen, maxIdle int
	}{
		{Options{MaxConns: 16, MinConns: 4}, 16, 16},
		{Options{MaxConns: 8, MinConns: 2}, 8, 8},
		{Options{MaxConns: 0, MinConns: 2}, 16, 16},
		{Options{MaxConns: 4, MinConns: 10}, 4, 4},
	}
	for _, tc := range cases {
		open, idle := sqlPoolLimits(tc.settings)
		if open != tc.maxOpen || idle != tc.maxIdle {
			t.Fatalf("sqlPoolLimits(%+v) = (%d,%d), want (%d,%d)", tc.settings, open, idle, tc.maxOpen, tc.maxIdle)
		}
	}
}
