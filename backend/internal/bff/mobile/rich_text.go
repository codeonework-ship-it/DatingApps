package mobile

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"
)

// Rich writing for Open Chapters and profile stories (migration 127).
//
// Formatting is a small, closed block model, never HTML. One block is one line
// of the plain text: blocks joined with "\n" give the `body`/`text` that search,
// excerpts, notifications, moderation, wall cards and older clients already
// use. The server derives that plain text itself, so formatting can never
// disagree with what moderators and older apps see.
// See documents/RICH_TEXT_WRITING_STYLES_2026-10-01.md.

const richDocVersion = 1

// Writing styles map to fonts bundled with the app and the website; no network
// fonts are ever requested.
var richWritingStyles = map[string]bool{"classic": true, "modern": true, "journal": true, "typewriter": true, "poetic": true}

const richDefaultStyle = "modern"

var richBlockTypes = map[string]bool{"paragraph": true, "heading": true, "subheading": true, "quote": true, "bullet": true, "numbered": true, "divider": true, "callout": true}

// Canonical mark order keeps stored documents byte-stable for retry checks.
var richMarkOrder = []string{"bold", "italic", "underline", "strikethrough", "highlight", "link"}
var richMarkRank = func() map[string]int {
	out := map[string]int{}
	for i, m := range richMarkOrder {
		out[m] = i
	}
	return out
}()

const (
	richBulletPrefix = "• "
	richDivider      = "* * *"
	richMaxHrefBytes = 2048
	richMaxSpans     = 200
)

type richSpan struct {
	Text  string   `json:"text"`
	Marks []string `json:"marks,omitempty"`
	Href  string   `json:"href,omitempty"`
}
type richBlock struct {
	Type  string     `json:"type"`
	Align string     `json:"align,omitempty"`
	Spans []richSpan `json:"spans,omitempty"`
}
type richDoc struct {
	Version int         `json:"version"`
	Style   string      `json:"style"`
	Blocks  []richBlock `json:"blocks"`
}

type richLimits struct {
	MaxRunes, MaxBlocks, MaxBytes int
	// TooLong is the member-facing message when the derived text is too long.
	TooLong string
}

var (
	blogRichLimits  = richLimits{MaxRunes: 8000, MaxBlocks: 400, MaxBytes: 96 * 1024, TooLong: "Use up to 100 characters for the title and 8,000 for the story"}
	storyRichLimits = richLimits{MaxRunes: 400, MaxBlocks: 40, MaxBytes: 12 * 1024, TooLong: "Use up to 400 characters per story"}
)

type richTextError string

func (e richTextError) Error() string { return string(e) }

var (
	errRichShape = richTextError("Formatting could not be read. Use the editor's toolbar; HTML and unknown formatting are not accepted.")
	errRichLink  = richTextError("Links must be complete https:// addresses")
)

// parseRichDoc validates and normalises an optional rich document from a
// decoded JSON request. nil means "no formatting" (a plain-text save).
func parseRichDoc(raw any, limits richLimits) (*richDoc, error) {
	if raw == nil {
		return nil, nil
	}
	// A string (for example "<p>hi</p>") is rejected: only the block model is accepted.
	if _, ok := raw.(map[string]any); !ok {
		return nil, errRichShape
	}
	encoded, err := json.Marshal(raw)
	if err != nil || len(encoded) > limits.MaxBytes {
		return nil, richTextError("This story has too much formatting. Simplify it and try again.")
	}
	decoder := json.NewDecoder(bytes.NewReader(encoded))
	decoder.DisallowUnknownFields()
	var doc richDoc
	if err = decoder.Decode(&doc); err != nil {
		return nil, errRichShape
	}
	if doc.Version != richDocVersion {
		return nil, errRichShape
	}
	if doc.Style == "" {
		doc.Style = richDefaultStyle
	}
	if !richWritingStyles[doc.Style] {
		return nil, richTextError("Choose an available writing style")
	}
	if doc.Blocks == nil {
		doc.Blocks = []richBlock{}
	}
	if len(doc.Blocks) > limits.MaxBlocks {
		return nil, richTextError("This story has too many paragraphs. Combine some and try again.")
	}
	for i := range doc.Blocks {
		if err = normaliseRichBlock(&doc.Blocks[i]); err != nil {
			return nil, err
		}
	}
	if utf8.RuneCountInString(strings.TrimSpace(richPlainText(&doc))) > limits.MaxRunes {
		return nil, richTextError(limits.TooLong)
	}
	return &doc, nil
}

