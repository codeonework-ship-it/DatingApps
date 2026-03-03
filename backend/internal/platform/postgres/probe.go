package postgres

import (
	"context"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
	"time"
)

func Probe(databaseURL, host string, port int, timeout time.Duration) error {
	resolvedHost := strings.TrimSpace(host)
	resolvedPort := port

	if resolvedHost == "" {
		parsedHost, parsedPort, err := parseHostPortFromDatabaseURL(databaseURL)
		if err != nil {
			return err
		}
		resolvedHost = parsedHost
		resolvedPort = parsedPort
	}

	if resolvedHost == "" {
		return fmt.Errorf("database host is required for postgres probe")
	}
	if resolvedPort <= 0 {
		resolvedPort = 5432
	}
	if timeout <= 0 {
		timeout = 5 * time.Second
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	dialer := &net.Dialer{}
	conn, err := dialer.DialContext(
		ctx,
		"tcp",
		net.JoinHostPort(resolvedHost, strconv.Itoa(resolvedPort)),
	)
	if err != nil {
		return fmt.Errorf("postgres tcp probe failed: %w", err)
	}
	_ = conn.Close()
	return nil
}

func parseHostPortFromDatabaseURL(databaseURL string) (string, int, error) {
	trimmed := strings.TrimSpace(databaseURL)
	if trimmed == "" {
		return "", 0, fmt.Errorf("database url is empty")
	}

	parsed, err := url.Parse(trimmed)
	if err != nil {
		return "", 0, fmt.Errorf("invalid database url: %w", err)
	}

	host := parsed.Hostname()
	if host == "" {
		return "", 0, fmt.Errorf("database url missing hostname")
	}

	port := 5432
	if rawPort := strings.TrimSpace(parsed.Port()); rawPort != "" {
		parsedPort, convErr := strconv.Atoi(rawPort)
		if convErr != nil {
			return "", 0, fmt.Errorf("invalid database url port: %w", convErr)
		}
		port = parsedPort
	}

	return host, port, nil
}
