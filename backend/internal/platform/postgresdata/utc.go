package postgresdata

import (
	"context"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

// API timestamps are UTC (API-05). Two things otherwise leaked the database
// server's local offset (e.g. "+05:30") into JSON:
//
//   - pgx decodes timestamptz into time.Local, and encoding/json then writes
//     that offset for every time.Time a handler returns;
//   - SQL that renders timestamptz as text (::text, to_json, json_build_object)
//     uses the session TimeZone, which defaults to the server's zone.
//
// Every connection opened through this package therefore runs with
// TimeZone=UTC (unless the database URL sets one explicitly) and decodes
// timestamptz in UTC.

func setSessionTimeZoneUTC(params map[string]string) {
	for key := range params {
		if strings.EqualFold(key, "timezone") {
			return
		}
	}
	params["timezone"] = "UTC"
}

// scanTimestamptzInUTC registers a timestamptz codec that returns UTC times.
func scanTimestamptzInUTC(_ context.Context, conn *pgx.Conn) error {
	conn.TypeMap().RegisterType(&pgtype.Type{
		Name:  "timestamptz",
		OID:   pgtype.TimestamptzOID,
		Codec: &pgtype.TimestamptzCodec{ScanLocation: time.UTC},
	})
	return nil
}