func normaliseRichBlock(b *richBlock) error {
	if !richBlockTypes[b.Type] {
		return errRichShape
	}
	switch b.Align {
	case "", "start":
		b.Align = ""
	case "center", "end":
	default:
		return errRichShape
	}
	if len(b.Spans) > richMaxSpans {
		return richTextError("This story has too much formatting. Simplify it and try again.")
	}
	if b.Type == "divider" {
		if len(b.Spans) > 0 {
			return errRichShape
		}
		b.Align = ""
		return nil
	}
	spans := make([]richSpan, 0, len(b.Spans))
	for _, s := range b.Spans {
		if err := normaliseRichSpan(&s); err != nil {
			return err
		}
		if s.Text == "" {
			continue
		}
		// Merge neighbours with identical formatting.
		if n := len(spans); n > 0 && spans[n-1].Href == s.Href && strings.Join(spans[n-1].Marks, ",") == strings.Join(s.Marks, ",") {
			spans[n-1].Text += s.Text
			continue
		}
		spans = append(spans, s)
	}
	b.Spans = spans
	return nil
}

func normaliseRichSpan(s *richSpan) error {
	if !utf8.ValidString(s.Text) {
		return errRichShape
	}
	for _, r := range s.Text {
		// One block is one line; control characters (other than tab) never render.
		if r == '\n' || r == '\r' || r == ' ' || r == ' ' || (unicode.IsControl(r) && r != '\t') {
			return errRichShape
		}
	}
	seen := map[string]bool{}
	for _, m := range s.Marks {
		if _, ok := richMarkRank[m]; !ok || seen[m] {
			return errRichShape
		}
		seen[m] = true
	}
	sort.Slice(s.Marks, func(i, j int) bool { return richMarkRank[s.Marks[i]] < richMarkRank[s.Marks[j]] })
	if len(s.Marks) == 0 {
		s.Marks = nil
	}
	if seen["link"] != (s.Href != "") {
		return errRichLink
	}
	if s.Href != "" {
		href, err := normaliseRichHref(s.Href)
		if err != nil {
			return err
		}
		s.Href = href
	}
	return nil
}

// Only absolute https links to a named host. No credentials, scripts, data:,
// mailto:, relative or protocol-relative URLs.
func normaliseRichHref(raw string) (string, error) {
	if len(raw) > richMaxHrefBytes || strings.TrimSpace(raw) != raw {
		return "", errRichLink
	}
	for _, r := range raw {
		if unicode.IsControl(r) || unicode.IsSpace(r) {
			return "", errRichLink
		}
	}
	u, err := url.Parse(raw)
	if err != nil || !strings.EqualFold(u.Scheme, "https") || u.Host == "" || u.User != nil || u.Opaque != "" || u.Hostname() == "" {
		return "", errRichLink
	}
	u.Scheme = "https"
	return u.String(), nil
}

// richBlockText is a block's own text without any list prefix.
func richBlockText(b richBlock) string {
	var out strings.Builder
	for _, s := range b.Spans {
		out.WriteString(s.Text)
	}
	return out.String()
}

// richLinePrefix is the plain-text marker a block contributes before its text.
// number is the 1-based position in a run of consecutive numbered blocks.
func richLinePrefix(b richBlock, number int) string {
	switch b.Type {
	case "bullet":
		return richBulletPrefix
	case "numbered":
		return strconv.Itoa(number) + ". "
	case "divider":
		return richDivider
	}
	return ""
}

