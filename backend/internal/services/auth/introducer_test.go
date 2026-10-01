package auth

import (
	"context"
	"database/sql"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func TestIntroducerSignupValidation(t *testing.T) {
	r := &PostgresRepository{}
	for _, v := range [][2]string{{"A", "1990-01-01"}, {"A Friend", "2015-01-01"}, {"A Friend", "not-a-date"}, {"A Friend", "1900-01-01"}} {
		response, err := r.SignupIntroducer(context.Background(), "friend_test", "Password123", v[0], v[1])
		if err != nil || response["success"] != false {
			t.Fatalf("accepted invalid basics %v", v)
		}
	}
}
func TestIntroducerAtomicSignupAndLoginPostgres(t *testing.T) {
	dsn := os.Getenv("PROFILE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("PROFILE_TEST_DATABASE_URL not set")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	r := &PostgresRepository{db: db}
	ctx := context.Background()
	username := "friend_" + strings.ReplaceAll(uuid.NewString()[:8], "-", "")
	result, err := r.SignupIntroducer(ctx, username, "Password123!", "Sam Friend", "1990-05-09")
	if err != nil || result["success"] != true || result["account_kind"] != "introducer" {
		t.Fatalf("signup: %v %v", result, err)
	}
	id := result["user_id"].(string)
	defer func() {
		_, _ = db.Exec(`DELETE FROM user_management.auth_credentials WHERE user_id=$1`, id)
		_, _ = db.Exec(`DELETE FROM user_management.users WHERE id=$1`, id)
	}()
	var kind string
	var gender sql.NullString
	var completion, drafts, photos int
	err = db.QueryRow(`SELECT account_kind,gender,profile_completion,(SELECT count(*) FROM user_management.profile_drafts WHERE user_id=u.id),(SELECT count(*) FROM user_management.photos WHERE user_id=u.id) FROM user_management.users u WHERE id=$1`, id).Scan(&kind, &gender, &completion, &drafts, &photos)
	if err != nil || kind != "introducer" || gender.Valid || completion != 0 || drafts != 0 || photos != 0 {
		t.Fatalf("unexpected dating data %s %v %d %d %d: %v", kind, gender, completion, drafts, photos, err)
	}
	login, err := r.Login(ctx, username, "Password123!")
	if err != nil || login["account_kind"] != "introducer" || login["user_id"] != id {
		t.Fatalf("login: %v", err)
	}
	duplicate, err := r.SignupIntroducer(ctx, username, "Password123!", "Sam Friend", "1990-05-09")
	if err != nil || duplicate["success"] != false {
		t.Fatal("duplicate account accepted")
	}
}
