package mobile

import (
	"errors"
	"fmt"
	"net/http"
)

// questRuleError is a business-rule violation in the match quest workflow
// (self review, nothing pending, cooldown, rate limit). It carries the HTTP
// status the BFF should answer with, so these are reported as client errors
// instead of 502 "service temporarily unavailable" (API-02).
type questRuleError struct {
	status  int
	code    string
	message string
}

func (e *questRuleError) Error() string { return e.message }

var (
	errQuestSelfReview = &questRuleError{
		status:  http.StatusForbidden,
		code:    "QUEST_SELF_REVIEW",
		message: "you can't review your own quest response; the other member of the match reviews it",
	}
	errQuestNotPending = &questRuleError{
		status:  http.StatusConflict,
		code:    "QUEST_NOT_PENDING",
		message: "quest submission is not pending review",
	}
	errQuestSubmissionNotFound = &questRuleError{
		status:  http.StatusNotFound,
		code:    "QUEST_SUBMISSION_NOT_FOUND",
		message: "quest submission not found for match",
	}
	errQuestTemplateNotFound = &questRuleError{
		status:  http.StatusNotFound,
		code:    "QUEST_TEMPLATE_NOT_FOUND",
		message: "quest template not found for match",
	}
	errQuestCooldown = &questRuleError{
		status:  http.StatusConflict,
		code:    "QUEST_COOLDOWN",
		message: "quest submission is in cooldown period",
	}
	errQuestRateLimited = &questRuleError{
		status:  http.StatusTooManyRequests,
		code:    "QUEST_RATE_LIMITED",
		message: "quest submission rate limit exceeded",
	}
	errQuestInvalidDecision = &questRuleError{
		status:  http.StatusBadRequest,
		code:    "QUEST_INVALID_DECISION",
		message: "invalid decision status",
	}
)

func questResponseLengthError(minChars, maxChars int) error {
	return &questRuleError{
		status:  http.StatusBadRequest,
		code:    "QUEST_RESPONSE_LENGTH",
		message: fmt.Sprintf("response text must be between %d and %d characters", minChars, maxChars),
	}
}

// questWorkflowErrorStatus maps a quest workflow error to an HTTP status and
// error code. ok is false for errors that are not business-rule violations
// (infrastructure failures), which keep their 5xx handling.
func questWorkflowErrorStatus(err error) (status int, code string, ok bool) {
	var ruleErr *questRuleError
	if errors.As(err, &ruleErr) {
		return ruleErr.status, ruleErr.code, true
	}
	if errors.Is(err, errUnauthorizedQuestAction) {
		return http.StatusForbidden, "QUEST_NOT_A_PARTICIPANT", true
	}
	return 0, "", false
}

// writeQuestWorkflowRuleError writes a 4xx for quest business-rule errors and
// reports whether it handled the error.
func writeQuestWorkflowRuleError(w http.ResponseWriter, err error) bool {
	status, code, ok := questWorkflowErrorStatus(err)
	if !ok {
		return false
	}
	message := err.Error()
	var ruleErr *questRuleError
	if errors.As(err, &ruleErr) {
		message = ruleErr.message
	} else if errors.Is(err, errUnauthorizedQuestAction) {
		message = "only members of this match can take part in its quest"
	}
	writeJSON(w, status, map[string]any{
		"success":    false,
		"error":      message,
		"error_code": code,
	})
	return true
}
