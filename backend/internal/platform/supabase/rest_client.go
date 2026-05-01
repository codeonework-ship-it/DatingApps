package supabase

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type Client struct {
	baseURL     string
	readBaseURL string
	anonKey     string
	serviceKey  string
	httpClient  *http.Client
}

func NewClient(baseURL, anonKey, serviceKey string, timeout time.Duration) *Client {
	if timeout <= 0 {
		timeout = 15 * time.Second
	}
	return &Client{
		baseURL:     strings.TrimRight(baseURL, "/"),
		readBaseURL: "",
		anonKey:     anonKey,
		serviceKey:  serviceKey,
		httpClient:  &http.Client{Timeout: timeout},
	}
}

func (c *Client) SetReadBaseURL(readBaseURL string) {
	c.readBaseURL = strings.TrimRight(strings.TrimSpace(readBaseURL), "/")
}

func (c *Client) Select(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	path := restPath(c.baseURL, table)
	if params == nil {
		params = url.Values{}
	}
	if params.Get("select") == "" {
		params.Set("select", "*")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, path+"?"+params.Encode(), nil)
	if err != nil {
		return nil, err
	}

	resBody, err := c.do(req, schema)
	if err != nil {
		return nil, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(resBody, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *Client) SelectRead(ctx context.Context, schema, table string, params url.Values) ([]map[string]any, error) {
	base := c.baseURL
	if strings.TrimSpace(c.readBaseURL) != "" {
		base = c.readBaseURL
	}

	path := restPath(base, table)
	if params == nil {
		params = url.Values{}
	}
	if params.Get("select") == "" {
		params.Set("select", "*")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, path+"?"+params.Encode(), nil)
	if err != nil {
		return nil, err
	}

	resBody, err := c.do(req, schema)
	if err != nil {
		return nil, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(resBody, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *Client) Insert(ctx context.Context, schema, table string, payload any) ([]map[string]any, error) {
	path := restPath(c.baseURL, table)
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, path, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Prefer", "return=representation")

	resBody, err := c.do(req, schema)
	if err != nil {
		return nil, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(resBody, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *Client) Upsert(ctx context.Context, schema, table string, payload any, onConflict string) ([]map[string]any, error) {
	path := restPath(c.baseURL, table)
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, path, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Prefer", "return=representation,resolution=merge-duplicates")
	if onConflict != "" {
		q := req.URL.Query()
		q.Set("on_conflict", onConflict)
		req.URL.RawQuery = q.Encode()
	}

	resBody, err := c.do(req, schema)
	if err != nil {
		return nil, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(resBody, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *Client) Update(
	ctx context.Context,
	schema,
	table string,
	payload any,
	filters url.Values,
) ([]map[string]any, error) {
	path := restPath(c.baseURL, table)
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	if filters == nil {
		filters = url.Values{}
	}

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPatch,
		path+"?"+filters.Encode(),
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Prefer", "return=representation")

	resBody, err := c.do(req, schema)
	if err != nil {
		return nil, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(resBody, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *Client) Delete(ctx context.Context, schema, table string, filters url.Values) ([]map[string]any, error) {
	path := restPath(c.baseURL, table)
	if filters == nil {
		filters = url.Values{}
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, path+"?"+filters.Encode(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Prefer", "return=representation")

	resBody, err := c.do(req, schema)
	if err != nil {
		return nil, err
	}

	var rows []map[string]any
	if err := json.Unmarshal(resBody, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (c *Client) do(req *http.Request, schema string) ([]byte, error) {
	apiKey := c.anonKey
	if c.serviceKey != "" {
		apiKey = c.serviceKey
	}

	if apiKey != "" {
		req.Header.Set("apikey", apiKey)
		if shouldAttachBearerToken(req.URL.String(), apiKey) {
			req.Header.Set("Authorization", "Bearer "+apiKey)
		}
	}
	req.Header.Set("Content-Type", "application/json")
	if schema != "" {
		req.Header.Set("Accept-Profile", schema)
		req.Header.Set("Content-Profile", schema)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	resBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("supabase request failed: status=%d body=%s", resp.StatusCode, string(resBody))
	}

	return resBody, nil
}

func shouldAttachBearerToken(rawURL, apiKey string) bool {
	trimmedKey := strings.TrimSpace(apiKey)
	if trimmedKey == "" {
		return false
	}
	if looksLikeJWT(trimmedKey) {
		return true
	}
	parsed, err := url.Parse(rawURL)
	if err != nil {
		return true
	}
	host := strings.ToLower(parsed.Hostname())
	return host != "localhost" && host != "127.0.0.1"
}

func looksLikeJWT(value string) bool {
	parts := strings.Split(value, ".")
	return len(parts) == 3 && parts[0] != "" && parts[1] != "" && parts[2] != ""
}

func restPath(baseURL, table string) string {
	base := strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if base == "" {
		return "/" + strings.TrimLeft(table, "/")
	}
	if strings.HasSuffix(base, "/rest/v1") {
		return fmt.Sprintf("%s/%s", base, strings.TrimLeft(table, "/"))
	}
	parsed, err := url.Parse(base)
	if err == nil {
		host := strings.ToLower(parsed.Hostname())
		path := strings.TrimSpace(parsed.Path)
		if (host == "localhost" || host == "127.0.0.1") && (path == "" || path == "/") {
			return fmt.Sprintf("%s/%s", base, strings.TrimLeft(table, "/"))
		}
	}
	return fmt.Sprintf("%s/rest/v1/%s", base, strings.TrimLeft(table, "/"))
}
