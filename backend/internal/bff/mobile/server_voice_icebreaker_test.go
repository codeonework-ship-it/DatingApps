package mobile

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_VoiceIcebreakerLifecycle(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	promptsReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/voice-icebreakers/prompts", nil)
	promptsRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(promptsRec, promptsReq)
	if promptsRec.Code != http.StatusOK {
		t.Fatalf("list prompts code=%d body=%s", promptsRec.Code, promptsRec.Body.String())
	}
	promptsPayload := decodeJSONMap(t, promptsRec.Body.Bytes())
	prompts, ok := promptsPayload["prompts"].([]any)
	if !ok || len(prompts) == 0 {
		t.Fatalf("expected prompts in response")
	}
	prompt := toMap(t, prompts[0])
	promptID := stringValue(prompt["id"])

	startBody := `{
		"match_id": "match-voice-1",
		"sender_user_id": "user-voice-a",
		"receiver_user_id": "user-voice-b",
		"prompt_id": "` + promptID + `"
	}`
	startReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/voice-icebreakers/start", strings.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start voice icebreaker code=%d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	icebreaker := toMap(t, startPayload["voice_icebreaker"])
	icebreakerID := stringValue(icebreaker["id"])

	sendReq := voiceRecordingRequest(
		t,
		"/v1/engagement/voice-icebreakers/"+icebreakerID+"/send",
		"user-voice-a",
		"30",
		"A calm Sunday for me is tea, a long walk, and one hour of reading.",
	)
	sendRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(sendRec, sendReq)
	if sendRec.Code != http.StatusOK {
		t.Fatalf("send voice icebreaker code=%d body=%s", sendRec.Code, sendRec.Body.String())
	}

	playBody := `{"user_id":"user-voice-b"}`
	playReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/voice-icebreakers/"+icebreakerID+"/play",
		strings.NewReader(playBody),
	)
	playReq.Header.Set("Content-Type", "application/json")
	playRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(playRec, playReq)
	if playRec.Code != http.StatusOK {
		t.Fatalf("play voice icebreaker code=%d body=%s", playRec.Code, playRec.Body.String())
	}
	playPayload := decodeJSONMap(t, playRec.Body.Bytes())
	playedItem := toMap(t, playPayload["voice_icebreaker"])
	audioURL := stringValue(playedItem["audio_url"])
	if audioURL == "" {
		t.Fatal("expected a signed private playback URL")
	}
	mediaReq := httptest.NewRequest(http.MethodGet, audioURL, nil)
	mediaRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(mediaRec, mediaReq)
	if mediaRec.Code != http.StatusOK || mediaRec.Body.Len() == 0 {
		t.Fatalf("private playback code=%d bytes=%d body=%s", mediaRec.Code, mediaRec.Body.Len(), mediaRec.Body.String())
	}
	if mediaRec.Header().Get("Cache-Control") != "private, no-store" {
		t.Fatalf("unexpected playback cache policy %q", mediaRec.Header().Get("Cache-Control"))
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(50)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "voice_icebreaker_started")
	assertActionSeen(t, activities, "voice_icebreaker_sent")
	assertActionSeen(t, activities, "voice_icebreaker_played")
}

func TestServer_VoiceIcebreakerSinglePerMatchPerDay(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-voice-2",
		"sender_user_id": "user-voice-c",
		"receiver_user_id": "user-voice-d"
	}`

	firstReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/voice-icebreakers/start", strings.NewReader(startBody))
	firstReq.Header.Set("Content-Type", "application/json")
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first start code=%d body=%s", firstRec.Code, firstRec.Body.String())
	}

	secondReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/voice-icebreakers/start", strings.NewReader(startBody))
	secondReq.Header.Set("Content-Type", "application/json")
	secondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusConflict {
		t.Fatalf("expected second start status=409, got code=%d body=%s", secondRec.Code, secondRec.Body.String())
	}
}

func TestServer_VoiceIcebreakerInvalidDuration(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	startBody := `{
		"match_id": "match-voice-3",
		"sender_user_id": "user-voice-e",
		"receiver_user_id": "user-voice-f"
	}`
	startReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/voice-icebreakers/start", strings.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(startRec, startReq)
	if startRec.Code != http.StatusOK {
		t.Fatalf("start code=%d body=%s", startRec.Code, startRec.Body.String())
	}
	startPayload := decodeJSONMap(t, startRec.Body.Bytes())
	icebreaker := toMap(t, startPayload["voice_icebreaker"])
	icebreakerID := stringValue(icebreaker["id"])

	sendReq := voiceRecordingRequest(
		t,
		"/v1/engagement/voice-icebreakers/"+icebreakerID+"/send",
		"user-voice-e",
		"12",
		"Short sample transcript text for validation.",
	)
	sendRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(sendRec, sendReq)
	if sendRec.Code != http.StatusBadRequest {
		t.Fatalf("expected invalid duration status=400, got code=%d body=%s", sendRec.Code, sendRec.Body.String())
	}
}

func voiceRecordingRequest(t *testing.T, target, senderID, duration, transcript string) *http.Request {
	t.Helper()
	var payload bytes.Buffer
	writer := multipart.NewWriter(&payload)
	for key, value := range map[string]string{
		"sender_user_id":   senderID,
		"duration_seconds": duration,
		"transcript":       transcript,
	} {
		if err := writer.WriteField(key, value); err != nil {
			t.Fatalf("write %s: %v", key, err)
		}
	}
	part, err := writer.CreateFormFile("audio", "voice.webm")
	if err != nil {
		t.Fatalf("create audio part: %v", err)
	}
	if _, err := part.Write(append([]byte{0x1a, 0x45, 0xdf, 0xa3}, bytes.Repeat([]byte{0x01}, 1024)...)); err != nil {
		t.Fatalf("write audio fixture: %v", err)
	}
	if err := writer.Close(); err != nil {
		t.Fatalf("close multipart: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, target, &payload)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	return req
}