// richPlainText derives the plain text exactly as the editors display it:
// one line per block, list markers included, dividers as "* * *".
func richPlainText(doc *richDoc) string {
	if doc == nil {
		return ""
	}
	lines := make([]string, len(doc.Blocks))
	number := 0
	for i, b := range doc.Blocks {
		if b.Type == "numbered" {
			number++
		} else {
			number = 0
		}
		lines[i] = richLinePrefix(b, number) + richBlockText(b)
	}
	return strings.Join(lines, "\n")
}

// richSlice returns the part of doc that renders excerpt (an exact substring of
// its plain text), keeping block types, alignment and inline marks. It returns
// nil when the excerpt is not found, so callers fall back to plain text.
func richSlice(doc *richDoc, excerpt string) *richDoc {
	if doc == nil || excerpt == "" {
		return nil
	}
	plain := richPlainText(doc)
	start := strings.Index(plain, excerpt)
	if start < 0 {
		return nil
	}
	end := start + len(excerpt)
	out := &richDoc{Version: doc.Version, Style: doc.Style, Blocks: []richBlock{}}
	offset, number := 0, 0
	for _, b := range doc.Blocks {
		if b.Type == "numbered" {
			number++
		} else {
			number = 0
		}
		prefix := richLinePrefix(b, number)
		text := richBlockText(b)
		lineStart, lineEnd := offset, offset+len(prefix)+len(text)
		offset = lineEnd + 1
		from, to := max(start, lineStart), min(end, lineEnd)
		if lineStart == lineEnd {
			// Blank lines inside the excerpt keep the author's spacing.
			if lineStart > start && lineStart < end {
				out.Blocks = append(out.Blocks, richBlock{Type: b.Type, Align: b.Align})
			}
			continue
		}
		if from >= to {
			continue
		}
		if b.Type == "divider" {
			out.Blocks = append(out.Blocks, richBlock{Type: "divider"})
			continue
		}
		contentStart := lineStart + len(prefix)
		cs, ce := max(from, contentStart)-contentStart, to-contentStart
		if ce <= cs {
			continue
		}
		out.Blocks = append(out.Blocks, richBlock{Type: b.Type, Align: b.Align, Spans: richSliceSpans(b.Spans, cs, ce)})
	}
	return out
}

func richSliceSpans(spans []richSpan, from, to int) []richSpan {
	out := []richSpan{}
	pos := 0
	for _, s := range spans {
		a, z := pos, pos+len(s.Text)
		pos = z
		lo, hi := max(a, from), min(z, to)
		if lo >= hi {
			continue
		}
		part := s
		part.Text = s.Text[lo-a : hi-a]
		out = append(out, part)
	}
	return out
}

// richDocEqual compares two normalised documents (nil equals nil only).
func richDocEqual(a, b *richDoc) bool {
	if a == nil || b == nil {
		return a == nil && b == nil
	}
	x, errX := json.Marshal(a)
	y, errY := json.Marshal(b)
	return errX == nil && errY == nil && bytes.Equal(x, y)
}

// richDocJSON encodes a document for a nullable JSONB column.
func richDocJSON(doc *richDoc) (any, error) {
	if doc == nil {
		return nil, nil
	}
	raw, err := json.Marshal(doc)
	if err != nil {
		return nil, err
	}
	return string(raw), nil
}

// decodeStoredRichDoc reads a nullable JSONB column. Stored documents were
// validated on write; anything unreadable is dropped so plain text still shows.
func decodeStoredRichDoc(raw []byte) *richDoc {
	if len(raw) == 0 || string(raw) == "null" {
		return nil
	}
	var doc richDoc
	if err := json.Unmarshal(raw, &doc); err != nil || doc.Version != richDocVersion {
		return nil
	}
	return &doc
}

func isRichTextError(err error) bool {
	var e richTextError
	return errors.As(err, &e)
}
