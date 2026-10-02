package mobile

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"reflect"
	"strings"
	"testing"
	"time"
)

var testListSpec = adminListSpec{
	DefaultLimit: 50, MaxLimit: 200,
	Sorts: map[string]string{
		"created_at": "created_at",
		"severity":   "CASE severity WHEN 'high' THEN 1 ELSE 0 END {dir}, created_at DESC",
	},
	DefaultSort: "created_at", TieBreak: "id {dir}",
}

func listRequest(query string) *http.Request {
	return httptest.NewRequest(http.MethodGet, "/v1/admin/things?"+query, nil)
}

func TestParseAdminListParams(t *testing.T) {
	day := func(s string) time.Time {
		parsed, _ := time.Parse("2006-01-02", s)
		return parsed.UTC()
	}
	longQ := strings.Repeat("é", 250)
	cases := []struct {
		name  string
		query string
		spec  adminListSpec
		want  adminListParams
	}{
		{name: "defaults", query: "",
			want: adminListParams{Limit: 50, Offset: 0, Sort: "created_at", Order: "desc"}},
		{name: "limit within range", query: "limit=7",
			want: adminListParams{Limit: 7, Sort: "created_at", Order: "desc"}},
		{name: "limit above max clamps", query: "limit=1000",
			want: adminListParams{Limit: 200, Sort: "created_at", Order: "desc"}},
		{name: "limit zero uses default", query: "limit=0",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "limit negative uses default", query: "limit=-4",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "limit malformed uses default", query: "limit=ten",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "offset", query: "offset=40",
			want: adminListParams{Limit: 50, Offset: 40, Sort: "created_at", Order: "desc"}},
		{name: "offset negative is zero", query: "offset=-3",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "offset capped", query: "offset=250000",
			want: adminListParams{Limit: 50, Offset: adminListMaxOffset, Sort: "created_at", Order: "desc"}},
		{name: "offset malformed is zero", query: "offset=x",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "q trimmed", query: "q=" + url.QueryEscape("  rose  "),
			want: adminListParams{Limit: 50, Q: "rose", Sort: "created_at", Order: "desc"}},
		{name: "q truncated to 200 runes", query: "q=" + url.QueryEscape(longQ),
			want: adminListParams{Limit: 50, Q: strings.Repeat("é", 200), Sort: "created_at", Order: "desc"}},
		{name: "allowed sort", query: "sort=severity",
			want: adminListParams{Limit: 50, Sort: "severity", Order: "desc"}},
		{name: "sort is case-insensitive", query: "sort=SEVERITY",
			want: adminListParams{Limit: 50, Sort: "severity", Order: "desc"}},
		{name: "unknown sort falls back", query: "sort=" + url.QueryEscape("created_at; DROP TABLE x"),
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "order asc", query: "order=ASC",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "asc"}},
		{name: "unknown order falls back", query: "order=sideways",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc"}},
		{name: "spec default order asc", query: "",
			spec: adminListSpec{DefaultLimit: 10, MaxLimit: 20, Sorts: map[string]string{"t": "t"}, DefaultSort: "t", DefaultOrder: "asc"},
			want: adminListParams{Limit: 10, Sort: "t", Order: "asc"}},
		{name: "explicit desc overrides asc default", query: "order=desc",
			spec: adminListSpec{DefaultLimit: 10, MaxLimit: 20, Sorts: map[string]string{"t": "t"}, DefaultSort: "t", DefaultOrder: "asc"},
			want: adminListParams{Limit: 10, Sort: "t", Order: "desc"}},
		{name: "from and to are UTC days, to exclusive next day", query: "from=2026-09-01&to=2026-09-30",
			want: adminListParams{Limit: 50, Sort: "created_at", Order: "desc", From: day("2026-09-01"), To: day("2026-10-01")}},
		{name: "spec without sorts", query: "sort=anything",
			spec: adminListSpec{DefaultLimit: 5, MaxLimit: 5},
			want: adminListParams{Limit: 5, Sort: "", Order: "desc"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			spec := testListSpec
			if tc.spec.DefaultLimit != 0 {
				spec = tc.spec
			}
			got, err := parseAdminListParams(listRequest(tc.query), spec)
			if err != nil {
				t.Fatalf("parse: %v", err)
			}
			got.spec = adminListSpec{}
			if !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got %+v\nwant %+v", got, tc.want)
			}
		})
	}
}

