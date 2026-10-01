package domain

import (
	"errors"
	"regexp"
	"strings"
)

var ErrInvalidUsername = errors.New("invalid username")
var ErrInvalidPassword = errors.New("invalid password")

var usernameRegex = regexp.MustCompile(`^[a-z0-9][a-z0-9._]{1,28}[a-z0-9]$`)

type Username struct {
	value string
}

func NewUsername(raw string) (Username, error) {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	if !usernameRegex.MatchString(normalized) {
		return Username{}, ErrInvalidUsername
	}
	return Username{value: normalized}, nil
}

func (u Username) Value() string {
	return u.value
}

func ValidatePassword(password string) error {
	// Go's bcrypt implementation rejects secrets longer than 72 bytes. Keep
	// signup, recovery and password-change on that same UTF-8 byte contract so
	// a password accepted by one entry point is never rejected by another.
	if len(password) < 8 || len(password) > 72 || !regexp.MustCompile(`[A-Za-z]`).MatchString(password) || !regexp.MustCompile(`[0-9]`).MatchString(password) {
		return ErrInvalidPassword
	}
	return nil
}
