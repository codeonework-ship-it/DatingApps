package mobile

import (
	"net/http"
	"strings"
	"testing"
)

// TestAccountRootIsSelfScoped is the access-control guard for the whole
// lifecycle surface.
//
// pathOwnedByPrincipal allows any root it does not recognise, so a new route
// family is unprotected by default. These endpoints deactivate and erase
// accounts, which makes that default the difference between a self-service
// feature and a way to delete other people's accounts.
func TestAccountRootIsSelfScoped(t *testing.T) {
	const prefix = "/v1"
	const owner = "11111111-1111-1111-1111-111111111111"
	const other = "22222222-2222-2222-2222-222222222222"

	paths := []string{
		"/account/%s/lifecycle",
		"/account/%s/deactivate",
		"/account/%s/reactivate",
		"/account/%s/deletion",
		"/account/%s/export",
	}
	methods := []string{
		http.MethodGet, http.MethodPost, http.MethodDelete,
	}

	for _, pattern := range paths {
		ownPath := prefix + strings.Replace(pattern, "%s", owner, 1)
		otherPath := prefix + strings.Replace(pattern, "%s", other, 1)
		for _, method := range methods {
			if !pathOwnedByPrincipal(prefix, ownPath, method, owner) {
				t.Errorf("%s %s: owner must be allowed to act on their own account",
					method, ownPath)
			}
			if pathOwnedByPrincipal(prefix, otherPath, method, owner) {
				t.Errorf(
					"%s %s: a principal must not reach another member's account "+
						"lifecycle. pathOwnedByPrincipal allows unknown roots, so "+
						"\"account\" has to stay in selfRoots.",
					method, otherPath,
				)
			}
		}
	}
}

// TestAccountExportOmitsCredentialMaterial pins the export boundary.
//
// The payload is assembled from an explicit section list rather than a table
// dump precisely so credentials cannot drift into it. This asserts the query
// text itself, because the failure mode — a password hash leaving the system
// inside a member's own export — is not visible in a passing round trip.
func TestAccountExportOmitsCredentialMaterial(t *testing.T) {
	forbidden := []string{
		"password_hash",
		"auth_credentials",
		"access_token_hash",
		"refresh_token_hash",
		"recovery_code",
		"auth_sessions",
	}
	source := accountExportSectionSQL()
	lowered := strings.ToLower(source)
	for _, term := range forbidden {
		if strings.Contains(lowered, term) {
			t.Errorf(
				"account export must not read %q: an export is the member's own "+
					"record, not a route to credential material",
				term,
			)
		}
	}
	// The export is worthless if it reads nothing, so assert it still covers
	// the member's substantive data.
	for _, expected := range []string{"users", "photos", "matches", "messages"} {
		if !strings.Contains(lowered, expected) {
			t.Errorf("account export should still include %q data", expected)
		}
	}
}

func TestAccountExportUsesCurrentMatchingSchema(t *testing.T) {
	source := strings.ToLower(accountExportSectionSQL())
	for _, current := range []string{"user_id_1", "user_id_2", "matching.messages", "text"} {
		if !strings.Contains(source, current) {
			t.Errorf("account export must use current schema field %q", current)
		}
	}
	for _, stale := range []string{"user1_id", "user2_id", "unlock_state", "content,"} {
		if strings.Contains(source, stale) {
			t.Errorf("account export still references removed schema field %q", stale)
		}
	}
}
