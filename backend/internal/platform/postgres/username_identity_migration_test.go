package postgres

import "testing"

func TestUsernameIdentityMigrationEnforcesCanonicalIdentity(t *testing.T) {
	script050 := mustReadMigrationScript(t, "050_username_password_identity.sql")

	assertContainsAll(t, script050,
		"add column if not exists username text",
		"alter column username set not null",
		"alter column phone_number drop not null",
		"on user_management.users (lower(username))",
		"users_username_format_check",
		"prevent_username_change",
		"trg_users_username_immutable",
	)
	assertNotContainsAny(t, script050,
		"password text",
		"password_hash",
		"drop table user_management.users",
	)
}
