package mobile

import (
	"context"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/rekognition"
	"github.com/aws/aws-sdk-go-v2/service/rekognition/types"
)

type fakeRekognitionModerationClient struct {
	output *rekognition.DetectModerationLabelsOutput
	calls  int
}

func (f *fakeRekognitionModerationClient) DetectModerationLabels(
	_ context.Context,
	_ *rekognition.DetectModerationLabelsInput,
	_ ...func(*rekognition.Options),
) (*rekognition.DetectModerationLabelsOutput, error) {
	f.calls++
	return f.output, nil
}

func TestEvaluateMediaModerationPolicyRejectsHighConfidenceBlockedContent(t *testing.T) {
	result := evaluateMediaModerationPolicy(
		[]mediaModerationLabel{{Name: "Explicit Nudity", Confidence: 97}},
		70,
		90,
		[]string{"suggestive"},
		[]string{"explicit nudity"},
	)
	if result.Status != mediaModerationRejected {
		t.Fatalf("status = %q, want rejected", result.Status)
	}
}

func TestEvaluateMediaModerationPolicyRoutesBorderlineAndReviewCategories(t *testing.T) {
	tests := []mediaModerationLabel{
		{Name: "Explicit Nudity", Confidence: 82},
		{Name: "Graphic Male Nudity", ParentName: "Suggestive", Confidence: 75},
	}
	for _, label := range tests {
		result := evaluateMediaModerationPolicy(
			[]mediaModerationLabel{label},
			70,
			90,
			[]string{"suggestive"},
			[]string{"explicit nudity"},
		)
		if result.Status != mediaModerationReviewRequired {
			t.Fatalf("label %#v produced %q, want review_required", label, result.Status)
		}
	}
}

func TestRekognitionModeratorApprovesCleanJPEG(t *testing.T) {
	client := &fakeRekognitionModerationClient{output: &rekognition.DetectModerationLabelsOutput{
		ModerationModelVersion: aws.String("7.0"),
		ModerationLabels:       []types.ModerationLabel{},
	}}
	moderator := &rekognitionMediaModerator{
		client:           client,
		minConfidence:    50,
		reviewConfidence: 70,
		rejectConfidence: 90,
		rejectLabels:     []string{"explicit nudity"},
		reviewLabels:     []string{"suggestive"},
	}
	result, err := moderator.Moderate(context.Background(), validatedPhotoUpload{
		MimeType: "image/jpeg",
		Content:  []byte{0xff, 0xd8, 0xff},
	})
	if err != nil {
		t.Fatalf("Moderate() error = %v", err)
	}
	if result.Status != mediaModerationApproved || result.ModelVersion != "7.0" || client.calls != 1 {
		t.Fatalf("unexpected result: %#v calls=%d", result, client.calls)
	}
}

func TestRekognitionModeratorRoutesWebPAndHEICWithoutCallingProvider(t *testing.T) {
	for _, mimeType := range []string{"image/webp", "image/heic"} {
		client := &fakeRekognitionModerationClient{}
		moderator := &rekognitionMediaModerator{client: client}
		result, err := moderator.Moderate(context.Background(), validatedPhotoUpload{MimeType: mimeType})
		if err != nil {
			t.Fatalf("Moderate(%s) error = %v", mimeType, err)
		}
		if result.Status != mediaModerationReviewRequired || result.Reason != "provider_unsupported_format" {
			t.Fatalf("Moderate(%s) = %#v", mimeType, result)
		}
		if client.calls != 0 {
			t.Fatalf("provider called for unsupported format %s", mimeType)
		}
	}
}
