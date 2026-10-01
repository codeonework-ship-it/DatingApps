package mobile

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/textproto"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

type providerEvidenceFile struct {
	Filename string
	MimeType string
	Content  []byte
}

type verificationEvidenceBundle struct {
	IDDocument providerEvidenceFile
	Selfie     providerEvidenceFile
}

type providerAssessment struct {
	Decision      string  `json:"decision"`
	Reason        string  `json:"reason,omitempty"`
	Confidence    float64 `json:"confidence,omitempty"`
	ProviderRef   string  `json:"provider_reference,omitempty"`
	Provider      string  `json:"provider"`
	ModelVersion  string  `json:"model_version,omitempty"`
	AssessedAtUTC string  `json:"assessed_at"`
}

type identityVerificationProvider interface {
	Assess(context.Context, string, verificationEvidenceBundle) (providerAssessment, error)
}

type voiceModerationProvider interface {
	Assess(context.Context, string, string, voiceRecordingMetadata) (providerAssessment, error)
}

type providerReviewClient struct {
	provider            string
	endpoint            string
	token               string
	allowLocalVoicePass bool
	client              *http.Client
}

func newIdentityVerificationProvider(cfg config.Config) identityVerificationProvider {
	return &providerReviewClient{
		provider: cfg.IdentityVerificationProvider, endpoint: cfg.IdentityVerificationWebhookURL,
		token: cfg.IdentityVerificationWebhookToken, client: &http.Client{Timeout: 20 * time.Second},
	}
}

func newVoiceModerationProvider(cfg config.Config) *providerReviewClient {
	environment := strings.ToLower(strings.TrimSpace(cfg.Environment))
	allowLocalVoicePass := environment != "production" && environment != "prod" && environment != "staging" && environment != "stage"
	return &providerReviewClient{
		provider: cfg.VoiceModerationProvider, endpoint: cfg.VoiceModerationWebhookURL,
		token: cfg.VoiceModerationWebhookToken, allowLocalVoicePass: allowLocalVoicePass,
		client: &http.Client{Timeout: 20 * time.Second},
	}
}

func (p *providerReviewClient) Assess(ctx context.Context, userID string, evidence verificationEvidenceBundle) (providerAssessment, error) {
	if p == nil || p.provider == "disabled" || strings.TrimSpace(p.provider) == "" {
		return providerAssessment{Decision: "manual_review", Provider: "disabled", AssessedAtUTC: time.Now().UTC().Format(time.RFC3339)}, nil
	}
	fields := map[string]string{"user_id": userID, "assessment_type": "identity_document_and_selfie"}
	files := map[string]providerEvidenceFile{"id_document": evidence.IDDocument, "selfie": evidence.Selfie}
	return p.postMultipart(ctx, fields, files)
}

func (p *providerReviewClient) AssessVoice(ctx context.Context, icebreakerID, transcript string, recording voiceRecordingMetadata) (providerAssessment, error) {
	if p == nil || p.provider == "disabled" || strings.TrimSpace(p.provider) == "" {
		decision := "manual_review"
		if p != nil && p.allowLocalVoicePass {
			decision = "approved"
		}
		return providerAssessment{Decision: decision, Provider: "disabled_local", AssessedAtUTC: time.Now().UTC().Format(time.RFC3339)}, nil
	}
	fields := map[string]string{
		"icebreaker_id": icebreakerID, "assessment_type": "voice_moderation",
		"transcript": transcript, "content_sha256": recording.SHA256,
	}
	files := map[string]providerEvidenceFile{"audio": {Filename: "voice" + voiceExtension(recording.MimeType), MimeType: recording.MimeType, Content: recording.Content}}
	return p.postMultipart(ctx, fields, files)
}

// Go cannot overload Assess, so the voice interface is satisfied by a small
// adapter while sharing the exact multipart and decision validation code.
type voiceProviderAdapter struct{ client *providerReviewClient }

func (a voiceProviderAdapter) Assess(ctx context.Context, icebreakerID, transcript string, recording voiceRecordingMetadata) (providerAssessment, error) {
	return a.client.AssessVoice(ctx, icebreakerID, transcript, recording)
}

func configuredVoiceModerationProvider(cfg config.Config) voiceModerationProvider {
	return voiceProviderAdapter{client: newVoiceModerationProvider(cfg)}
}

func (p *providerReviewClient) postMultipart(ctx context.Context, fields map[string]string, files map[string]providerEvidenceFile) (providerAssessment, error) {
	if strings.TrimSpace(p.endpoint) == "" {
		return providerAssessment{}, errors.New("provider endpoint is not configured")
	}
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	for key, value := range fields {
		if err := writer.WriteField(key, value); err != nil {
			return providerAssessment{}, err
		}
	}
	for field, file := range files {
		header := make(textproto.MIMEHeader)
		header.Set("Content-Disposition", fmt.Sprintf(`form-data; name=%q; filename=%q`, field, file.Filename))
		header.Set("Content-Type", file.MimeType)
		part, err := writer.CreatePart(header)
		if err != nil {
			return providerAssessment{}, err
		}
		if _, err := part.Write(file.Content); err != nil {
			return providerAssessment{}, err
		}
	}
	if err := writer.Close(); err != nil {
		return providerAssessment{}, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.endpoint, &body)
	if err != nil {
		return providerAssessment{}, err
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	if strings.TrimSpace(p.token) != "" {
		req.Header.Set("Authorization", "Bearer "+strings.TrimSpace(p.token))
	}
	response, err := p.client.Do(req)
	if err != nil {
		return providerAssessment{}, err
	}
	defer response.Body.Close()
	responseBody, _ := io.ReadAll(io.LimitReader(response.Body, 64<<10))
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return providerAssessment{}, fmt.Errorf("provider returned %d: %s", response.StatusCode, strings.TrimSpace(string(responseBody)))
	}
	var assessment providerAssessment
	if err := json.Unmarshal(responseBody, &assessment); err != nil {
		return providerAssessment{}, errors.New("provider returned an invalid assessment")
	}
	assessment.Decision = strings.ToLower(strings.TrimSpace(assessment.Decision))
	if !map[string]bool{"approved": true, "rejected": true, "manual_review": true}[assessment.Decision] {
		return providerAssessment{}, errors.New("provider returned an unsupported decision")
	}
	assessment.Provider = p.provider
	assessment.AssessedAtUTC = time.Now().UTC().Format(time.RFC3339)
	return assessment, nil
}

func voiceExtension(mimeType string) string {
	switch mimeType {
	case "audio/ogg":
		return ".ogg"
	case "audio/mp4":
		return ".m4a"
	case "audio/wav":
		return ".wav"
	default:
		return ".webm"
	}
}
