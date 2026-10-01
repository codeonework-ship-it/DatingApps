package mobile

import (
	"bytes"
	"context"
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

const fcmMessagingScope = "https://www.googleapis.com/auth/firebase.messaging"

type providerPushSender struct {
	mode    string
	webhook *webhookPushSender
	fcm     *fcmPushSender
	apns    *apnsPushSender
}

func newPushNotificationSender(cfg config.Config) pushNotificationSender {
	sender := &providerPushSender{mode: cfg.NotificationPushProvider}
	switch sender.mode {
	case "webhook":
		sender.webhook = newWebhookPushSender(cfg)
	case "direct":
		sender.fcm = newFCMPushSender(cfg)
		sender.apns = newAPNSPushSender(cfg)
	}
	return sender
}

func (s *providerPushSender) Configured() bool {
	if s == nil {
		return false
	}
	return (s.webhook != nil && s.webhook.Configured()) ||
		(s.fcm != nil && s.fcm.Configured()) || (s.apns != nil && s.apns.Configured())
}

func (s *providerPushSender) Send(ctx context.Context, device notificationDevice, job notificationOutboxJob) (pushDeliveryResult, error) {
	if s == nil {
		return pushDeliveryResult{Permanent: true}, errors.New("push delivery is disabled")
	}
	if s.webhook != nil {
		return s.webhook.Send(ctx, device, job)
	}
	switch strings.ToLower(device.Provider) {
	case "fcm":
		if s.fcm != nil && s.fcm.Configured() {
			return s.fcm.Send(ctx, device, job)
		}
	case "apns":
		if s.apns != nil && s.apns.Configured() {
			return s.apns.Send(ctx, device, job)
		}
	}
	return pushDeliveryResult{Permanent: true}, fmt.Errorf("push provider %q is not configured", device.Provider)
}

type webhookPushSender struct {
	endpoint string
	token    string
	client   *http.Client
}

func newWebhookPushSender(cfg config.Config) *webhookPushSender {
	return &webhookPushSender{endpoint: strings.TrimSpace(cfg.NotificationPushWebhookURL), token: strings.TrimSpace(cfg.NotificationPushWebhookToken), client: &http.Client{Timeout: 8 * time.Second}}
}

func (s *webhookPushSender) Configured() bool { return s != nil && s.endpoint != "" }

func (s *webhookPushSender) Send(ctx context.Context, device notificationDevice, job notificationOutboxJob) (pushDeliveryResult, error) {
	payload, err := json.Marshal(pushEnvelope(device, job))
	if err != nil {
		return pushDeliveryResult{Permanent: true}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.endpoint, bytes.NewReader(payload))
	if err != nil {
		return pushDeliveryResult{Permanent: true}, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Idempotency-Key", job.ID+":"+device.ID)
	if s.token != "" {
		req.Header.Set("Authorization", "Bearer "+s.token)
	}
	resp, err := s.client.Do(req)
	if err != nil {
		return pushDeliveryResult{}, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		permanent := resp.StatusCode == http.StatusBadRequest || resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusGone
		return pushDeliveryResult{Permanent: permanent, InvalidToken: resp.StatusCode == http.StatusGone}, fmt.Errorf("push webhook returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	messageID := strings.TrimSpace(resp.Header.Get("X-Provider-Message-ID"))
	if messageID == "" {
		var decoded map[string]any
		if json.Unmarshal(body, &decoded) == nil {
			messageID = strings.TrimSpace(toString(decoded["message_id"]))
		}
	}
	return pushDeliveryResult{MessageID: messageID}, nil
}

func pushEnvelope(device notificationDevice, job notificationOutboxJob) map[string]any {
	return map[string]any{
		"device":       map[string]any{"provider": device.Provider, "platform": device.Platform, "token": device.Token},
		"notification": map[string]any{"id": job.ID, "sequence": job.Sequence, "event_type": job.EventType, "category": job.Category, "title": job.Title, "body": job.Body, "action_route": job.ActionRoute, "payload": job.Payload},
	}
}

type fcmServiceAccount struct {
	ProjectID   string `json:"project_id"`
	ClientEmail string `json:"client_email"`
	PrivateKey  string `json:"private_key"`
	TokenURI    string `json:"token_uri"`
}

type fcmTokenSource struct {
	credentialsFile string
	tokenURL        string
	client          *http.Client
	mu              sync.Mutex
	account         *fcmServiceAccount
	privateKey      *rsa.PrivateKey
	accessToken     string
	expiresAt       time.Time
}

func (s *fcmTokenSource) Token(ctx context.Context) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.accessToken != "" && time.Now().Add(5*time.Minute).Before(s.expiresAt) {
		return s.accessToken, nil
	}
	if err := s.load(); err != nil {
		return "", err
	}
	now := time.Now().UTC()
	assertion, err := signedJWT(map[string]any{"alg": "RS256", "typ": "JWT"}, map[string]any{"iss": s.account.ClientEmail, "scope": fcmMessagingScope, "aud": s.tokenURL, "iat": now.Unix(), "exp": now.Add(time.Hour).Unix()}, func(input []byte) ([]byte, error) {
		hash := sha256.Sum256(input)
		return rsa.SignPKCS1v15(rand.Reader, s.privateKey, crypto.SHA256, hash[:])
	})
	if err != nil {
		return "", err
	}
	form := url.Values{"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"}, "assertion": {assertion}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.tokenURL, strings.NewReader(form.Encode()))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 8192))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("FCM OAuth token request returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	var token struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err := json.Unmarshal(body, &token); err != nil || token.AccessToken == "" {
		return "", errors.New("FCM OAuth token response is invalid")
	}
	if token.ExpiresIn <= 0 {
		token.ExpiresIn = 3600
	}
	s.accessToken, s.expiresAt = token.AccessToken, now.Add(time.Duration(token.ExpiresIn)*time.Second)
	return s.accessToken, nil
}

