package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// The member's language follows the account (093_member_locale.sql): the
// PATCH accepts a language[-REGION] tag or an empty string (device language),
// refuses anything else with 400, and the GET echoes what was stored.
func TestSettingsPatch_LocaleRoundTripAndValidation(t *testing.T) {
	const userID = "user-locale-1"
	installOperatorPrincipal(t, userID)
	server := newAppealsTestServer(t)
	defer server.Close()

	settingsOf := func(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
		t.Helper()
		return toMap(t, decodeJSONMap(t, rec.Body.Bytes())["settings"])
	}
	patch := func(t *testing.T, body string) *httptest.ResponseRecorder {
		t.Helper()
		req := httptest.NewRequest(http.MethodPatch, "/v1/settings/"+userID, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		return rec
	}
	get := func(t *testing.T) map[string]any {
		t.Helper()
		req := httptest.NewRequest(http.MethodGet, "/v1/settings/"+userID, nil)
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("GET settings code=%d body=%s", rec.Code, rec.Body.String())
		}
		return settingsOf(t, rec)
	}

	if got, present := get(t)["locale"]; !present || got != "" {
		t.Fatalf("fresh settings must expose an empty locale (device language), got %v present=%v", got, present)
	}

	for _, tag := range []string{"en-GB", "de", "pt", "ru"} {
		rec := patch(t, `{"locale":"`+tag+`"}`)
		if rec.Code != http.StatusOK {
			t.Fatalf("PATCH locale=%q code=%d body=%s", tag, rec.Code, rec.Body.String())
		}
		if got := stringValue(settingsOf(t, rec)["locale"]); got != tag {
			t.Fatalf("PATCH locale=%q echoed %q", tag, got)
		}
		if got := stringValue(get(t)["locale"]); got != tag {
			t.Fatalf("GET after PATCH locale=%q returned %q", tag, got)
		}
	}

	// Other settings ride along untouched and a locale-only patch keeps them.
	if rec := patch(t, `{"show_age":false,"theme":"dark"}`); rec.Code != http.StatusOK {
		t.Fatalf("PATCH unrelated fields code=%d body=%s", rec.Code, rec.Body.String())
	}
	if settings := get(t); settings["show_age"] != false || stringValue(settings["theme"]) != "dark" || stringValue(settings["locale"]) != "ru" {
		t.Fatalf("locale must survive an unrelated patch, got %v", settings)
	}

	for _, bad := range []string{`"EN-gb"`, `"english"`, `"de_DE"`, `"de-de"`, `"d"`, `"de-DEU"`, `"de-DE-x"`, `42`, `true`, `["de"]`} {
		rec := patch(t, `{"locale":`+bad+`,"show_age":true}`)
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("PATCH locale=%s code=%d, want 400; body=%s", bad, rec.Code, rec.Body.String())
		}
		settings := get(t)
		if got := stringValue(settings["locale"]); got != "ru" {
			t.Fatalf("rejected locale=%s must not change the stored value, got %q", bad, got)
		}
		if settings["show_age"] != false {
			t.Fatalf("a rejected patch must not apply its other fields, got %v", settings)
		}
	}

	// Empty string and null both return the member to the device language.
	for _, clear := range []string{`""`, `null`} {
		if rec := patch(t, `{"locale":"fr"}`); rec.Code != http.StatusOK {
			t.Fatalf("re-seed locale code=%d", rec.Code)
		}
		rec := patch(t, `{"locale":`+clear+`}`)
		if rec.Code != http.StatusOK {
			t.Fatalf("PATCH locale=%s code=%d body=%s", clear, rec.Code, rec.Body.String())
		}
		if got := stringValue(get(t)["locale"]); got != "" {
			t.Fatalf("PATCH locale=%s should clear the locale, got %q", clear, got)
		}
	}

	// Omitting the key leaves the stored locale alone.
	if rec := patch(t, `{"locale":"nl"}`); rec.Code != http.StatusOK {
		t.Fatalf("seed locale code=%d", rec.Code)
	}
	if rec := patch(t, `{"notify_likes":false}`); rec.Code != http.StatusOK {
		t.Fatalf("PATCH without locale code=%d", rec.Code)
	}
	if got := stringValue(get(t)["locale"]); got != "nl" {
		t.Fatalf("omitted locale must be preserved, got %q", got)
	}
}

func TestApplySettingsPatch_LocaleGuardMirrorsColumnCheck(t *testing.T) {
	base := defaultSettings("user-locale-2")
	base.Locale = "it"

	if got := applySettingsPatch(base, map[string]any{"locale": "pl"}).Locale; got != "pl" {
		t.Fatalf("valid tag not applied, got %q", got)
	}
	if got := applySettingsPatch(base, map[string]any{"locale": " es "}).Locale; got != "es" {
		t.Fatalf("tag should be trimmed, got %q", got)
	}
	if got := applySettingsPatch(base, map[string]any{"locale": ""}).Locale; got != "" {
		t.Fatalf("empty string should clear, got %q", got)
	}
	if got := applySettingsPatch(base, map[string]any{"locale": nil}).Locale; got != "" {
		t.Fatalf("null should clear, got %q", got)
	}
	if got := applySettingsPatch(base, map[string]any{"theme": "light"}).Locale; got != "it" {
		t.Fatalf("absent key should keep the stored locale, got %q", got)
	}
	for _, bad := range []any{"EN-gb", "de_DE", "deutsch", 7, true} {
		if got := applySettingsPatch(base, map[string]any{"locale": bad}).Locale; got != "it" {
			t.Fatalf("malformed locale %v must be ignored by the store guard, got %q", bad, got)
		}
	}
}
