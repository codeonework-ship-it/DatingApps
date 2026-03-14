package mobile

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestDefaultGatewayHost(t *testing.T) {
	tests := []struct {
		name string
		addr string
		want string
	}{
		{name: "empty", addr: "", want: ""},
		{name: "port only", addr: ":8080", want: "localhost:8080"},
		{name: "host and port", addr: "gateway.internal:8080", want: "gateway.internal:8080"},
		{name: "url", addr: "https://api.example.com:443", want: "api.example.com:443"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := defaultGatewayHost(tc.addr)
			if got != tc.want {
				t.Fatalf("defaultGatewayHost(%q) = %q, want %q", tc.addr, got, tc.want)
			}
		})
	}
}

func TestRequestBaseURL(t *testing.T) {
	t.Run("uses forwarded host and proto", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		req.Header.Set("X-Forwarded-Host", "media.example.com")
		req.Header.Set("X-Forwarded-Proto", "https")

		got := requestBaseURL(req, "localhost:8080")
		if got != "https://media.example.com" {
			t.Fatalf("requestBaseURL() = %q, want %q", got, "https://media.example.com")
		}
	})

	t.Run("falls back to request host", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "http://10.0.2.2:8080/v1/ping", nil)

		got := requestBaseURL(req, "localhost:8080")
		if got != "http://10.0.2.2:8080" {
			t.Fatalf("requestBaseURL() = %q, want %q", got, "http://10.0.2.2:8080")
		}
	})

	t.Run("falls back to configured host", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/v1/ping", nil)
		req.Host = ""

		got := requestBaseURL(req, "gateway.internal:9090")
		if got != "http://gateway.internal:9090" {
			t.Fatalf("requestBaseURL() = %q, want %q", got, "http://gateway.internal:9090")
		}
	})
}
