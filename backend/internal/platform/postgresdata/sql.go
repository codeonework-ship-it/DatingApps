package postgresdata

import (
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/stdlib"
)

// OpenSQL gives repositories that need transactions and row locks the same
// session limits as the generic pgx pool. Keeping this in one place prevents a
// direct database/sql pool from silently bypassing statement/lock protection.
func OpenSQL(databaseURL string, settings Options) (*sql.DB, error) {
	connConfig, err := sqlConfig(databaseURL, settings)
	if err != nil {
		return nil, err
	}
	db := stdlib.OpenDB(*connConfig, stdlib.OptionAfterConnect(scanTimestamptzInUTC))
	maxOpen, maxIdle := sqlPoolLimits(settings)
	db.SetMaxOpenConns(maxOpen)
	db.SetMaxIdleConns(maxIdle)
	db.SetConnMaxLifetime(30 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)
	trackSQLPool(poolName(settings.PoolName, 1), db)
	return db, nil
}

// sqlPoolLimits maps pool Options onto database/sql. database/sql has no
// "min connections": MaxIdleConns is how many connections it may KEEP after
// use. Setting it to MinConns (2-4) made every burst above that close its
// extra connections on release and open new ones for the next request (a
// PostgreSQL backend fork plus TLS/auth each time). Idle connections are kept
// up to MaxConns and still reaped after five idle minutes (ConnMaxIdleTime),
// so a quiet pool shrinks on its own.
func sqlPoolLimits(settings Options) (maxOpen, maxIdle int) {
	maxConns := settings.MaxConns
	if maxConns <= 0 {
		maxConns = 16
	}
	return int(maxConns), int(maxConns)
}

func sqlConfig(databaseURL string, settings Options) (*pgx.ConnConfig, error) {
	if strings.TrimSpace(databaseURL) == "" {
		return nil, errors.New("database URL is required")
	}
	config, err := pgx.ParseConfig(databaseURL)
	if err != nil {
		return nil, err
	}
	setRuntimeTimeout(config.RuntimeParams, "statement_timeout", settings.StatementTimeout)
	setRuntimeTimeout(config.RuntimeParams, "lock_timeout", settings.LockTimeout)
	setRuntimeTimeout(config.RuntimeParams, "idle_in_transaction_session_timeout", settings.IdleTransactionTimeout)
	setSessionTimeZoneUTC(config.RuntimeParams)
	return config, nil
}
