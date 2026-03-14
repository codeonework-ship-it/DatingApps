package mobile

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_GroupCoffeePollLifecycle(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"creator_user_id": "user-poll-a",
		"participant_user_ids": ["user-poll-b", "user-poll-c"],
		"options": [
			{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"},
			{"day": "Sunday", "time_window": "11:00-13:00", "neighborhood": "Koramangala"}
		]
	}`
	createReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(createBody))
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("create poll code=%d body=%s", createRec.Code, createRec.Body.String())
	}

	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	poll := toMap(t, createPayload["poll"])
	pollID := stringValue(poll["id"])
	if pollID == "" {
		t.Fatalf("expected poll id")
	}
	options := poll["options"].([]any)
	option1 := toMap(t, options[0])
	option1ID := stringValue(option1["id"])

	voteBody := `{"user_id":"user-poll-b","option_id":"` + option1ID + `"}`
	voteReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls/"+pollID+"/votes", strings.NewReader(voteBody))
	voteReq.Header.Set("Content-Type", "application/json")
	voteRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(voteRec, voteReq)
	if voteRec.Code != http.StatusOK {
		t.Fatalf("vote poll code=%d body=%s", voteRec.Code, voteRec.Body.String())
	}

	finalizeBody := `{"user_id":"user-poll-a"}`
	finalizeReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls/"+pollID+"/finalize", strings.NewReader(finalizeBody))
	finalizeReq.Header.Set("Content-Type", "application/json")
	finalizeRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(finalizeRec, finalizeReq)
	if finalizeRec.Code != http.StatusOK {
		t.Fatalf("finalize poll code=%d body=%s", finalizeRec.Code, finalizeRec.Body.String())
	}

	finalizePayload := decodeJSONMap(t, finalizeRec.Body.Bytes())
	selected := toMap(t, finalizePayload["selected_option"])
	if got := stringValue(selected["id"]); got == "" {
		t.Fatalf("expected selected option id")
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(60)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "intro_event_created")
	assertActionSeen(t, activities, "intro_event_voted")
	assertActionSeen(t, activities, "intro_event_finalized")
	assertActionSeen(t, activities, "group_poll_created")
	assertActionSeen(t, activities, "group_poll_voted")
	assertActionSeen(t, activities, "group_poll_finalized")
}

func TestServer_GroupCoffeePollParticipantCap(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	body := `{
		"creator_user_id": "user-poll-cap",
		"participant_user_ids": ["u1", "u2", "u3", "u4"],
		"options": [
			{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"}
		]
	}`
	req := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected participant cap status=400, got code=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestServer_GroupCoffeePollVoteByNonParticipant(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"creator_user_id": "user-poll-d",
		"participant_user_ids": ["user-poll-e"],
		"options": [
			{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"}
		]
	}`
	createReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(createBody))
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("create poll code=%d body=%s", createRec.Code, createRec.Body.String())
	}

	payload := decodeJSONMap(t, createRec.Body.Bytes())
	poll := toMap(t, payload["poll"])
	pollID := stringValue(poll["id"])
	options := poll["options"].([]any)
	optionID := stringValue(toMap(t, options[0])["id"])

	voteBody := `{"user_id":"user-outsider","option_id":"` + optionID + `"}`
	voteReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls/"+pollID+"/votes", strings.NewReader(voteBody))
	voteReq.Header.Set("Content-Type", "application/json")
	voteRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(voteRec, voteReq)
	if voteRec.Code != http.StatusForbidden {
		t.Fatalf("expected outsider vote status=403, got code=%d body=%s", voteRec.Code, voteRec.Body.String())
	}
}

