package matching

import (
	"context"
	"net/url"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

// recordingClient captures the query a repository issues so a test can assert
// on the filter itself. Discovery media visibility is a safety invariant, and
// the only way to check it without a live database is to inspect the query.
type recordingClient struct {
	lastSchema string
	lastTable  string
	lastParams url.Values
	rows       []map[string]any
}

func (c *recordingClient) Select(
	_ context.Context, schema, table string, params url.Values,
) ([]map[string]any, error) {
	c.lastSchema, c.lastTable = schema, table
	c.lastParams = params
	return c.rows, nil
}

func (c *recordingClient) SelectRead(
	ctx context.Context, schema, table string, params url.Values,
) ([]map[string]any, error) {
	return c.Select(ctx, schema, table, params)
}

func (c *recordingClient) Insert(
	context.Context, string, string, any,
) ([]map[string]any, error) {
	return nil, nil
}

func (c *recordingClient) Upsert(
	context.Context, string, string, any, string,
) ([]map[string]any, error) {
	return nil, nil
}

func (c *recordingClient) Update(
	context.Context, string, string, any, url.Values,
) ([]map[string]any, error) {
	return nil, nil
}

func (c *recordingClient) Delete(
	context.Context, string, string, url.Values,
) ([]map[string]any, error) {
	return nil, nil
}

// TestGetUserPhotos_ExcludesQuarantinedMediaFromDiscovery guards FRD PROF-011
// ("public quarantine reads fail") and the stated product principle that no
// quarantined media appears in public discovery.
//
// Moderation status and lifecycle status are independent columns. A photo that
// was approved and later quarantined — by a rescan, a report, or an operator
// decision — still carries moderation_status='approved' while its lifecycle
// moves to 'quarantined'. Discovery previously filtered on the moderation
// decision alone, so that photo went back into the public deck. The public
// profile read already required both conditions; the two surfaces disagreed.
func TestGetUserPhotos_ExcludesQuarantinedMediaFromDiscovery(t *testing.T) {
	client := &recordingClient{}
	repo := &DataRepository{
		db:  client,
		cfg: config.Config{UserSchema: "user_management", PhotosTable: "photos"},
	}

	if _, err := repo.GetUserPhotos(
		context.Background(), []string{"11111111-1111-1111-1111-111111111111"},
	); err != nil {
		t.Fatalf("GetUserPhotos returned an error: %v", err)
	}

	// Params are normalised to snake_case for snake_case schemas, so assert on
	// either spelling rather than pinning the normalisation step.
	lifecycle := client.lastParams.Get("lifecycleStatus")
	if lifecycle == "" {
		lifecycle = client.lastParams.Get("lifecycle_status")
	}
	if lifecycle != "eq.active" {
		t.Fatalf(
			"discovery must restrict media to the active lifecycle; got %q. "+
				"Without it an approved-then-quarantined photo is served into "+
				"the public deck.",
			lifecycle,
		)
	}

	// The moderation filter must survive alongside it: the two conditions are
	// complementary, and dropping either one reopens a different hole.
	moderation := client.lastParams.Get("moderationStatus")
	if moderation == "" {
		moderation = client.lastParams.Get("moderation_status")
	}
	if moderation != "eq.approved" {
		t.Fatalf("discovery must still require approved moderation; got %q", moderation)
	}

	deleted := client.lastParams.Get("deletedAt")
	if deleted == "" {
		deleted = client.lastParams.Get("deleted_at")
	}
	if deleted != "is.null" {
		t.Fatalf("discovery must still exclude deleted media; got %q", deleted)
	}
}

// TestListActiveUsers_ExcludesBannedMembers guards FRD SAFE-004: a ban must
// take effect everywhere, not only on the banned member's own session.
func TestListActiveUsers_ExcludesBannedMembers(t *testing.T) {
	client := &recordingClient{}
	repo := &DataRepository{
		db:  client,
		cfg: config.Config{UserSchema: "user_management", UsersTable: "users"},
	}

	if _, err := repo.ListActiveUsers(context.Background(), 10); err != nil {
		t.Fatalf("ListActiveUsers returned an error: %v", err)
	}

	banned := client.lastParams.Get("isBanned")
	if banned == "" {
		banned = client.lastParams.Get("is_banned")
	}
	if banned != "eq.false" {
		t.Fatalf(
			"discovery must exclude banned members; got %q. Banning writes "+
				"is_banned and revokes sessions but leaves is_active true, so "+
				"without this filter a banned member stays in the deck.",
			banned,
		)
	}
}

// TestDropSuspendedUsers_KeepsServedSuspensions checks the disjunction that the
// filter API cannot express: an elapsed suspension must restore visibility,
// while an active or indefinite one must not.
func TestDropSuspendedUsers_KeepsServedSuspensions(t *testing.T) {
	past := time.Now().Add(-24 * time.Hour).UTC().Format(time.RFC3339)
	future := time.Now().Add(24 * time.Hour).UTC().Format(time.RFC3339)

	rows := []map[string]any{
		{"id": "never-suspended"},
		{"id": "served", "suspendedAt": past, "suspendedUntil": past},
		{"id": "active-suspension", "suspendedAt": past, "suspendedUntil": future},
		{"id": "indefinite", "suspendedAt": past},
		{"id": "unparseable", "suspendedAt": past, "suspendedUntil": "not-a-time"},
	}

	kept := map[string]bool{}
	for _, row := range dropSuspendedUsers(append([]map[string]any(nil), rows...)) {
		kept[toString(row["id"])] = true
	}

	for _, id := range []string{"never-suspended", "served"} {
		if !kept[id] {
			t.Errorf("%s should be discoverable", id)
		}
	}
	for _, id := range []string{"active-suspension", "indefinite", "unparseable"} {
		if kept[id] {
			t.Errorf("%s must not be discoverable", id)
		}
	}
}

// TestListActiveUsers_ExcludesSelfDeactivatedMembers guards the pause path.
//
// Self-deactivation cannot clear is_active: that column gates login and bearer
// validation, so using it would lock the member out of the endpoint that
// reverses the pause. Visibility is withdrawn by deactivated_at instead, and
// discovery has to honour it or a paused member stays in the deck.
func TestListActiveUsers_ExcludesSelfDeactivatedMembers(t *testing.T) {
	client := &recordingClient{}
	repo := &DataRepository{
		db:  client,
		cfg: config.Config{UserSchema: "user_management", UsersTable: "users"},
	}

	if _, err := repo.ListActiveUsers(context.Background(), 10); err != nil {
		t.Fatalf("ListActiveUsers returned an error: %v", err)
	}

	deactivated := client.lastParams.Get("deactivatedAt")
	if deactivated == "" {
		deactivated = client.lastParams.Get("deactivated_at")
	}
	if deactivated != "is.null" {
		t.Fatalf(
			"discovery must exclude self-deactivated members; got %q. "+
				"Deactivation intentionally leaves is_active set so the member "+
				"can sign back in, so this is the only filter hiding them.",
			deactivated,
		)
	}
}
