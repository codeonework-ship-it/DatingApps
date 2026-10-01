package postgresdata

import (
	"database/sql"
	"path/filepath"
	"runtime"
	"strings"
	"weak"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/verified-dating/backend/internal/platform/observability"
)

// poolName returns a bounded, code-defined name for a pool: the explicit
// Options.PoolName, or "<package dir>/<file>" of the code that opened it
// (for example "mobile/terms_repository").
func poolName(explicit string, callerSkip int) string {
	if name := strings.TrimSpace(explicit); name != "" {
		return name
	}
	_, file, _, ok := runtime.Caller(callerSkip + 1)
	if !ok {
		return "unknown"
	}
	base := strings.TrimSuffix(filepath.Base(file), ".go")
	return filepath.Base(filepath.Dir(file)) + "/" + base
}

// trackSQLPool publishes database/sql pool stats without keeping the pool
// alive: once the *sql.DB is garbage collected the collector forgets it.
func trackSQLPool(name string, db *sql.DB) {
	ref := weak.Make(db)
	observability.TrackDBPool(name, func() (observability.DBPoolStats, bool) {
		current := ref.Value()
		if current == nil {
			return observability.DBPoolStats{}, false
		}
		s := current.Stats()
		return observability.DBPoolStats{
			MaxConnections:   s.MaxOpenConnections,
			OpenConnections:  s.OpenConnections,
			InUseConnections: s.InUse,
			IdleConnections:  s.Idle,
			WaitCount:        s.WaitCount,
			WaitDuration:     s.WaitDuration,
		}, true
	})
}

func trackPgxPool(name string, pool *pgxpool.Pool) func() {
	return observability.TrackDBPool(name, func() (observability.DBPoolStats, bool) {
		s := pool.Stat()
		return observability.DBPoolStats{
			MaxConnections:   int(s.MaxConns()),
			OpenConnections:  int(s.TotalConns()),
			InUseConnections: int(s.AcquiredConns()),
			IdleConnections:  int(s.IdleConns()),
			WaitCount:        s.EmptyAcquireCount(),
			WaitDuration:     s.EmptyAcquireWaitTime(),
		}, true
	})
}