func TestServer_GetGroupCoffeePollState(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createBody := `{
		"creator_user_id": "user-poll-read-a",
		"participant_user_ids": ["user-poll-read-b"],
		"options": [
			{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"},
			{"day": "Sunday", "time_window": "11:00-13:00", "neighborhood": "Koramangala"}
		]
	}`
	createReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(createBody))
	createReq.Header.Set("Content-Type", "application/json")
	createRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createRec, createReq)
	if createRec.Code != http.StatusOK {
		t.Fatalf("create poll code=%d body=%s", createRec.Code, createRec.Body.String())
	}
	createPayload := decodeJSONMap(t, createRec.Body.Bytes())
	poll := toMap(t, createPayload["poll"])
	pollID := stringValue(poll["id"])
	optionID := stringValue(toMap(t, poll["options"].([]any)[0])["id"])

	voteBody := `{"user_id":"user-poll-read-b","option_id":"` + optionID + `"}`
	voteReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls/"+pollID+"/votes", strings.NewReader(voteBody))
	voteReq.Header.Set("Content-Type", "application/json")
	voteRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(voteRec, voteReq)
	if voteRec.Code != http.StatusOK {
		t.Fatalf("vote code=%d body=%s", voteRec.Code, voteRec.Body.String())
	}

	getReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls/"+pollID, nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get poll code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	getPoll := toMap(t, getPayload["poll"])
	if got := stringValue(getPoll["id"]); got != pollID {
		t.Fatalf("expected poll id %q, got %q", pollID, got)
	}
	options := getPoll["options"].([]any)
	first := toMap(t, options[0])
	if got := int(first["votes_count"].(float64)); got != 1 {
		t.Fatalf("expected votes_count=1, got %d", got)
	}
}

