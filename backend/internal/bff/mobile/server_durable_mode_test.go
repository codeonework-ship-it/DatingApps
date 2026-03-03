package mobile

import (
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/observability"
)

func TestNewServer_DurableModeRequiresQuestRepository(t *testing.T) {
	cfg := config.Config{
		APIPrefix:                     "/v1",
		AuthGRPCAddr:                  "127.0.0.1:29091",
		ProfileGRPCAddr:               "127.0.0.1:29092",
		MatchingGRPCAddr:              "127.0.0.1:29093",
		ChatGRPCAddr:                  "127.0.0.1:29094",
		RequireDurableEngagementStore: true,
		FeatureEngagementUnlockMVP:    true,
		FeatureDigitalGestures:        true,
		FeatureMiniActivities:         false,
		FeatureTrustBadges:            false,
		FeatureConversationRooms:      false,
	}

	metrics := observability.NewHTTPMetrics(prometheus.NewRegistry())
	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err == nil {
		server.Close()
		t.Fatalf("expected error when durable mode requires quest repository")
	}
	if !strings.Contains(err.Error(), "quest/gesture persistence repository") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestNewServer_DurableModeRejectsMemoryOnlyEngagementFeatures(t *testing.T) {
	cfg := config.Config{
		APIPrefix:                     "/v1",
		AuthGRPCAddr:                  "127.0.0.1:39091",
		ProfileGRPCAddr:               "127.0.0.1:39092",
		MatchingGRPCAddr:              "127.0.0.1:39093",
		ChatGRPCAddr:                  "127.0.0.1:39094",
		RequireDurableEngagementStore: true,
		FeatureEngagementUnlockMVP:    false,
		FeatureDigitalGestures:        false,
		FeatureMiniActivities:         true,
		FeatureTrustBadges:            true,
		FeatureConversationRooms:      true,
	}

	metrics := observability.NewHTTPMetrics(prometheus.NewRegistry())
	server, err := NewServer(cfg, zap.NewNop(), metrics)
	if err == nil {
		server.Close()
		t.Fatalf("expected error when durable mode enables memory-only engagement features")
	}
	if !strings.Contains(err.Error(), "mini_activities") ||
		!strings.Contains(err.Error(), "trust_badges") ||
		!strings.Contains(err.Error(), "conversation_rooms") {
		t.Fatalf("unexpected error: %v", err)
	}
}
