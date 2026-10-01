package mobile

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
	"github.com/google/uuid"
)

// Writing copilot (migration 097): "AI on your side, not pretending to be
// you." It drafts an opener, a reply or a date idea from the other member's
// public profile and the last few messages. It never sends. A message sent
// from a draft carries an assisted mark the other member can see.

const (
	copilotDailyDraftLimit  = 10
	copilotContextMessages  = 6
	copilotMaxDraftRunes    = 280
	copilotDefaultModel     = "claude-opus-5"
	copilotProviderTemplate = "template"
	copilotProviderClaude   = "claude"
)

var (
	errCopilotLimit     = errors.New("you have used today's drafts; write this one yourself")
	errCopilotNoProfile = errors.New("the other member's profile is not available")
	errCopilotUnlocked  = errors.New("unlock the conversation before drafting")
	errCopilotProvider  = errors.New("the copilot is unavailable right now")
	allowedCopilotKinds = map[string]bool{"opener": true, "reply": true, "plan_idea": true}
	allowedCopilotTones = map[string]bool{"warm": true, "playful": true, "direct": true}
	copilotDisclosure   = "Say it in your own words. If you send it as drafted, they will see it was written with help."
)

type copilotRequest struct {
	Kind        string
	Tone        string
	ViewerName  string
	PartnerName string
	Profile     map[string]any // allowlisted public projection of the partner
	Recent      []copilotTurn  // oldest first
}

type copilotTurn struct {
	FromViewer bool
	Text       string
}

type copilotResult struct {
	Text     string
	Provider string
	Model    string
}

type copilotProvider interface {
	Draft(ctx context.Context, req copilotRequest) (copilotResult, error)
}

// ── Template provider: deterministic, offline, always available ──────────────

type templateCopilot struct{}

func firstString(values any, limit int) []string {
	out := []string{}
	items, ok := values.([]any)
	if !ok {
		if strs, ok := values.([]string); ok {
			for _, s := range strs {
				items = append(items, s)
			}
		}
	}
	for _, item := range items {
		s := strings.TrimSpace(toString(item))
		if s != "" {
			out = append(out, s)
		}
		if len(out) >= limit {
			break
		}
	}
	return out
}

func (templateCopilot) Draft(_ context.Context, req copilotRequest) (copilotResult, error) {
	name := strings.TrimSpace(req.PartnerName)
	if name == "" {
		name = "there"
	}
	hobbies := firstString(req.Profile["hobbies"], 2)
	intents := firstString(req.Profile["intent_tags"], 1)
	profession := strings.TrimSpace(toString(req.Profile["profession"]))
	city := strings.TrimSpace(toString(req.Profile["city"]))
	hook := ""
	switch {
	case len(hobbies) > 0:
		hook = hobbies[0]
	case profession != "":
		hook = profession
	case city != "":
		hook = city
	}
	var text string
	switch req.Kind {
	case "opener":
		switch {
		case len(hobbies) > 0 && req.Tone == "playful":
			text = fmt.Sprintf("Hi %s! Two questions: how did you get into %s, and are you any good? Be honest.", name, hobbies[0])
		case len(hobbies) > 0 && req.Tone == "direct":
			text = fmt.Sprintf("Hi %s. Your profile mentions %s, which I like. What are you looking for here?", name, hobbies[0])
		case len(hobbies) > 0:
			text = fmt.Sprintf("Hi %s, I noticed %s on your profile. What got you started with it?", name, hobbies[0])
		case profession != "":
			text = fmt.Sprintf("Hi %s! What does a normal week look like for a %s?", name, strings.ToLower(profession))
		case city != "":
			text = fmt.Sprintf("Hi %s, fellow %s person here. What is your favourite corner of the city?", name, city)
		default:
			text = fmt.Sprintf("Hi %s! Your profile made me smile. What is something you are into that most people would not guess?", name)
		}
	case "reply":
		last := ""
		for i := len(req.Recent) - 1; i >= 0; i-- {
			if !req.Recent[i].FromViewer {
				last = strings.TrimSpace(req.Recent[i].Text)
				break
			}
		}
		switch {
		case last != "" && strings.HasSuffix(last, "?"):
			text = "Good question. Honestly, " + strings.ToLower(firstWords(last, 6)) + "... let me think about that properly and answer for real: "
		case last != "":
			text = fmt.Sprintf("I liked that you said \"%s\". Tell me more about that side of you.", firstWords(last, 8))
		case hook != "":
			text = fmt.Sprintf("I keep thinking about the %s thing. What is the story there?", hook)
		default:
			text = "I would rather hear it from you than guess: what made you smile today?"
		}
	case "plan_idea":
		switch {
		case len(intents) > 0 && strings.Contains(strings.ToLower(intents[0]), "serious"):
			text = fmt.Sprintf("How about a proper coffee this weekend, %s? Somewhere quiet where we can actually talk. I can propose a time here.", name)
		case len(hobbies) > 0:
			text = fmt.Sprintf("Since you are into %s, want to do something around that this week? A walk and a coffee after works too. I can send a plan here.", hobbies[0])
		default:
			text = fmt.Sprintf("Want to turn this into a coffee this week, %s? Public place, an hour, no pressure. I can propose a time here.", name)
		}
	}
	return copilotResult{Text: clampDraft(text), Provider: copilotProviderTemplate, Model: "template-v1"}, nil
}

