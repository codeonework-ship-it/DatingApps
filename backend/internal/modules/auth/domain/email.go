package domain

import (
	"errors"
	"regexp"
	"strings"
)

var ErrInvalidEmail = errors.New("invalid email")

type Email struct {
	value string
}

var emailRegex = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]+$`)

func NewEmail(raw string) (Email, error) {
	normalized := strings.ToLower(strings.TrimSpace(raw))
	if normalized == "" {
		return Email{}, ErrInvalidEmail
	}
	if !emailRegex.MatchString(normalized) {
		return Email{}, ErrInvalidEmail
	}
	return Email{value: normalized}, nil
}

func (e Email) Value() string {
	return e.value
}
