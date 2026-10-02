package postgresdata

import (
	"context"
	"encoding/json"
	"math/big"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgtype"
)

// Regression: NUMERIC columns (billing_plans.monthly_price, coin_packages.price_usd,
// sos_alerts.latitude, ...) were rendered as "{499 -2 false finite true}" because
// pgtype.Numeric fell through to fmt.Sprint.
func TestNormalizeValue_NumericBecomesJSONNumber(t *testing.T) {
	cases := []struct {
		name string
		in   pgtype.Numeric
		want any
	}{
		{"price", pgtype.Numeric{Int: big.NewInt(499), Exp: -2, Valid: true}, 4.99},
		{"zero", pgtype.Numeric{Int: big.NewInt(0), Exp: 0, Valid: true}, 0.0},
		{"negative", pgtype.Numeric{Int: big.NewInt(-12345), Exp: -4, Valid: true}, -1.2345},
		{"null", pgtype.Numeric{}, nil},
		{"nan", pgtype.Numeric{NaN: true, Valid: true}, "NaN"},
		{"infinity", pgtype.Numeric{InfinityModifier: pgtype.Infinity, Valid: true}, "Infinity"},
	}
	for _, tc := range cases {
		got := normalizeValue(tc.in)
		if got != tc.want {
			t.Fatalf("%s: normalizeValue() = %#v, want %#v", tc.name, got, tc.want)
		}
		if _, err := json.Marshal(map[string]any{"v": got}); err != nil {
			t.Fatalf("%s: value is not JSON-encodable: %v", tc.name, err)
		}
	}
}

func TestQueryMapsReturnsNumericAsNumberPostgres(t *testing.T) {
	databaseURL := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	ctx := context.Background()
	client, err := Open(ctx, databaseURL, Options{MaxConns: 1, MinConns: 0, PoolName: "postgresdata/numeric_test"})
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	rows, err := client.queryMaps(ctx, "SELECT 4.99::numeric(10,2) AS price, NULL::numeric AS missing, 12.345678::numeric AS latitude")
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 1 {
		t.Fatalf("rows=%d", len(rows))
	}
	if rows[0]["price"] != 4.99 || rows[0]["latitude"] != 12.345678 || rows[0]["missing"] != nil {
		t.Fatalf("numeric row = %#v", rows[0])
	}
}