func firstWords(text string, n int) string {
	words := strings.Fields(text)
	if len(words) > n {
		words = words[:n]
	}
	return strings.Join(words, " ")
}

func clampDraft(text string) string {
	text = strings.TrimSpace(text)
	if utf8.RuneCountInString(text) <= copilotMaxDraftRunes {
		return text
	}
	runes := []rune(text)
	return strings.TrimSpace(string(runes[:copilotMaxDraftRunes-1])) + "…"
}

// ── Claude provider: the official Anthropic Go SDK ───────────────────────────

type claudeCopilot struct {
	client anthropic.Client
	model  string
}

func newClaudeCopilot(apiKey, model string) *claudeCopilot {
	if strings.TrimSpace(model) == "" {
		model = copilotDefaultModel
	}
	opts := []option.RequestOption{}
	if strings.TrimSpace(apiKey) != "" {
		opts = append(opts, option.WithAPIKey(apiKey))
	}
	return &claudeCopilot{client: anthropic.NewClient(opts...), model: model}
}

const copilotSystemPrompt = `You help a dating-app member write one short message in their own voice. Rules:
- Write in first person as the member. One message, at most 280 characters, no emoji spam, no hashtags.
- Use only facts given in the profile and conversation. Never invent plans, places, or details about either person.
- Be warm and respectful. No sexual content, no pressure, no negging, no requests for contact details or money.
- If asked for a date idea, suggest a public place and offer to propose a time in the app.
- Return only the message text, nothing else.`

