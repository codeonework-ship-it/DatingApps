package mobile

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
)

// Routes that are intentionally absent from the versioned API document.
//
// These are process/infrastructure endpoints, not part of the client contract:
// probes, the docs UI, and the spec itself. Everything else that the router
// serves under the API prefix is a promise to a client and must be documented.
var openAPIExemptPaths = map[string]bool{
	"/healthz":      true,
	"/readyz":       true,
	"/metrics":      true,
	"/docs":         true,
	"/openapi.yaml": true,
	"/openapi.json": true,
	"/":             true,
}

var openAPIPathParam = regexp.MustCompile(`\{[^}]*\}`)

// normalisePath makes a chi pattern and an OpenAPI path comparable by
// collapsing parameter names, which differ freely between the two ("{userID}"
// vs "{user_id}") without changing the contract.
func normalisePath(path string) string {
	normalised := openAPIPathParam.ReplaceAllString(path, "{}")
	normalised = strings.TrimSuffix(normalised, "/")
	if normalised == "" {
		normalised = "/"
	}
	return normalised
}

// registeredAPIRoutes walks the live router, which is the only source that
// cannot drift from what the service actually serves.
func registeredAPIRoutes(t *testing.T, server *Server) map[string][]string {
	t.Helper()

	routes := map[string][]string{}
	router, ok := server.Handler().(chi.Router)
	if !ok {
		t.Fatal("server handler is not a chi.Router; cannot enumerate routes")
	}

	walk := func(method string, route string, _ http.Handler, _ ...func(http.Handler) http.Handler) error {
		if method == http.MethodOptions || method == http.MethodHead {
			return nil
		}
		if openAPIExemptPaths[route] || openAPIExemptPaths[strings.TrimSuffix(route, "/")] {
			return nil
		}
		if strings.HasPrefix(route, "/debug/") || route == "/debug" {
			return nil
		}
		key := normalisePath(route)
		routes[key] = append(routes[key], method)
		return nil
	}
	if err := chi.Walk(router, walk); err != nil {
		t.Fatalf("walk router: %v", err)
	}
	return routes
}

// documentedAPIPaths reads the paths block of the OpenAPI document.
func documentedAPIPaths(t *testing.T) map[string]bool {
	t.Helper()

	specPath := filepath.Join("..", "..", "platform", "docs", "openapi.yaml")
	raw, err := os.ReadFile(specPath)
	if err != nil {
		t.Fatalf("read openapi.yaml: %v", err)
	}

	paths := map[string]bool{}
	inPaths := false
	for _, line := range strings.Split(string(raw), "\n") {
		if strings.HasPrefix(line, "paths:") {
			inPaths = true
			continue
		}
		if inPaths && len(line) > 0 && line[0] != ' ' && line[0] != '#' {
			break // left the paths block
		}
		if !inPaths {
			continue
		}
		// A path entry sits at exactly two spaces of indentation.
		if !strings.HasPrefix(line, "  /") || strings.HasPrefix(line, "   ") {
			continue
		}
		entry := strings.TrimSpace(line)
		entry = strings.TrimSuffix(entry, ":")
		entry = strings.TrimSpace(strings.Split(entry, "#")[0])
		if entry == "" {
			continue
		}
		paths[normalisePath(entry)] = true
	}
	return paths
}

func newContractTestServer(t *testing.T) *Server {
	t.Helper()

	cfg := config.Config{
		APIPrefix:        "/v1",
		AuthGRPCAddr:     "127.0.0.1:19091",
		ProfileGRPCAddr:  "127.0.0.1:19092",
		MatchingGRPCAddr: "127.0.0.1:19093",
		ChatGRPCAddr:     "127.0.0.1:19094",
	}
	server, err := NewServer(cfg, zap.NewNop(), nil)
	if err != nil {
		t.Fatalf("NewServer: %v", err)
	}
	t.Cleanup(server.Close)
	return server
}

// TestOpenAPI_DocumentsEveryRegisteredRoute is the contract guard.
//
// The router and the specification drifted to the point where dozens of live
// endpoints — most of the admin and engagement surface — had no published
// definition at all. A one-off documentation sweep does not stop that
// recurring; this test does, by failing the build the moment a route is added
// without a corresponding entry.
func TestOpenAPI_DocumentsEveryRegisteredRoute(t *testing.T) {
	server := newContractTestServer(t)

	registered := registeredAPIRoutes(t, server)
	documented := documentedAPIPaths(t)

	var missing []string
	for route := range registered {
		if !documented[route] {
			missing = append(missing, route)
		}
	}
	sort.Strings(missing)

	if len(missing) == 0 {
		return
	}

	byArea := map[string]int{}
	for _, route := range missing {
		// Group by the segment after the version prefix, which is the
		// functional area an owner would recognise.
		segments := strings.Split(strings.Trim(strings.TrimPrefix(route, "/v1"), "/"), "/")
		if len(segments) > 0 && segments[0] != "" {
			byArea[segments[0]]++
		}
	}
	areas := make([]string, 0, len(byArea))
	for area := range byArea {
		areas = append(areas, area)
	}
	sort.Slice(areas, func(i, j int) bool { return byArea[areas[i]] > byArea[areas[j]] })

	var summary strings.Builder
	summary.WriteString(fmt.Sprintf(
		"%d registered routes are missing from openapi.yaml (%d registered, %d documented)\n\nby area:\n",
		len(missing), len(registered), len(documented)))
	for _, area := range areas {
		summary.WriteString(fmt.Sprintf("  %-16s %d\n", area, byArea[area]))
	}
	summary.WriteString("\nundocumented routes:\n")
	for _, route := range missing {
		methods := append([]string(nil), registered[route]...)
		sort.Strings(methods)
		summary.WriteString(fmt.Sprintf("  %-8s %s\n", strings.Join(methods, ","), route))
	}
	t.Fatal(summary.String())
}

// TestOpenAPI_HasNoPathsTheRouterDoesNotServe catches the opposite drift: a
// documented endpoint a client can code against that does not exist.
func TestOpenAPI_HasNoPathsTheRouterDoesNotServe(t *testing.T) {
	server := newContractTestServer(t)

	registered := registeredAPIRoutes(t, server)
	documented := documentedAPIPaths(t)

	var phantom []string
	for route := range documented {
		// Exempt paths are deliberately excluded from the registered set, so
		// they would otherwise read as phantoms in this direction.
		if openAPIExemptPaths[route] {
			continue
		}
		if len(registered[route]) == 0 {
			phantom = append(phantom, route)
		}
	}
	sort.Strings(phantom)

	if len(phantom) > 0 {
		t.Fatalf(
			"%d paths are documented but not served by the router:\n  %s",
			len(phantom), strings.Join(phantom, "\n  "))
	}
}