func (s *fcmTokenSource) load() error {
	if s.account != nil && s.privateKey != nil {
		return nil
	}
	body, err := os.ReadFile(s.credentialsFile)
	if err != nil {
		return fmt.Errorf("read FCM service account: %w", err)
	}
	var account fcmServiceAccount
	if err := json.Unmarshal(body, &account); err != nil {
		return fmt.Errorf("parse FCM service account: %w", err)
	}
	block, _ := pem.Decode([]byte(account.PrivateKey))
	if block == nil {
		return errors.New("FCM service account private_key is not PEM")
	}
	parsed, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return fmt.Errorf("parse FCM private key: %w", err)
	}
	key, ok := parsed.(*rsa.PrivateKey)
	if !ok {
		return errors.New("FCM service account private key is not RSA")
	}
	if account.ClientEmail == "" {
		return errors.New("FCM service account client_email is missing")
	}
	s.account, s.privateKey = &account, key
	return nil
}

type fcmPushSender struct {
	projectID string
	endpoint  string
	tokens    interface {
		Token(context.Context) (string, error)
	}
	client *http.Client
}

func newFCMPushSender(cfg config.Config) *fcmPushSender {
	if cfg.NotificationFCMProjectID == "" || cfg.NotificationFCMCredentialsFile == "" {
		return nil
	}
	client := &http.Client{Timeout: 8 * time.Second}
	tokenURL := cfg.NotificationFCMTokenURL
	return &fcmPushSender{projectID: cfg.NotificationFCMProjectID, endpoint: strings.TrimRight(cfg.NotificationFCMEndpoint, "/"), client: client, tokens: &fcmTokenSource{credentialsFile: cfg.NotificationFCMCredentialsFile, tokenURL: tokenURL, client: client}}
}

func (s *fcmPushSender) Configured() bool { return s != nil && s.projectID != "" && s.tokens != nil }