func (c *claudeCopilot) Draft(ctx context.Context, req copilotRequest) (copilotResult, error) {
	var sb strings.Builder
	fmt.Fprintf(&sb, "Kind: %s. Tone: %s.\n", req.Kind, req.Tone)
	fmt.Fprintf(&sb, "I am %s. The other member is %s.\n", req.ViewerName, req.PartnerName)
	sb.WriteString("Their public profile (only these facts are known):\n")
	for _, key := range []string{"bio", "profession", "education", "city", "hobbies", "intent_tags", "language_tags", "favorite_books", "favorite_songs", "extra_curriculars"} {
		if value, ok := req.Profile[key]; ok {
			text := strings.TrimSpace(strings.Join(firstString(value, 6), ", "))
			if text == "" {
				text = strings.TrimSpace(toString(value))
			}
			if text != "" {
				fmt.Fprintf(&sb, "- %s: %s\n", key, text)
			}
		}
	}
	if len(req.Recent) > 0 {
		sb.WriteString("Recent conversation, oldest first:\n")
		for _, turn := range req.Recent {
			who := "Them"
			if turn.FromViewer {
				who = "Me"
			}
			fmt.Fprintf(&sb, "%s: %s\n", who, strings.TrimSpace(turn.Text))
		}
	}
	sb.WriteString("Write the message now.")

	resp, err := c.client.Beta.Messages.New(ctx, anthropic.BetaMessageNewParams{
		Model:     anthropic.Model(c.model),
		MaxTokens: 512,
		System:    []anthropic.BetaTextBlockParam{{Text: copilotSystemPrompt}},
		Messages: []anthropic.BetaMessageParam{
			anthropic.NewBetaUserMessage(anthropic.NewBetaTextBlock(sb.String())),
		},
		// A policy refusal is re-served by a fallback model in the same call,
		// routed by refusal category so no model list needs maintaining.
		Betas:     []anthropic.AnthropicBeta{anthropic.AnthropicBeta("server-side-fallback-2026-07-01")},
		Fallbacks: anthropic.BetaFallbacksParamOfDefault(),
	})
	if err != nil {
		return copilotResult{}, fmt.Errorf("%w: %v", errCopilotProvider, err)
	}
	if resp.StopReason == anthropic.BetaStopReasonRefusal {
		return copilotResult{}, errCopilotProvider
	}
	var text strings.Builder
	for _, block := range resp.Content {
		if tb, ok := block.AsAny().(anthropic.BetaTextBlock); ok {
			text.WriteString(tb.Text)
		}
	}
	draft := clampDraft(strings.Trim(strings.TrimSpace(text.String()), `"`))
	if draft == "" {
		return copilotResult{}, errCopilotProvider
	}
	return copilotResult{Text: draft, Provider: copilotProviderClaude, Model: resp.Model}, nil
}

// newCopilotProviderFromEnv picks the provider: COPILOT_PROVIDER=claude uses
// the Anthropic SDK (ANTHROPIC_API_KEY, optional COPILOT_MODEL); anything
// else, or a missing key, uses the offline template provider.
func newCopilotProviderFromEnv() copilotProvider {
	provider := strings.ToLower(strings.TrimSpace(os.Getenv("COPILOT_PROVIDER")))
	apiKey := strings.TrimSpace(os.Getenv("ANTHROPIC_API_KEY"))
	if provider == copilotProviderClaude && apiKey != "" {
		return newClaudeCopilot(apiKey, os.Getenv("COPILOT_MODEL"))
	}
	return templateCopilot{}
}

// ── Service ──────────────────────────────────────────────────────────────────

type copilotDraftView struct {
	ID         string `json:"draft_id"`
	Kind       string `json:"kind"`
	Tone       string `json:"tone"`
	Text       string `json:"text"`
	Provider   string `json:"provider"`
	Model      string `json:"model,omitempty"`
	Disclosure string `json:"disclosure"`
	Remaining  int    `json:"drafts_remaining_today"`
}

type copilotService struct {
	db       *sql.DB
	provider copilotProvider
	now      func() time.Time
}

func newCopilotService(db *sql.DB, provider copilotProvider) *copilotService {
	if db == nil {
		return nil
	}
	if provider == nil {
		provider = templateCopilot{}
	}
	return &copilotService{db: db, provider: provider, now: func() time.Time { return time.Now().UTC() }}
}

func (s *copilotService) draftsToday(ctx context.Context, userID string) (int, error) {
	var n int
	err := s.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM matching.copilot_drafts
		WHERE user_id=$1::uuid AND created_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'`,
		userID).Scan(&n)
	return n, err
}

