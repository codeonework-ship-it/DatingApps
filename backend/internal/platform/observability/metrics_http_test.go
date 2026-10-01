package observability

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus"
	dto "github.com/prometheus/client_model/go"
	"go.uber.org/zap"
)

func newTestRouter(metrics *HTTPMetrics) chi.Router {
	r := chi.NewRouter()
	r.Use(RequestLoggingMiddleware(zap.NewNop(), metrics, metrics.Service))
	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	r.Route("/v1", func(v1 chi.Router) {
		v1.Get("/profile/{userID}", func(w http.ResponseWriter, r *http.Request) {
			if chi.URLParam(r, "userID") == "missing" {
				http.Error(w, "not found", http.StatusNotFound)
				return
			}
			_, _ = w.Write([]byte("ok"))
		})
		v1.Post("/chat/{matchID}/messages", func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
		})
		v1.Get("/realtime/chat", func(w http.ResponseWriter, r *http.Request) {
			upgrader := websocket.Upgrader{CheckOrigin: func(*http.Request) bool { return true }}
			conn, err := upgrader.Upgrade(w, r, nil)
			if err != nil {
				return
			}
			defer conn.Close()
			_, _, _ = conn.ReadMessage()
		})
	})
	return r
}

func counterValues(t *testing.T, reg *prometheus.Registry, name string) map[string]float64 {
	t.Helper()
	families, err := reg.Gather()
	if err != nil {
		t.Fatal(err)
	}
	out := map[string]float64{}
	for _, family := range families {
		if family.GetName() != name {
			continue
		}
		for _, metric := range family.GetMetric() {
			out[labelKey(metric)] = metricValue(metric)
		}
	}
	return out
}

func labelKey(metric *dto.Metric) string {
	parts := []string{}
	for _, pair := range metric.GetLabel() {
		parts = append(parts, pair.GetName()+"="+pair.GetValue())
	}
	return strings.Join(parts, ",")
}

func metricValue(metric *dto.Metric) float64 {
	switch {
	case metric.Counter != nil:
		return metric.GetCounter().GetValue()
	case metric.Gauge != nil:
		return metric.GetGauge().GetValue()
	case metric.Histogram != nil:
		return float64(metric.GetHistogram().GetSampleCount())
	}
	return 0
}

func TestRequestMetricsUseRouteTemplateAndStatusClass(t *testing.T) {
	reg := prometheus.NewRegistry()
	metrics := NewBFFMetrics(reg)
	server := httptest.NewServer(newTestRouter(metrics))
	defer server.Close()

	for i := 0; i < 3; i++ {
		resp, err := http.Get(fmt.Sprintf("%s/v1/profile/user-%d", server.URL, i))
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
	}
	for _, path := range []string{"/v1/profile/missing", "/v1/does-not-exist", "/wp-login.php", "/v1/profile/a/b/c"} {
		resp, err := http.Get(server.URL + path)
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
	}
	resp, err := http.Post(server.URL+"/v1/chat/m-1/messages", "application/json", nil)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	// Method the route does not accept: the router answers 405.
	resp, err = http.Post(server.URL+"/v1/profile/u-1", "application/json", nil)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()

	got := counterValues(t, reg, "verified_dating_http_requests_total")
	want := map[string]float64{
		"method=GET,route=/v1/profile/{userID},service=mobile_bff,status_class=2xx":         3,
		"method=GET,route=/v1/profile/{userID},service=mobile_bff,status_class=4xx":         1,
		"method=GET,route=unmatched,service=mobile_bff,status_class=4xx":                    3,
		"method=POST,route=/v1/chat/{matchID}/messages,service=mobile_bff,status_class=5xx": 1,
		"method=POST,route=unmatched,service=mobile_bff,status_class=4xx":                   1,
	}
	if len(got) != len(want) {
		t.Fatalf("unexpected series: %v", got)
	}
	for key, value := range want {
		if got[key] != value {
			t.Fatalf("series %s = %v, want %v (all: %v)", key, got[key], value, got)
		}
	}
	for key := range got {
		if strings.Contains(key, "user-") || strings.Contains(key, "wp-login") || strings.Contains(key, "does-not-exist") {
			t.Fatalf("raw path leaked into labels: %s", key)
		}
	}
	codes := counterValues(t, reg, "verified_dating_http_responses_by_code_total")
	if codes["code=405,service=mobile_bff"] != 1 || codes["code=500,service=mobile_bff"] != 1 {
		t.Fatalf("unexpected per-code counts: %v", codes)
	}
}

func TestRouteLabelCardinalityIsBounded(t *testing.T) {
	labeler := newRouteLabeler(3)
	for i := 0; i < 3; i++ {
		if got := labeler.admit(fmt.Sprintf("/r%d", i)); got != fmt.Sprintf("/r%d", i) {
			t.Fatalf("route %d relabelled to %s", i, got)
		}
	}
	if got := labeler.admit("/r99"); got != RouteOverflow {
		t.Fatalf("overflow route = %q, want %q", got, RouteOverflow)
	}
	if got := labeler.admit("/r1"); got != "/r1" {
		t.Fatalf("known route must keep its label, got %q", got)
	}
	if got := labeler.admit(RouteUnmatched); got != RouteUnmatched {
		t.Fatalf("unmatched must never count against the budget, got %q", got)
	}
	if got := normalizeMethod("PROPFIND"); got != "OTHER" {
		t.Fatalf("unknown methods must collapse, got %q", got)
	}
	for status, class := range map[int]string{101: "1xx", 204: "2xx", 302: "3xx", 429: "4xx", 503: "5xx", 0: "unknown"} {
		if got := StatusClass(status); got != class {
			t.Fatalf("StatusClass(%d) = %s, want %s", status, got, class)
		}
	}
}

