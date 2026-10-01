package mobile

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/rekognition"
	"github.com/aws/aws-sdk-go-v2/service/rekognition/types"

	"github.com/verified-dating/backend/internal/platform/config"
)

const (
	mediaModerationApproved       = "approved"
	mediaModerationReviewRequired = "review_required"
	mediaModerationRejected       = "rejected"
)

type mediaModerationLabel struct {
	Name       string  `json:"name"`
	ParentName string  `json:"parent_name,omitempty"`
	Confidence float32 `json:"confidence"`
}

type mediaModerationResult struct {
	Status       string                 `json:"status"`
	Provider     string                 `json:"provider"`
	ModelVersion string                 `json:"model_version,omitempty"`
	Reason       string                 `json:"reason,omitempty"`
	Labels       []mediaModerationLabel `json:"labels"`
	DurationMS   int64                  `json:"duration_ms"`
}

type mediaModerator interface {
	Moderate(context.Context, validatedPhotoUpload) (mediaModerationResult, error)
}

type localValidationModerator struct{}

func (localValidationModerator) Moderate(_ context.Context, _ validatedPhotoUpload) (mediaModerationResult, error) {
	return mediaModerationResult{
		Status:       mediaModerationApproved,
		Provider:     "local_validation",
		ModelVersion: "structural-v1",
		Labels:       []mediaModerationLabel{},
	}, nil
}

type rekognitionModerationAPI interface {
	DetectModerationLabels(
		context.Context,
		*rekognition.DetectModerationLabelsInput,
		...func(*rekognition.Options),
	) (*rekognition.DetectModerationLabelsOutput, error)
}

type rekognitionMediaModerator struct {
	client           rekognitionModerationAPI
	minConfidence    float32
	reviewConfidence float32
	rejectConfidence float32
	rejectLabels     []string
	reviewLabels     []string
}

func newMediaModerator(cfg config.Config) (mediaModerator, error) {
	if cfg.MediaModerationProvider != "aws_rekognition" {
		return localValidationModerator{}, nil
	}

	region := strings.TrimSpace(cfg.AWSS3Region)
	if region == "" {
		region = "us-east-1"
	}
	options := []func(*awsconfig.LoadOptions) error{awsconfig.WithRegion(region)}
	if accessKeyID := strings.TrimSpace(cfg.AWSS3AccessKeyID); accessKeyID != "" {
		options = append(options, awsconfig.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			accessKeyID,
			strings.TrimSpace(cfg.AWSS3SecretAccessKey),
			"",
		)))
	}
	if endpoint := strings.TrimRight(strings.TrimSpace(cfg.AWSRekognitionEndpoint), "/"); endpoint != "" {
		options = append(options, awsconfig.WithEndpointResolverWithOptions(aws.EndpointResolverWithOptionsFunc(
			func(service, _ string, _ ...interface{}) (aws.Endpoint, error) {
				if service != rekognition.ServiceID {
					return aws.Endpoint{}, &aws.EndpointNotFoundError{}
				}
				return aws.Endpoint{URL: endpoint, HostnameImmutable: true}, nil
			},
		)))
	}
	awsCfg, err := awsconfig.LoadDefaultConfig(context.Background(), options...)
	if err != nil {
		return nil, fmt.Errorf("load aws configuration for media moderation: %w", err)
	}
	return &rekognitionMediaModerator{
		client:           rekognition.NewFromConfig(awsCfg),
		minConfidence:    float32(cfg.MediaModerationMinConfidence),
		reviewConfidence: float32(cfg.MediaModerationReviewConfidence),
		rejectConfidence: float32(cfg.MediaModerationRejectConfidence),
		rejectLabels:     normalizeModerationLabels(cfg.MediaModerationRejectLabels),
		reviewLabels:     normalizeModerationLabels(cfg.MediaModerationReviewLabels),
	}, nil
}

func (m *rekognitionMediaModerator) Moderate(
	ctx context.Context,
	upload validatedPhotoUpload,
) (mediaModerationResult, error) {
	startedAt := time.Now()
	if upload.MimeType != "image/jpeg" && upload.MimeType != "image/png" {
		return mediaModerationResult{
			Status:       mediaModerationReviewRequired,
			Provider:     "aws_rekognition",
			ModelVersion: "format-routing-v1",
			Reason:       "provider_unsupported_format",
			Labels:       []mediaModerationLabel{},
			DurationMS:   time.Since(startedAt).Milliseconds(),
		}, nil
	}

	output, err := m.client.DetectModerationLabels(ctx, &rekognition.DetectModerationLabelsInput{
		Image:         &types.Image{Bytes: upload.Content},
		MinConfidence: aws.Float32(m.minConfidence),
	})
	if err != nil {
		return mediaModerationResult{}, fmt.Errorf("aws rekognition moderation request failed: %w", err)
	}

	labels := make([]mediaModerationLabel, 0, len(output.ModerationLabels))
	for _, item := range output.ModerationLabels {
		labels = append(labels, mediaModerationLabel{
			Name:       strings.TrimSpace(aws.ToString(item.Name)),
			ParentName: strings.TrimSpace(aws.ToString(item.ParentName)),
			Confidence: aws.ToFloat32(item.Confidence),
		})
	}
	result := evaluateMediaModerationPolicy(
		labels,
		m.reviewConfidence,
		m.rejectConfidence,
		m.reviewLabels,
		m.rejectLabels,
	)
	result.Provider = "aws_rekognition"
	result.ModelVersion = strings.TrimSpace(aws.ToString(output.ModerationModelVersion))
	result.DurationMS = time.Since(startedAt).Milliseconds()
	return result, nil
}

func evaluateMediaModerationPolicy(
	labels []mediaModerationLabel,
	reviewConfidence, rejectConfidence float32,
	reviewLabels, rejectLabels []string,
) mediaModerationResult {
	result := mediaModerationResult{Status: mediaModerationApproved, Labels: labels}
	for _, label := range labels {
		if label.Confidence >= rejectConfidence && moderationLabelMatches(label, rejectLabels) {
			result.Status = mediaModerationRejected
			result.Reason = "blocked_content:" + normalizedModerationLabel(label)
			return result
		}
	}
	for _, label := range labels {
		if label.Confidence < reviewConfidence {
			continue
		}
		if moderationLabelMatches(label, rejectLabels) || moderationLabelMatches(label, reviewLabels) {
			result.Status = mediaModerationReviewRequired
			result.Reason = "manual_review:" + normalizedModerationLabel(label)
			return result
		}
	}
	return result
}

func moderationLabelMatches(label mediaModerationLabel, configured []string) bool {
	name := strings.ToLower(strings.TrimSpace(label.Name))
	parent := strings.ToLower(strings.TrimSpace(label.ParentName))
	for _, candidate := range configured {
		if candidate != "" && (name == candidate || parent == candidate) {
			return true
		}
	}
	return false
}

func normalizedModerationLabel(label mediaModerationLabel) string {
	if value := strings.ToLower(strings.TrimSpace(label.Name)); value != "" {
		return value
	}
	return strings.ToLower(strings.TrimSpace(label.ParentName))
}

func normalizeModerationLabels(values []string) []string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		if normalized := strings.ToLower(strings.TrimSpace(value)); normalized != "" {
			out = append(out, normalized)
		}
	}
	return out
}
