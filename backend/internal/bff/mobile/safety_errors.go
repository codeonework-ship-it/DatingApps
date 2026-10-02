package mobile

import (
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"
)

// Report, block and unblock passed every repository error through as 502
// "temporarily unavailable": reporting or blocking yourself, unblocking someone
// you never blocked, and naming a member who does not exist (API-13). Those
// are the caller's mistakes, so they are answered as 4xx before or after the
// command runs; genuine faults stay 502.

// safetyPairProblem validates the two member ids of a report or block.
func safetyPairProblem(actor, target, targetField string) (int, error) {
	if target == "" {
		return 0, nil // the command reports the missing field as a validation error
	}
	if _, err := uuid.Parse(target); err != nil {
		return http.StatusBadRequest, errors.New(targetField + " must be a member id")
	}
	if actor != "" && actor == target {
		return http.StatusBadRequest, errors.New("you cannot do this to yourself")
	}
	return 0, nil
}

// safetyCommandStatus maps a repository error that is really a client mistake
// to a status and a message that names no table or constraint.
func safetyCommandStatus(err error) (int, error, bool) {
	message := strings.ToLower(err.Error())
	switch {
	case strings.Contains(message, "block not found"):
		return http.StatusNotFound, errors.New("you have not blocked this member"), true
	case strings.Contains(message, "violates foreign key"), strings.Contains(message, "sqlstate 23503"):
		return http.StatusNotFound, errors.New("member not found"), true
	case strings.Contains(message, "cannot report yourself"), strings.Contains(message, "valid distinct user_id"):
		return http.StatusBadRequest, errors.New("you cannot do this to yourself"), true
	}
	return 0, nil, false
}