func TestWebSocketConnectionsAreGaugedAndExcludedFromLatency(t *testing.T) {
	reg := prometheus.NewRegistry()
	metrics := NewBFFMetrics(reg)
	server := httptest.NewServer(newTestRouter(metrics))
	defer server.Close()

	url := "ws" + strings.TrimPrefix(server.URL, "http") + "/v1/realtime/chat"
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		t.Fatal(err)
	}
	waitFor(t, func() bool {
		return counterValues(t, reg, "verified_dating_realtime_connections")["route=/v1/realtime/chat,service=mobile_bff"] == 1
	})
	if inflight := counterValues(t, reg, "verified_dating_http_in_flight_requests")["service=mobile_bff"]; inflight != 0 {
		t.Fatalf("upgraded connection must not count as in-flight, got %v", inflight)
	}
	_ = conn.Close()
	waitFor(t, func() bool {
		return counterValues(t, reg, "verified_dating_realtime_connection_duration_seconds")["route=/v1/realtime/chat,service=mobile_bff"] == 1
	})
	if open := counterValues(t, reg, "verified_dating_realtime_connections")["route=/v1/realtime/chat,service=mobile_bff"]; open != 0 {
		t.Fatalf("closed socket still counted: %v", open)
	}
	if latency := counterValues(t, reg, "verified_dating_http_request_duration_seconds"); len(latency) != 0 {
		t.Fatalf("socket lifetime leaked into request latency: %v", latency)
	}
	requests := counterValues(t, reg, "verified_dating_http_requests_total")
	if requests["method=GET,route=/v1/realtime/chat,service=mobile_bff,status_class=1xx"] != 1 {
		t.Fatalf("upgrade should be counted as 1xx: %v", requests)
	}
}

func waitFor(t *testing.T, cond func() bool) {
	t.Helper()
	for i := 0; i < 200; i++ {
		if cond() {
			return
		}
		<-timeAfterMillis(10)
	}
	t.Fatal("condition not met")
}

func TestGatewayRegistryExposesOnlyEdgeMetrics(t *testing.T) {
	gatewayReg := newCapture()
	gateway := NewGatewayMetrics(gatewayReg)
	bffReg := newCapture()
	NewBFFMetrics(bffReg)

	gatewayNames := describedNames(t, gatewayReg)
	bffNames := describedNames(t, bffReg)
	for _, bffOnly := range []string{
		"verified_dating_notification_push_success_percent_15m",
		"verified_dating_notification_queue_depth",
		"verified_dating_sos_delivery_queue_depth",
		"verified_dating_progression_projection_queue_depth",
		"verified_dating_reliability_requests_shed_total",
		"verified_dating_worker_last_success_timestamp_seconds",
		"verified_dating_queue_depth",
		"verified_dating_realtime_delivery_lag_seconds",
	} {
		if gatewayNames[bffOnly] {
			t.Fatalf("gateway must not register BFF-only metric %s", bffOnly)
		}
		if !bffNames[bffOnly] {
			t.Fatalf("BFF must register %s", bffOnly)
		}
	}
	for _, shared := range []string{"verified_dating_http_requests_total", "verified_dating_http_request_duration_seconds", "verified_dating_realtime_connections"} {
		if !gatewayNames[shared] || !bffNames[shared] {
			t.Fatalf("%s must be registered by both processes", shared)
		}
	}
	if gateway.Service != ServiceAPIGateway || gateway.Workers != nil || gateway.NotificationPushSuccess != nil {
		t.Fatal("gateway metrics must not carry BFF collectors")
	}
}

func TestRecoveredPanicsAndRejectionsAreCounted(t *testing.T) {
	reg := prometheus.NewRegistry()
	metrics := NewGatewayMetrics(reg)
	r := chi.NewRouter()
	r.Use(CorrelationIDMiddleware(zap.NewNop()))
	r.Use(RequestLoggingMiddleware(zap.NewNop(), metrics, ServiceAPIGateway))
	r.Use(GlobalExceptionMiddleware(zap.NewNop()))
	r.Use(InflightSheddingMiddleware(zap.NewNop(), "test", 1, 1))
	release := make(chan struct{})
	entered := make(chan struct{})
	r.Get("/v1/slow", func(w http.ResponseWriter, _ *http.Request) {
		close(entered)
		<-release
	})
	r.Get("/v1/panic", func(http.ResponseWriter, *http.Request) { panic("boom") })
	server := httptest.NewServer(r)
	defer server.Close()

	resp, err := http.Get(server.URL + "/v1/panic")
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		defer close(done)
		if slow, err := http.Get(server.URL + "/v1/slow"); err == nil {
			slow.Body.Close()
		}
	}()
	<-entered
	shed, err := http.Get(server.URL + "/v1/panic")
	if err != nil {
		t.Fatal(err)
	}
	shed.Body.Close()
	close(release)
	<-done

	got := counterValues(t, reg, "verified_dating_http_requests_total")
	if got["method=GET,route=/v1/panic,service=api_gateway,status_class=5xx"] != 1 {
		t.Fatalf("recovered panic not counted as 5xx: %v", got)
	}
	if got["method=GET,route=/v1/panic,service=api_gateway,status_class=4xx"] != 1 {
		t.Fatalf("shed request not counted as 4xx: %v", got)
	}
}
