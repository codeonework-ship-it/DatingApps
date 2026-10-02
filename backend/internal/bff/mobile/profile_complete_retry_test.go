package mobile

import (
	"context"
	"errors"
	"fmt"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
)

// API-23: under concurrent signups the SERIALIZABLE profile-completion
// transaction was cancelled with 40001 and surfaced as a 502 on the last
// signup step. It is now re-run a bounded number of times.
func TestRetrySerializableRetriesOnlySerializationFailures(t *testing.T) {
	ctx := context.Background()
	serialization := fmt.Errorf("complete profile failed: %w", &pgconn.PgError{Code: "40001", Message: "could not serialize access due to read/write dependencies among transactions"})

	calls := 0
	err := retrySerializable(ctx, serializableAttempts, func() error {
		calls++
		if calls < serializableAttempts {
			return serialization
		}
		return nil
	})
	if err != nil || calls != serializableAttempts {
		t.Fatalf("transient 40001 must be retried until success: err=%v calls=%d", err, calls)
	}

	calls = 0
	err = retrySerializable(ctx, serializableAttempts, func() error { calls++; return serialization })
	if !isSerializationFailure(err) || calls != serializableAttempts {
		t.Fatalf("persistent 40001 must stop after %d attempts: err=%v calls=%d", serializableAttempts, err, calls)
	}

	for name, other := range map[string]error{
		"unique violation": &pgconn.PgError{Code: "23505"},
		"deadlock":         &pgconn.PgError{Code: "40P01"},
		"completion":       completionProblem(errors.New("terms must be accepted before completing profile")),
		"plain":            errors.New("boom"),
	} {
		calls = 0
		err = retrySerializable(ctx, serializableAttempts, func() error { calls++; return other })
		if !errors.Is(err, other) || calls != 1 {
			t.Fatalf("%s must not be retried: err=%v calls=%d", name, err, calls)
		}
	}

	cancelled, cancel := context.WithCancel(ctx)
	cancel()
	calls = 0
	err = retrySerializable(cancelled, serializableAttempts, func() error { calls++; return serialization })
	if !isSerializationFailure(err) || calls != 1 {
		t.Fatalf("a cancelled request must not keep retrying: err=%v calls=%d", err, calls)
	}
}