func TestParseAdminListParamsRejectsBadDates(t *testing.T) {
	for _, query := range []string{"from=2026-13-01", "to=yesterday", "from=2026-09-01T00:00:00Z", "to=01-09-2026"} {
		if _, err := parseAdminListParams(listRequest(query), testListSpec); !errors.Is(err, errAdminListBadDate) {
			t.Fatalf("%s: err=%v, want errAdminListBadDate", query, err)
		}
	}
}

func TestEscapeILIKE(t *testing.T) {
	cases := map[string]string{
		"plain":     "plain",
		"50%":       `50\%`,
		"a_b":       `a\_b`,
		`back\path`: `back\\path`,
		`%_\`:       `\%\_\\`,
		"":          "",
	}
	for in, want := range cases {
		if got := escapeILIKE(in); got != want {
			t.Fatalf("escapeILIKE(%q)=%q, want %q", in, got, want)
		}
	}
}

func TestSQLFilterBuildsNumberedArguments(t *testing.T) {
	from := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	to := time.Date(2026, 9, 3, 0, 0, 0, 0, time.UTC)
	const member = "6F1C2B8E-1D2A-4C3B-9E8F-0A1B2C3D4E5F"
	cases := []struct {
		name      string
		build     func(*sqlFilter)
		wantWhere string
		wantArgs  []any
	}{
		{name: "empty", build: func(*sqlFilter) {}, wantWhere: "", wantArgs: nil},
		{name: "blank values are skipped", build: func(f *sqlFilter) {
			f.Eq("status", "  ").Search("", "name").UUIDEq("user_id", "")
		}, wantWhere: "", wantArgs: nil},
		{name: "eq and search share numbering", build: func(f *sqlFilter) {
			f.Eq("status", " open ").Search("50%_off", "name", "description")
		},
			wantWhere: ` WHERE status = $1 AND (name ILIKE $2 ESCAPE '\' OR description ILIKE $2 ESCAPE '\')`,
			wantArgs:  []any{"open", `%50\%\_off%`}},
		{name: "time range", build: func(f *sqlFilter) {
			f.TimeRange("created_at", adminListParams{From: from, To: to})
		},
			wantWhere: " WHERE created_at >= $1 AND created_at < $2",
			wantArgs:  []any{from, to}},
		{name: "uuid lowercased", build: func(f *sqlFilter) { f.UUIDEq("user_id", member) },
			wantWhere: " WHERE user_id = $1", wantArgs: []any{strings.ToLower(member)}},
		{name: "malformed uuid matches nothing", build: func(f *sqlFilter) { f.UUIDEq("user_id", "x' OR 1=1") },
			wantWhere: " WHERE FALSE", wantArgs: nil},
		{name: "raw clause reusing one argument", build: func(f *sqlFilter) {
			arg := f.Arg("m")
			f.Where("(user_id = " + arg + " OR actor_user_id = " + arg + ")")
		},
			wantWhere: " WHERE (user_id = $1 OR actor_user_id = $1)", wantArgs: []any{"m"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			f := newSQLFilter()
			tc.build(f)
			if got := f.SQL(); got != tc.wantWhere {
				t.Fatalf("SQL()=%q, want %q", got, tc.wantWhere)
			}
			if got := f.Args(); !reflect.DeepEqual(got, tc.wantArgs) {
				t.Fatalf("Args()=%#v, want %#v", got, tc.wantArgs)
			}
		})
	}
	if got := newSQLFilter("deleted_at IS NULL").Conditions(); got != "deleted_at IS NULL" {
		t.Fatalf("seeded Conditions()=%q", got)
	}
	if got := newSQLFilter().Conditions(); got != "TRUE" {
		t.Fatalf("empty Conditions()=%q", got)
	}
}