func (s *copilotService) recentTurns(ctx context.Context, matchID, viewerID string) ([]copilotTurn, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT sender_id::text, text FROM matching.messages
		WHERE match_id=$1::uuid AND COALESCE(is_deleted,FALSE)=FALSE AND gift_send_id IS NULL
		ORDER BY created_at DESC LIMIT $2`, matchID, copilotContextMessages)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var turns []copilotTurn
	for rows.Next() {
		var sender, text string
		if err := rows.Scan(&sender, &text); err != nil {
			return nil, err
		}
		turns = append([]copilotTurn{{FromViewer: sender == viewerID, Text: text}}, turns...)
	}
	return turns, rows.Err()
}

// draft builds the minimised context, asks the provider and stores the draft.
func (s *copilotService) draft(ctx context.Context, viewerID, matchID, kind, tone string) (copilotDraftView, error) {
	kind = strings.ToLower(strings.TrimSpace(kind))
	tone = strings.ToLower(strings.TrimSpace(tone))
	if !allowedCopilotKinds[kind] {
		return copilotDraftView{}, errors.New("kind must be opener, reply, or plan_idea")
	}
	if tone == "" {
		tone = "warm"
	}
	if !allowedCopilotTones[tone] {
		return copilotDraftView{}, errors.New("tone must be warm, playful, or direct")
	}
	if _, err := uuid.Parse(strings.TrimSpace(matchID)); err != nil {
		return copilotDraftView{}, errDatePlanNotFound
	}
	var first, second string
	if err := s.db.QueryRowContext(ctx, `SELECT user_id_1::text, user_id_2::text FROM matching.matches WHERE id=$1::uuid`, matchID).Scan(&first, &second); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return copilotDraftView{}, errDatePlanNotFound
		}
		return copilotDraftView{}, err
	}
	if viewerID != first && viewerID != second {
		return copilotDraftView{}, errDatePlanForbidden
	}
	partnerID := second
	if viewerID == second {
		partnerID = first
	}
	used, err := s.draftsToday(ctx, viewerID)
	if err != nil {
		return copilotDraftView{}, err
	}
	if used >= copilotDailyDraftLimit {
		return copilotDraftView{}, errCopilotLimit
	}
	profile, found, err := loadPublicProfile(ctx, s.db, viewerID, partnerID)
	if err != nil {
		return copilotDraftView{}, err
	}
	if !found {
		return copilotDraftView{}, errCopilotNoProfile
	}
	turns, err := s.recentTurns(ctx, matchID, viewerID)
	if err != nil {
		return copilotDraftView{}, err
	}
	req := copilotRequest{
		Kind: kind, Tone: tone,
		ViewerName:  memberName(ctx, s.db, viewerID, "me"),
		PartnerName: toString(profile["name"]),
		Profile:     profile,
		Recent:      turns,
	}
	result, err := s.provider.Draft(ctx, req)
	if err != nil {
		return copilotDraftView{}, err
	}
	digest := sha256.Sum256([]byte(fmt.Sprintf("%s|%s|%d", partnerID, kind, len(turns))))
	var id string
	if err = s.db.QueryRowContext(ctx, `
		INSERT INTO matching.copilot_drafts(user_id, match_id, kind, tone, draft, provider, model, context_digest)
		VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, NULLIF($7,''), $8) RETURNING id::text`,
		viewerID, matchID, kind, tone, result.Text, result.Provider, result.Model, hex.EncodeToString(digest[:8])).Scan(&id); err != nil {
		return copilotDraftView{}, err
	}
	return copilotDraftView{
		ID: id, Kind: kind, Tone: tone, Text: result.Text, Provider: result.Provider, Model: result.Model,
		Disclosure: copilotDisclosure, Remaining: copilotDailyDraftLimit - used - 1,
	}, nil
}

// markAssisted records that a sent message started as a copilot draft.
func (s *copilotService) markAssisted(ctx context.Context, matchID, messageID, senderID, draftID string) error {
	for _, id := range []string{matchID, messageID, senderID} {
		if _, err := uuid.Parse(strings.TrimSpace(id)); err != nil {
			return errors.New("invalid identifiers for assist mark")
		}
	}
	if _, err := uuid.Parse(strings.TrimSpace(draftID)); err != nil {
		draftID = ""
	}
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO matching.message_assist_marks(message_id, match_id, sender_user_id, draft_id)
		VALUES ($1::uuid, $2::uuid, $3::uuid, NULLIF($4,'')::uuid)
		ON CONFLICT (message_id) DO NOTHING`, messageID, matchID, senderID, draftID)
	if err != nil {
		return err
	}
	if draftID != "" {
		_, _ = s.db.ExecContext(ctx, `UPDATE matching.copilot_drafts SET used_at=NOW() WHERE id=$1::uuid AND used_at IS NULL`, draftID)
	}
	return nil
}

