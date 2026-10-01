package mobile

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"testing"
)

// specPathBlocks splits the OpenAPI paths section into one text block per path,
// so a test can assert on what a specific endpoint documents.
func specPathBlocks(t *testing.T) map[string]string {
	t.Helper()

	raw, err := os.ReadFile(
		filepath.Join("..", "..", "platform", "docs", "openapi.yaml"),
	)
	if err != nil {
		t.Fatalf("read openapi.yaml: %v", err)
	}

	blocks := map[string]string{}
	var current string
	var builder strings.Builder
	inPaths := false

	flush := func() {
		if current != "" {
			blocks[normalisePath(current)] = builder.String()
		}
		builder.Reset()
	}

	for _, line := range strings.Split(string(raw), "\n") {
		if strings.HasPrefix(line, "paths:") {
			inPaths = true
			continue
		}
		if !inPaths {
			continue
		}
		if len(line) > 0 && line[0] != ' ' && line[0] != '#' {
			break // left the paths block
		}
		if strings.HasPrefix(line, "  /") && !strings.HasPrefix(line, "   ") {
			flush()
			current = strings.TrimSuffix(strings.TrimSpace(line), ":")
			continue
		}
		builder.WriteString(line)
		builder.WriteString("\n")
	}
	flush()
	return blocks
}

// idempotentRoutes asks the server itself which routes the middleware treats as
// idempotent, rather than restating the rule and letting the two drift.
func idempotentRoutes(t *testing.T, server *Server) []string {
	t.Helper()

	registered := registeredAPIRoutes(t, server)
	var idempotent []string
	for route, methods := range registered {
		for _, method := range methods {
			// The matcher works on concrete paths; the normalised "{}" segments
			// stand in for real ids and do not affect the prefix/suffix rules.
			probe := httptest.NewRequest(method, strings.ReplaceAll(route, "{}", "x"), nil)
			if server.shouldApplyIdempotency(probe) {
				idempotent = append(idempotent, method+" "+route)
				break
			}
		}
	}
	sort.Strings(idempotent)
	return idempotent
}

// Every endpoint that replays a cached response must say so, otherwise a client
// cannot know that retrying is safe — which is the entire point of the header.
func TestOpenAPI_IdempotentRoutesDocumentTheirKey(t *testing.T) {
	server := newContractTestServer(t)
	blocks := specPathBlocks(t)

	routes := idempotentRoutes(t, server)
	if len(routes) == 0 {
		t.Fatal("no idempotent routes detected; the matcher or the walker changed")
	}

	var undocumented []string
	for _, entry := range routes {
		parts := strings.SplitN(entry, " ", 2)
		block, ok := blocks[parts[1]]
		if !ok {
			undocumented = append(undocumented, entry+" (path absent from spec)")
			continue
		}
		if !strings.Contains(block, "Idempotency-Key") {
			undocumented = append(undocumented, entry+" (no Idempotency-Key parameter)")
		}
	}

	if len(undocumented) > 0 {
		t.Fatalf(
			"%d of %d idempotent routes do not document Idempotency-Key:\n  %s",
			len(undocumented), len(routes), strings.Join(undocumented, "\n  "))
	}
}

var aliasRoutePattern = regexp.MustCompile(
	`v1\.(Get|Post|Put|Patch|Delete)\("([^"]*)", s\.withAliasDeprecation\("([^"]*)"`,
)

// aliasRoutes reads the alias registrations straight from the router source, so
// adding one without documenting it fails here.
func aliasRoutes(t *testing.T) map[string]string {
	t.Helper()

	raw, err := os.ReadFile("server.go")
	if err != nil {
		t.Fatalf("read server.go: %v", err)
	}

	routes := map[string]string{}
	for _, match := range aliasRoutePattern.FindAllStringSubmatch(string(raw), -1) {
		routes[normalisePath("/v1"+match[2])] = match[3]
	}
	return routes
}

// A deprecated endpoint that is not marked deprecated in the specification is
// invisible to every client generator and linter, which is exactly the audience
// the Sunset header is meant to reach.
func TestOpenAPI_AliasRoutesAreMarkedDeprecated(t *testing.T) {
	blocks := specPathBlocks(t)
	aliases := aliasRoutes(t)

	if len(aliases) == 0 {
		t.Fatal("no alias routes detected; the registration pattern changed")
	}

	var problems []string
	for route, successor := range aliases {
		block, ok := blocks[route]
		if !ok {
			problems = append(problems, route+" (path absent from spec)")
			continue
		}
		if !strings.Contains(block, "deprecated: true") {
			problems = append(problems, route+" (not marked deprecated)")
		}
		if !strings.Contains(block, successor) {
			problems = append(problems, route+" (does not name successor "+successor+")")
		}
	}
	sort.Strings(problems)

	if len(problems) > 0 {
		t.Fatalf(
			"%d alias documentation problems across %d alias routes:\n  %s",
			len(problems), len(aliases), strings.Join(problems, "\n  "))
	}
}

// The alias wrapper is what actually emits the headers; assert the behaviour as
// well as the documentation.
func TestAliasRoutes_EmitDeprecationHeaders(t *testing.T) {
	server := newContractTestServer(t)

	handler := server.withAliasDeprecation(
		"/v1/matches/{matchID}/quest-workflow",
		func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) },
	)

	rec := httptest.NewRecorder()
	handler(rec, httptest.NewRequest(http.MethodGet, "/v1/matches/m-1/quests", nil))

	if got := rec.Header().Get("Deprecation"); got != "true" {
		t.Errorf("Deprecation header = %q, want \"true\"", got)
	}
	if got := rec.Header().Get("Sunset"); got != aliasRouteSunset {
		t.Errorf("Sunset header = %q, want %q", got, aliasRouteSunset)
	}
	if got := rec.Header().Get("Link"); !strings.Contains(got, `rel="successor-version"`) {
		t.Errorf("Link header = %q, want a successor-version relation", got)
	}
}

// TestOpenAPI_UnmodelledPayloadsDoNotGrow ratchets down the endpoints whose
// response body is still an open object.
//
// The 61 paths added when the router and the specification were reconciled were
// generated, so their bodies started as "any object at all". Those now point at
// SuccessEnvelope, which at least documents the correlation_id that writeJSON
// guarantees on every response — but an envelope is not a payload model.
//
// The remainder has to be modelled per endpoint by reading each handler.
// Guessing shapes would be worse than an honest placeholder: a client generator
// will happily produce typed bindings from a wrong schema. This test stops the
// count regressing while that work proceeds.
func TestOpenAPI_UnmodelledPayloadsDoNotGrow(t *testing.T) {
	raw, err := os.ReadFile(
		filepath.Join("..", "..", "platform", "docs", "openapi.yaml"),
	)
	if err != nil {
		t.Fatalf("read openapi.yaml: %v", err)
	}

	open := strings.Count(string(raw), "additionalProperties: true")

	// Baseline after routing the generated bodies through SuccessEnvelope.
	// Lower this as endpoints get real schemas; never raise it.
	const baseline = 35

	if open > baseline {
		t.Fatalf(
			"open response/request objects grew to %d (baseline %d); "+
				"model the payload instead of widening the schema",
			open, baseline)
	}
}
