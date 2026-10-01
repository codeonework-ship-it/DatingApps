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
	db := stdlib.OpenDB(*connConfig)
	maxConns := settings.MaxConns
	if maxConns <= 0 {
		maxConns = 16
	}
	minConns := settings.MinConns
	if minConns < 0 {
		minConns = 0
	}
	if minConns > maxConns {
		minConns = maxConns
	}
	db.SetMaxOpenConns(int(maxConns))
	db.SetMaxIdleConns(int(minConns))
	db.SetConnMaxLifetime(30 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)
	trackSQLPool(poolName(settings.PoolName, 1), db)
	return db, nil
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
	return config, nil
}