// attachAssistMarks adds composed_with_assist to every message in a list
// response so both members see which messages started as drafts.
func (s *copilotService) attachAssistMarks(ctx context.Context, matchID string, response map[string]any) error {
	items, ok := response["messages"].([]any)
	if !ok || len(items) == 0 {
		return nil
	}
	rows, err := s.db.QueryContext(ctx, `SELECT message_id::text FROM matching.message_assist_marks WHERE match_id=$1::uuid`, matchID)
	if err != nil {
		return err
	}
	defer rows.Close()
	marked := map[string]bool{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return err
		}
		marked[id] = true
	}
	if err := rows.Err(); err != nil {
		return err
	}
	for _, raw := range items {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		item["composed_with_assist"] = marked[strings.TrimSpace(toString(item["id"]))]
	}
	return nil
}

// ── Conversation trust ───────────────────────────────────────────────────────

type conversationTrustView struct {
	MatchID          string   `json:"match_id"`
	ViewerVerified   bool     `json:"viewer_verified"`
	PartnerVerified  bool     `json:"partner_verified"`
	HumanVerified    bool     `json:"human_verified"`
	PartnerBadges    []string `json:"partner_badges"`
	AssistedMessages int      `json:"assisted_messages"`
}

func (s *copilotService) conversationTrust(ctx context.Context, viewerID, matchID string) (conversationTrustView, error) {
	if _, err := uuid.Parse(strings.TrimSpace(matchID)); err != nil {
		return conversationTrustView{}, errDatePlanNotFound
	}
	var first, second string
	if err := s.db.QueryRowContext(ctx, `SELECT user_id_1::text, user_id_2::text FROM matching.matches WHERE id=$1::uuid`, matchID).Scan(&first, &second); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return conversationTrustView{}, errDatePlanNotFound
		}
		return conversationTrustView{}, err
	}
	if viewerID != first && viewerID != second {
		return conversationTrustView{}, errDatePlanForbidden
	}
	partnerID := second
	if viewerID == second {
		partnerID = first
	}
	view := conversationTrustView{MatchID: matchID, PartnerBadges: []string{}}
	if err := s.db.QueryRowContext(ctx, `
		SELECT COALESCE((SELECT is_verified FROM user_management.users WHERE id=$1::uuid), FALSE),
		       COALESCE((SELECT is_verified FROM user_management.users WHERE id=$2::uuid), FALSE),
		       (SELECT COUNT(*) FROM matching.message_assist_marks WHERE match_id=$3::uuid)`,
		viewerID, partnerID, matchID).Scan(&view.ViewerVerified, &view.PartnerVerified, &view.AssistedMessages); err != nil {
		return conversationTrustView{}, err
	}
	view.HumanVerified = view.ViewerVerified && view.PartnerVerified
	rows, err := s.db.QueryContext(ctx, `
		SELECT badge_code FROM matching.user_trust_badges WHERE user_id=$1::uuid AND status='active' ORDER BY badge_code`, partnerID)
	if err != nil {
		return conversationTrustView{}, err
	}
	defer rows.Close()
	for rows.Next() {
		var code string
		if err := rows.Scan(&code); err != nil {
			return conversationTrustView{}, err
		}
		view.PartnerBadges = append(view.PartnerBadges, code)
	}
	return view, rows.Err()
}