func (s *fcmPushSender) Send(ctx context.Context, device notificationDevice, job notificationOutboxJob) (pushDeliveryResult, error) {
	token, err := s.tokens.Token(ctx)
	if err != nil {
		return pushDeliveryResult{}, err
	}
	data := pushData(job)
	message := map[string]any{
		"token":        device.Token,
		"notification": map[string]string{"title": job.Title, "body": job.Body},
		"data":         data,
		"android":      map[string]any{"priority": "HIGH", "ttl": pushTTL(job.Category), "notification": map[string]any{"channel_id": pushChannel(job.Category), "tag": job.ID, "click_action": "FLUTTER_NOTIFICATION_CLICK"}},
		"apns":         map[string]any{"headers": map[string]string{"apns-push-type": "alert", "apns-priority": "10", "apns-collapse-id": job.ID}, "payload": map[string]any{"aps": map[string]any{"sound": "default", "category": pushCategory(job.Category), "content-available": 1}}},
	}
	body, err := json.Marshal(map[string]any{"message": message})
	if err != nil {
		return pushDeliveryResult{Permanent: true}, err
	}
	endpoint := fmt.Sprintf("%s/v1/projects/%s/messages:send", s.endpoint, url.PathEscape(s.projectID))
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return pushDeliveryResult{Permanent: true}, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	resp, err := s.client.Do(req)
	if err != nil {
		return pushDeliveryResult{}, err
	}
	defer resp.Body.Close()
	responseBody, _ := io.ReadAll(io.LimitReader(resp.Body, 8192))
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		var decoded map[string]any
		_ = json.Unmarshal(responseBody, &decoded)
		return pushDeliveryResult{MessageID: strings.TrimSpace(toString(decoded["name"]))}, nil
	}
	code := fcmErrorCode(responseBody)
	invalid := code == "UNREGISTERED" || code == "SENDER_ID_MISMATCH"
	permanent := invalid || resp.StatusCode == http.StatusBadRequest || resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusForbidden
	return pushDeliveryResult{Permanent: permanent, InvalidToken: invalid}, fmt.Errorf("FCM send returned %d (%s): %s", resp.StatusCode, code, strings.TrimSpace(string(responseBody)))
}

func fcmErrorCode(body []byte) string {
	var decoded struct {
		Error struct {
			Status  string `json:"status"`
			Details []struct {
				ErrorCode string `json:"errorCode"`
			} `json:"details"`
		} `json:"error"`
	}
	if json.Unmarshal(body, &decoded) != nil {
		return ""
	}
	for _, detail := range decoded.Error.Details {
		if detail.ErrorCode != "" {
			return detail.ErrorCode
		}
	}
	return decoded.Error.Status
}

type apnsPushSender struct {
	teamID, keyID, bundleID, keyFile, endpoint string
	client                                     *http.Client
	mu                                         sync.Mutex
	privateKey                                 *ecdsa.PrivateKey
	authToken                                  string
	tokenAt                                    time.Time
}

func newAPNSPushSender(cfg config.Config) *apnsPushSender {
	if cfg.NotificationAPNSTeamID == "" || cfg.NotificationAPNSKeyID == "" || cfg.NotificationAPNSBundleID == "" || cfg.NotificationAPNSPrivateKeyFile == "" {
		return nil
	}
	endpoint := strings.TrimRight(cfg.NotificationAPNSEndpoint, "/")
	if endpoint == "" {
		if cfg.NotificationAPNSUseSandbox {
			endpoint = "https://api.sandbox.push.apple.com"
		} else {
			endpoint = "https://api.push.apple.com"
		}
	}
	return &apnsPushSender{teamID: cfg.NotificationAPNSTeamID, keyID: cfg.NotificationAPNSKeyID, bundleID: cfg.NotificationAPNSBundleID, keyFile: cfg.NotificationAPNSPrivateKeyFile, endpoint: endpoint, client: &http.Client{Timeout: 8 * time.Second, Transport: &http.Transport{ForceAttemptHTTP2: true}}}
}

func (s *apnsPushSender) Configured() bool { return s != nil && s.teamID != "" && s.bundleID != "" }

func (s *apnsPushSender) Send(ctx context.Context, device notificationDevice, job notificationOutboxJob) (pushDeliveryResult, error) {
	auth, err := s.token()
	if err != nil {
		return pushDeliveryResult{}, err
	}
	payload := map[string]any{"aps": map[string]any{"alert": map[string]string{"title": job.Title, "body": job.Body}, "sound": "default", "category": pushCategory(job.Category), "content-available": 1}, "notification": pushData(job)}
	body, err := json.Marshal(payload)
	if err != nil {
		return pushDeliveryResult{Permanent: true}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.endpoint+"/3/device/"+url.PathEscape(device.Token), bytes.NewReader(body))
	if err != nil {
		return pushDeliveryResult{Permanent: true}, err
	}
	req.Header.Set("authorization", "bearer "+auth)
	req.Header.Set("apns-topic", s.bundleID)
	req.Header.Set("apns-push-type", "alert")
	req.Header.Set("apns-priority", "10")
	req.Header.Set("apns-expiration", fmt.Sprintf("%d", time.Now().Add(pushTTLDuration(job.Category)).Unix()))
	req.Header.Set("apns-collapse-id", job.ID)
	resp, err := s.client.Do(req)
	if err != nil {
		return pushDeliveryResult{}, err
	}
	defer resp.Body.Close()
	responseBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if resp.StatusCode == http.StatusOK {
		return pushDeliveryResult{MessageID: strings.TrimSpace(resp.Header.Get("apns-id"))}, nil
	}
	var failure struct {
		Reason string `json:"reason"`
	}
	_ = json.Unmarshal(responseBody, &failure)
	invalid := failure.Reason == "BadDeviceToken" || failure.Reason == "DeviceTokenNotForTopic" || failure.Reason == "Unregistered"
	permanent := invalid || resp.StatusCode == http.StatusBadRequest || resp.StatusCode == http.StatusForbidden || resp.StatusCode == http.StatusGone
	return pushDeliveryResult{Permanent: permanent, InvalidToken: invalid}, fmt.Errorf("APNs send returned %d (%s)", resp.StatusCode, failure.Reason)
}

