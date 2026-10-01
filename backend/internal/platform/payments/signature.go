package payments

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// DefaultSignatureTolerance bounds how old a signed webhook may be before it
// is treated as a replay.
const DefaultSignatureTolerance = 5 * time.Minute

// SignPayload produces a Stripe-compatible signature header
// (`t=<unix>,v1=<hex hmac>`) over `<unix>.<payload>`.
func SignPayload(secret string, at time.Time, payload []byte) string {
	ts := strconv.FormatInt(at.Unix(), 10)
	return "t=" + ts + ",v1=" + computeSignature(secret, ts, payload)
}

func computeSignature(secret, timestamp string, payload []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(timestamp))
	mac.Write([]byte("."))
	mac.Write(payload)
	return hex.EncodeToString(mac.Sum(nil))
}

// VerifySignature checks a `t=...,v1=...` header against the payload.
// Several v1 entries are accepted (secret rotation). The timestamp must be
// within tolerance of now.
func VerifySignature(secret, header string, payload []byte, now time.Time, tolerance time.Duration) error {
	if strings.TrimSpace(secret) == "" {
		return errors.New("webhook secret is not configured")
	}
	if tolerance <= 0 {
		tolerance = DefaultSignatureTolerance
	}
	var timestamp string
	var candidates []string
	for _, part := range strings.Split(header, ",") {
		kv := strings.SplitN(strings.TrimSpace(part), "=", 2)
		if len(kv) != 2 {
			continue
		}
		switch kv[0] {
		case "t":
			timestamp = kv[1]
		case "v1":
			candidates = append(candidates, kv[1])
		}
	}
	if timestamp == "" || len(candidates) == 0 {
		return fmt.Errorf("%w: malformed header", ErrSignature)
	}
	unix, err := strconv.ParseInt(timestamp, 10, 64)
	if err != nil {
		return fmt.Errorf("%w: malformed timestamp", ErrSignature)
	}
	signedAt := time.Unix(unix, 0)
	if diff := now.Sub(signedAt); diff > tolerance || diff < -tolerance {
		return fmt.Errorf("%w: timestamp outside tolerance", ErrSignature)
	}
	expected := computeSignature(secret, timestamp, payload)
	for _, candidate := range candidates {
		if hmac.Equal([]byte(expected), []byte(candidate)) {
			return nil
		}
	}
	return ErrSignature
}
