package matching

import (
	"context"
	"fmt"
	"net/url"
	"os"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/postgresdata"
)

type nativeRecordingClient struct {
	recordingClient
	queries []string
	args    [][]any
	result  []map[string]any
}

func (c *nativeRecordingClient) QueryRows(_ context.Context, query string, args ...any) ([]map[string]any, error) {
	c.queries = append(c.queries, query)
	c.args = append(c.args, args)
	return c.result, nil
}

func nativeTestConfig() config.Config {
	return config.Config{MatchingSchema: "matching", MessagesTable: "messages"}
}

func TestLatestMessagesUsesOneBoundedProbePerMatch(t *testing.T) {
	matchA := "11111111-1111-4111-8111-111111111111"
	matchB := "22222222-2222-4222-8222-222222222222"
	client := &nativeRecordingClient{result: []map[string]any{
		{"match_id": matchA, "text": "latest A", "created_at": "2026-10-02T10:00:00Z"},
	}}
	repo := &DataRepository{db: client, cfg: nativeTestConfig()}

	got, err := repo.GetLatestMessagesByMatchIDs(context.Background(), []string{matchA, matchB, matchA, "not-a-uuid"})
	if err != nil {
		t.Fatal(err)
	}
	if client.lastParams != nil {
		t.Fatal("native client must not fall back to the unbounded filter query")
	}
	if len(client.queries) != 1 || !strings.Contains(client.queries[0], "LIMIT 1") || !strings.Contains(client.queries[0], "CROSS JOIN LATERAL") {
		t.Fatalf("expected one LATERAL ... LIMIT 1 query, got %q", client.queries)
	}
	if ids := client.args[0][0].([]string); !reflect.DeepEqual(ids, []string{matchA, matchB}) {
		t.Fatalf("ids = %v, want distinct well-formed ids", ids)
	}
	if got[matchA]["text"] != "latest A" || got[matchA]["matchId"] != matchA || got[matchA]["createdAt"] == nil {
		t.Fatalf("row not normalised like the filter path: %#v", got[matchA])
	}
	if _, ok := got[matchB]; ok {
		t.Fatal("a match without messages must have no preview")
	}
}

func TestUnreadCountsAreCountedInTheDatabase(t *testing.T) {
	matchA := "11111111-1111-4111-8111-111111111111"
	client := &nativeRecordingClient{result: []map[string]any{{"match_id": matchA, "unread": int64(3)}}}
	repo := &DataRepository{db: client, cfg: nativeTestConfig()}
	got, err := repo.GetUnreadCounts(context.Background(), []string{matchA}, "33333333-3333-4333-8333-333333333333")
	if err != nil {
		t.Fatal(err)
	}
	if got[matchA] != 3 || !strings.Contains(client.queries[0], "GROUP BY match_id") {
		t.Fatalf("got %v from %q", got, client.queries)
	}
}

func TestPreviewQueriesFallBackWithoutNativeClient(t *testing.T) {
	client := &recordingClient{}
	repo := &DataRepository{db: client, cfg: nativeTestConfig()}
	if _, err := repo.GetLatestMessagesByMatchIDs(context.Background(), []string{"11111111-1111-4111-8111-111111111111"}); err != nil {
		t.Fatal(err)
	}
	if client.lastParams == nil {
		t.Fatal("hosted (PostgREST) mode must keep the filter-based query")
	}
}

// Against a real database the native queries return exactly what the
// filter-based queries returned.
func TestNativePreviewsMatchFilterQueriesPostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL is not set")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	client, err := postgresdata.Open(ctx, dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	rows, err := client.QueryRows(ctx, `
		SELECT match_id::text AS match_id, MIN(sender_id::text) AS viewer
		FROM matching.messages GROUP BY match_id ORDER BY MAX(created_at) DESC LIMIT 25`)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) == 0 {
		t.Skip("no messages in this database")
	}
	ids := make([]string, 0, len(rows))
	for _, row := range rows {
		ids = append(ids, fmt.Sprint(row["match_id"]))
	}
	viewer := fmt.Sprint(rows[0]["viewer"])
	cfg := config.Config{MatchingSchema: "matching", MessagesTable: "messages"}
	native := &DataRepository{db: client, cfg: cfg}
	filter := &DataRepository{db: selectOnly{client}, cfg: cfg}

	gotLatest, err := native.GetLatestMessagesByMatchIDs(ctx, ids)
	if err != nil {
		t.Fatal(err)
	}
	wantLatest, err := filter.GetLatestMessagesByMatchIDs(ctx, ids)
	if err != nil {
		t.Fatal(err)
	}
	if len(gotLatest) != len(wantLatest) {
		t.Fatalf("native previews for %d matches, filter query for %d", len(gotLatest), len(wantLatest))
	}
	for id, want := range wantLatest {
		got := gotLatest[id]
		// Equal timestamps can tie; the newest time must agree.
		if fmt.Sprint(got["createdAt"]) != fmt.Sprint(want["createdAt"]) {
			t.Fatalf("match %s: native latest %v, filter latest %v", id, got, want)
		}
	}
	gotUnread, err := native.GetUnreadCounts(ctx, ids, viewer)
	if err != nil {
		t.Fatal(err)
	}
	wantUnread, err := filter.GetUnreadCounts(ctx, ids, viewer)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(gotUnread, wantUnread) {
		t.Fatalf("unread counts differ: native %v, filter %v", gotUnread, wantUnread)
	}
}

// selectOnly hides QueryRows so the repository takes the filter path.
type selectOnly struct{ c *postgresdata.Client }

func (s selectOnly) Select(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	return s.c.Select(ctx, schema, table, params)
}
func (s selectOnly) SelectRead(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	return s.c.SelectRead(ctx, schema, table, params)
}
func (s selectOnly) Insert(ctx context.Context, schema, table string, payload any) ([]map[string]any, error) {
	return s.c.Insert(ctx, schema, table, payload)
}
func (s selectOnly) Upsert(ctx context.Context, schema, table string, payload any, onConflict string) ([]map[string]any, error) {
	return s.c.Upsert(ctx, schema, table, payload, onConflict)
}
func (s selectOnly) Update(ctx context.Context, schema, table string, payload any, filters url.Values) ([]map[string]any, error) {
	return s.c.Update(ctx, schema, table, payload, filters)
}
func (s selectOnly) Delete(ctx context.Context, schema, table string, filters url.Values) ([]map[string]any, error) {
	return s.c.Delete(ctx, schema, table, filters)
}