func TestSQLFilterNeverInterpolatesInput(t *testing.T) {
	malicious := "x'; DROP TABLE audit.security_events; --"
	f := newSQLFilter()
	f.Eq("event_type", malicious).Search(malicious, "event_type")
	if strings.Contains(f.SQL(), "DROP") {
		t.Fatalf("filter interpolated input: %s", f.SQL())
	}
}

func TestAdminListOrderBy(t *testing.T) {
	cases := []struct {
		name  string
		query string
		spec  adminListSpec
		want  string
	}{
		{name: "default desc with tiebreak", query: "", spec: testListSpec, want: "created_at DESC, id DESC"},
		{name: "asc", query: "order=asc", spec: testListSpec, want: "created_at ASC, id ASC"},
		{name: "dir placeholder", query: "sort=severity&order=desc", spec: testListSpec,
			want: "CASE severity WHEN 'high' THEN 1 ELSE 0 END DESC, created_at DESC, id DESC"},
		{name: "no tiebreak", query: "order=asc",
			spec: adminListSpec{DefaultLimit: 1, MaxLimit: 1, Sorts: map[string]string{"t": "t {dir} NULLS LAST"}, DefaultSort: "t"},
			want: "t ASC NULLS LAST"},
		{name: "no sorts", query: "", spec: adminListSpec{DefaultLimit: 1, MaxLimit: 1}, want: ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			p, err := parseAdminListParams(listRequest(tc.query), tc.spec)
			if err != nil {
				t.Fatal(err)
			}
			if got := p.OrderBy(); got != tc.want {
				t.Fatalf("OrderBy()=%q, want %q", got, tc.want)
			}
		})
	}
}

func TestAdminListPageAndRange(t *testing.T) {
	p, err := parseAdminListParams(listRequest("limit=20&offset=40&from=2026-09-01&to=2026-09-01"), testListSpec)
	if err != nil {
		t.Fatal(err)
	}
	if got := p.LimitOffset(); got != " LIMIT 20 OFFSET 40" {
		t.Fatalf("LimitOffset()=%q", got)
	}
	resp := p.Page(map[string]any{"items": []int{1}}, 77)
	if resp["total"] != 77 || resp["limit"] != 20 || resp["offset"] != 40 || resp["items"] == nil {
		t.Fatalf("Page()=%v", resp)
	}
	for _, tc := range []struct {
		at   time.Time
		want bool
	}{
		{time.Date(2026, 8, 31, 23, 59, 59, 0, time.UTC), false},
		{time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC), true},
		{time.Date(2026, 9, 1, 23, 59, 59, 0, time.UTC), true},
		{time.Date(2026, 9, 2, 0, 0, 0, 0, time.UTC), false},
	} {
		if got := p.InRange(tc.at); got != tc.want {
			t.Fatalf("InRange(%s)=%v", tc.at, got)
		}
	}
}

func TestNormalizeAdminSQLValue(t *testing.T) {
	at := time.Date(2026, 9, 1, 10, 0, 0, 5, time.FixedZone("IST", 19800))
	cases := []struct {
		value  any
		dbType string
		want   any
	}{
		{nil, "TEXT", nil},
		{at, "TIMESTAMPTZ", "2026-09-01T04:30:00.000000005Z"},
		{int64(7), "INT8", float64(7)},
		{"12.50", "NUMERIC", 12.5},
		{"abc", "TEXT", "abc"},
		{[]byte(`{"a":1}`), "JSONB", map[string]any{"a": float64(1)}},
		{[]byte(`raw`), "BYTEA", "raw"},
		{true, "BOOL", true},
	}
	for _, tc := range cases {
		if got := normalizeAdminSQLValue(tc.value, tc.dbType); !reflect.DeepEqual(got, tc.want) {
			t.Fatalf("normalize(%#v,%s)=%#v, want %#v", tc.value, tc.dbType, got, tc.want)
		}
	}
}

