package observability

import (
	"strings"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func NewLogger(env, level string) (*zap.Logger, error) {
	cfg := zap.NewProductionConfig()
	if strings.EqualFold(env, "development") {
		cfg = zap.NewDevelopmentConfig()
	}

	parsedLevel := zapcore.InfoLevel
	if err := parsedLevel.UnmarshalText([]byte(strings.ToLower(level))); err == nil {
		cfg.Level = zap.NewAtomicLevelAt(parsedLevel)
	}

	return cfg.Build()
}