func (s *apnsPushSender) token() (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.authToken != "" && time.Since(s.tokenAt) < 50*time.Minute {
		return s.authToken, nil
	}
	if s.privateKey == nil {
		body, err := os.ReadFile(s.keyFile)
		if err != nil {
			return "", fmt.Errorf("read APNs key: %w", err)
		}
		block, _ := pem.Decode(body)
		if block == nil {
			return "", errors.New("APNs private key is not PEM")
		}
		parsed, err := x509.ParsePKCS8PrivateKey(block.Bytes)
		if err != nil {
			return "", fmt.Errorf("parse APNs key: %w", err)
		}
		key, ok := parsed.(*ecdsa.PrivateKey)
		if !ok || key.Curve != elliptic.P256() {
			return "", errors.New("APNs private key must be P-256")
		}
		s.privateKey = key
	}
	now := time.Now().UTC()
	token, err := signedJWT(map[string]any{"alg": "ES256", "kid": s.keyID}, map[string]any{"iss": s.teamID, "iat": now.Unix()}, func(input []byte) ([]byte, error) {
		hash := sha256.Sum256(input)
		r, ss, err := ecdsa.Sign(rand.Reader, s.privateKey, hash[:])
		if err != nil {
			return nil, err
		}
		return ecdsaSignature(r, ss, 32), nil
	})
	if err != nil {
		return "", err
	}
	s.authToken, s.tokenAt = token, now
	return token, nil
}

func signedJWT(header, claims map[string]any, sign func([]byte) ([]byte, error)) (string, error) {
	h, err := json.Marshal(header)
	if err != nil {
		return "", err
	}
	c, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}
	input := base64.RawURLEncoding.EncodeToString(h) + "." + base64.RawURLEncoding.EncodeToString(c)
	sig, err := sign([]byte(input))
	if err != nil {
		return "", err
	}
	return input + "." + base64.RawURLEncoding.EncodeToString(sig), nil
}

func ecdsaSignature(r, s *big.Int, size int) []byte {
	out := make([]byte, size*2)
	r.FillBytes(out[:size])
	s.FillBytes(out[size:])
	return out
}

func pushData(job notificationOutboxJob) map[string]string {
	data := map[string]string{"notification_id": job.ID, "sequence": fmt.Sprint(job.Sequence), "event_type": job.EventType, "category": job.Category, "action_route": job.ActionRoute}
	for key, value := range job.Payload {
		switch typed := value.(type) {
		case string:
			data[key] = typed
		case nil:
			continue
		default:
			if encoded, err := json.Marshal(typed); err == nil {
				data[key] = string(encoded)
			}
		}
	}
	return data
}

func pushTTL(category string) string {
	return fmt.Sprintf("%ds", int(pushTTLDuration(category).Seconds()))
}
func pushTTLDuration(category string) time.Duration {
	switch category {
	case "call":
		return 45 * time.Second
	case "nudge":
		return 6 * time.Hour
	default:
		return 24 * time.Hour
	}
}
func pushChannel(category string) string {
	if category == "call" {
		return "incoming_calls"
	}
	return "dating_activity"
}
func pushCategory(category string) string {
	if category == "call" {
		return "INCOMING_CALL"
	}
	if category == "nudge" {
		return "MATCH_NUDGE"
	}
	if category == "friend_plan" {
		return "FRIEND_PLAN"
	}
	return "DATING_ACTIVITY"
}