func TestAdminUUIDParam(t *testing.T) {
	const id = "6F1C2B8E-1D2A-4C3B-9E8F-0A1B2C3D4E5F"
	if got, err := adminUUIDParam(listRequest("user_id="+id), "user_id"); err != nil || got != strings.ToLower(id) {
		t.Fatalf("valid: %q %v", got, err)
	}
	if got, err := adminUUIDParam(listRequest(""), "user_id"); err != nil || got != "" {
		t.Fatalf("absent: %q %v", got, err)
	}
	if _, err := adminUUIDParam(listRequest("user_id=nope"), "user_id"); err == nil {
		t.Fatal("malformed uuid accepted")
	}
}

func TestFilterActivityMapsAppliesContract(t *testing.T) {
	const member = "11111111-1111-4111-8111-111111111111"
	rows := []map[string]any{ // newest first, as the older path returns them
		{"id": "4", "action": "GET /v1/x", "domain": "api_request", "user_id": member, "created_at": "2026-09-04T10:00:00Z"},
		{"id": "3", "action": "appeal.resolved", "domain": "", "actor": member, "created_at": "2026-09-03T10:00:00Z"},
		{"id": "2", "action": "gift.sent", "domain": "gifts", "user_id": "22222222-2222-4222-8222-222222222222", "created_at": "2026-09-02T10:00:00Z"},
		{"id": "1", "action": "appeal.submitted", "domain": "mobile_bff", "user_id": member, "created_at": "2026-09-01T10:00:00Z"},
	}
	ids := func(items []map[string]any) string {
		out := []string{}
		for _, item := range items {
			out = append(out, toString(item["id"]))
		}
		return strings.Join(out, ",")
	}
	cases := []struct {
		name      string
		query     string
		filter    activityListFilter
		wantIDs   string
		wantTotal int
	}{
		{name: "all", wantIDs: "4,3,2,1", wantTotal: 4},
		{name: "exclude api_request", filter: activityListFilter{ExcludeDomains: []string{"api_request"}}, wantIDs: "3,2,1", wantTotal: 3},
		{name: "member matches user or actor", filter: activityListFilter{Member: member}, wantIDs: "4,3,1", wantTotal: 3},
		{name: "empty domain means mobile_bff", filter: activityListFilter{EventDomain: "mobile_bff"}, wantIDs: "3,1", wantTotal: 2},
		{name: "q over name", query: "q=APPEAL", wantIDs: "3,1", wantTotal: 2},
		{name: "date range", query: "from=2026-09-02&to=2026-09-03", wantIDs: "3,2", wantTotal: 2},
		{name: "page", query: "limit=2&offset=1", wantIDs: "3,2", wantTotal: 4},
		{name: "ascending", query: "order=asc&limit=2", wantIDs: "1,2", wantTotal: 4},
		{name: "offset past end", query: "offset=10", wantIDs: "", wantTotal: 4},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			p, err := parseAdminListParams(listRequest(tc.query), adminActivitiesSpec)
			if err != nil {
				t.Fatal(err)
			}
			page, total := filterActivityMaps(rows, tc.filter, p)
			if got := ids(page); got != tc.wantIDs || total != tc.wantTotal {
				t.Fatalf("ids=%q total=%d, want %q/%d", got, total, tc.wantIDs, tc.wantTotal)
			}
		})
	}
}

func TestParseActivityListFilter(t *testing.T) {
	f, err := parseActivityListFilter(listRequest("exclude_domain=api_request,gifts&exclude_domain=gifts&event_name=x"))
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(f.ExcludeDomains, []string{"api_request", "gifts"}) || f.EventName != "x" {
		t.Fatalf("filter=%+v", f)
	}
	for _, key := range []string{"user_id", "actor_user_id", "member"} {
		if _, err := parseActivityListFilter(listRequest(key + "=not-a-uuid")); err == nil {
			t.Fatalf("%s accepted a malformed uuid", key)
		}
	}
}