func TestServer_GetGroupCoffeePollNotFound(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls/coffee-poll-missing", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected missing poll status=404, got code=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestServer_ListGroupCoffeePollsByUserAndStatus(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	createOpenBody := `{
		"creator_user_id": "user-poll-list-a",
		"participant_user_ids": ["user-poll-list-b"],
		"options": [
			{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "Indiranagar"}
		]
	}`
	createOpenReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(createOpenBody))
	createOpenReq.Header.Set("Content-Type", "application/json")
	createOpenRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createOpenRec, createOpenReq)
	if createOpenRec.Code != http.StatusOK {
		t.Fatalf("create open poll code=%d body=%s", createOpenRec.Code, createOpenRec.Body.String())
	}
	createOpenPayload := decodeJSONMap(t, createOpenRec.Body.Bytes())
	openPoll := toMap(t, createOpenPayload["poll"])

	createFinalizedBody := `{
		"creator_user_id": "user-poll-list-a",
		"participant_user_ids": ["user-poll-list-c"],
		"options": [
			{"day": "Sunday", "time_window": "11:00-13:00", "neighborhood": "Koramangala"}
		]
	}`
	createFinalizedReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(createFinalizedBody))
	createFinalizedReq.Header.Set("Content-Type", "application/json")
	createFinalizedRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(createFinalizedRec, createFinalizedReq)
	if createFinalizedRec.Code != http.StatusOK {
		t.Fatalf("create finalized poll code=%d body=%s", createFinalizedRec.Code, createFinalizedRec.Body.String())
	}
	createFinalizedPayload := decodeJSONMap(t, createFinalizedRec.Body.Bytes())
	finalizedPoll := toMap(t, createFinalizedPayload["poll"])
	finalizedPollID := stringValue(finalizedPoll["id"])

	finalizeReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/group-coffee-polls/"+finalizedPollID+"/finalize",
		strings.NewReader(`{"user_id":"user-poll-list-a"}`),
	)
	finalizeReq.Header.Set("Content-Type", "application/json")
	finalizeRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(finalizeRec, finalizeReq)
	if finalizeRec.Code != http.StatusOK {
		t.Fatalf("finalize poll code=%d body=%s", finalizeRec.Code, finalizeRec.Body.String())
	}

	listAllReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls?user_id=user-poll-list-a", nil)
	listAllRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listAllRec, listAllReq)
	if listAllRec.Code != http.StatusOK {
		t.Fatalf("list all polls code=%d body=%s", listAllRec.Code, listAllRec.Body.String())
	}
	listAllPayload := decodeJSONMap(t, listAllRec.Body.Bytes())
	allPolls, ok := listAllPayload["polls"].([]any)
	if !ok {
		t.Fatalf("expected polls array")
	}
	if len(allPolls) != 2 {
		t.Fatalf("expected 2 polls, got %d", len(allPolls))
	}

	listOpenReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls?user_id=user-poll-list-a&status=open", nil)
	listOpenRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listOpenRec, listOpenReq)
	if listOpenRec.Code != http.StatusOK {
		t.Fatalf("list open polls code=%d body=%s", listOpenRec.Code, listOpenRec.Body.String())
	}
	listOpenPayload := decodeJSONMap(t, listOpenRec.Body.Bytes())
	openPolls := listOpenPayload["polls"].([]any)
	if len(openPolls) != 1 {
		t.Fatalf("expected 1 open poll, got %d", len(openPolls))
	}
	if got := stringValue(toMap(t, openPolls[0])["id"]); got != stringValue(openPoll["id"]) {
		t.Fatalf("expected open poll id %q, got %q", stringValue(openPoll["id"]), got)
	}

	listFinalizedReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls?user_id=user-poll-list-a&status=finalized", nil)
	listFinalizedRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listFinalizedRec, listFinalizedReq)
	if listFinalizedRec.Code != http.StatusOK {
		t.Fatalf("list finalized polls code=%d body=%s", listFinalizedRec.Code, listFinalizedRec.Body.String())
	}
	listFinalizedPayload := decodeJSONMap(t, listFinalizedRec.Body.Bytes())
	finalizedPolls := listFinalizedPayload["polls"].([]any)
	if len(finalizedPolls) != 1 {
		t.Fatalf("expected 1 finalized poll, got %d", len(finalizedPolls))
	}
	if got := stringValue(toMap(t, finalizedPolls[0])["id"]); got != finalizedPollID {
		t.Fatalf("expected finalized poll id %q, got %q", finalizedPollID, got)
	}
}

func TestServer_ListGroupCoffeePollsRequiresUserID(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected missing user_id status=400, got code=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestServer_ListGroupCoffeePollsLimitValidAndInvalid(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	for i := 0; i < 3; i++ {
		body := fmt.Sprintf(`{
			"creator_user_id": "user-poll-limit-a",
			"participant_user_ids": ["user-poll-limit-b"],
			"options": [
				{"day": "Saturday", "time_window": "10:00-12:00", "neighborhood": "N%d"}
			]
		}`, i)
		req := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("create poll[%d] code=%d body=%s", i, rec.Code, rec.Body.String())
		}
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls?user_id=user-poll-limit-a&limit=2", nil)
	listRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list with valid limit code=%d body=%s", listRec.Code, listRec.Body.String())
	}
	listPayload := decodeJSONMap(t, listRec.Body.Bytes())
	polls := listPayload["polls"].([]any)
	if len(polls) != 2 {
		t.Fatalf("expected 2 polls for limit=2, got %d", len(polls))
	}

	invalidReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls?user_id=user-poll-limit-a&limit=oops", nil)
	invalidRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(invalidRec, invalidReq)
	if invalidRec.Code != http.StatusBadRequest {
		t.Fatalf("expected invalid limit status=400, got code=%d body=%s", invalidRec.Code, invalidRec.Body.String())
	}
}

func TestServer_ListGroupCoffeePollsLimitMaxCap(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	for i := 0; i < 205; i++ {
		body := fmt.Sprintf(`{
			"creator_user_id": "user-poll-limit-cap-a",
			"participant_user_ids": ["user-poll-limit-cap-b"],
			"options": [
				{"day": "Sunday", "time_window": "11:00-13:00", "neighborhood": "C%d"}
			]
		}`, i)
		req := httptest.NewRequest(http.MethodPost, "/v1/engagement/group-coffee-polls", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("create poll[%d] code=%d body=%s", i, rec.Code, rec.Body.String())
		}
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/group-coffee-polls?user_id=user-poll-limit-cap-a&limit=500", nil)
	listRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(listRec, listReq)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list with capped limit code=%d body=%s", listRec.Code, listRec.Body.String())
	}
	listPayload := decodeJSONMap(t, listRec.Body.Bytes())
	polls := listPayload["polls"].([]any)
	if len(polls) != 200 {
		t.Fatalf("expected capped poll count=200, got %d", len(polls))
	}
}
