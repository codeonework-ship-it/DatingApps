package domain

import (
	"errors"
	"regexp"
	"strings"
)

var ErrInvalidPhone = errors.New("invalid phone number")

type PhoneNumber struct {
	value string
}

var nonDigitRegex = regexp.MustCompile(`[^0-9]`)

func NewPhoneNumber(raw string) (PhoneNumber, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return PhoneNumber{}, ErrInvalidPhone
	}

	digitsOnly := nonDigitRegex.ReplaceAllString(trimmed, "")
	if len(digitsOnly) < 10 {
		return PhoneNumber{}, ErrInvalidPhone
	}

	normalized := strings.ReplaceAll(trimmed, " ", "")
	return PhoneNumber{value: normalized}, nil
}

func (p PhoneNumber) Value() string {
	return p.value
}
