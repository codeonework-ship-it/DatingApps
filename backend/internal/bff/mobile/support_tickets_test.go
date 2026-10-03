package mobile

import (
	"bytes"
	"compress/zlib"
	"context"
	"encoding/json"
	"image"
	"image/color"
	"image/png"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/mediastore"
)

// Support ticket system (migration 126): support_tickets.go,
// support_admin.go, support_attachments.go, support_worker.go.

// ── pure logic ───────────────────────────────────────────────────────────────

func TestSupportSLATargetsByPriorityAndSafety(t *testing.T) {
	t.Parallel()
	cases := []struct {
		category, priority string
		first, resolution  time.Duration
	}{
		{"technical", "urgent", time.Hour, 8 * time.Hour},
		{"technical", "high", 4 * time.Hour, 24 * time.Hour},
		{"technical", "normal", 24 * time.Hour, 72 * time.Hour},
		{"feature_request", "low", 48 * time.Hour, 168 * time.Hour},
		{"safety_harassment", "high", time.Hour, 24 * time.Hour},
		{"safety_harassment", "low", time.Hour, 24 * time.Hour},
		{"safety_harassment", "urgent", time.Hour, 8 * time.Hour},
	}
	for _, c := range cases {
		first, resolution := supportSLATargets(c.category, c.priority)
		if first != c.first || resolution != c.resolution {
			t.Errorf("%s/%s targets=(%s,%s) want (%s,%s)", c.category, c.priority, first, resolution, c.first, c.resolution)
		}
	}
	for key, spec := range supportCategories {
		if !supportTeams[spec.Team] || !supportPriorities[spec.Priority] {
			t.Errorf("category %s maps to unknown team/priority %+v", key, spec)
		}
	}
	if supportCategories["safety_harassment"].Team != "trust_safety" || supportCategories["safety_harassment"].Priority != "high" {
		t.Fatal("safety reports must route to trust & safety at high priority")
	}
	if err := validateGrowthGuardrails(); err != nil {
		t.Fatal(err)
	}
}

func newTestSupportTicket(created time.Time, category, priority string) *supportTicket {
	first, resolution := supportSLATargets(category, priority)
	return &supportTicket{ID: uuid.NewString(), Category: category, Priority: priority, Status: "new",
		CreatedAt: created, FirstResponseDueAt: created.Add(first), ResolutionDueAt: created.Add(resolution), Tags: []string{}}
}

func TestSupportSLAPauseReopenAndRetarget(t *testing.T) {
	t.Parallel()
	created := time.Date(2026, 10, 1, 9, 0, 0, 0, time.UTC)
	tk := newTestSupportTicket(created, "technical", "normal") // 24h / 72h
	if state, first, _ := tk.slaState(created.Add(time.Hour)); state != "ok" || first != "ok" {
		t.Fatalf("fresh ticket state=%s first=%s", state, first)
	}
	if _, first, _ := tk.slaState(created.Add(19 * time.Hour)); first != "at_risk" {
		t.Fatalf("first response in the last quarter should be at risk, got %s", first)
	}
	responded := created.Add(2 * time.Hour)
	tk.FirstRespondedAt = &responded
	// Waiting on the member pauses the resolution clock: 10h paused shifts the due time by 10h.
	tk.setStatus("pending_member", created.Add(2*time.Hour))
	if state, _, resolution := tk.slaState(created.Add(80 * time.Hour)); resolution != "paused" || state != "paused" {
		t.Fatalf("pending ticket should be paused, got %s/%s", state, resolution)
	}
	tk.setStatus("open", created.Add(12*time.Hour))
	if want := created.Add(82 * time.Hour); !tk.ResolutionDueAt.Equal(want) {
		t.Fatalf("resolution due %s want %s", tk.ResolutionDueAt, want)
	}
	if tk.ResolutionBreached {
		t.Fatal("pause must not count as a breach")
	}
	// Priority change keeps the pause shift.
	tk.retarget("technical", "high") // 24h resolution
	if want := created.Add(34 * time.Hour); !tk.ResolutionDueAt.Equal(want) {
		t.Fatalf("retargeted due %s want %s", tk.ResolutionDueAt, want)
	}
	// Resolving late latches the breach for good.
	tk.setStatus("resolved", created.Add(40*time.Hour))
	if !tk.ResolutionBreached || tk.ResolvedAt == nil {
		t.Fatalf("late resolution should latch the breach: %+v", tk)
	}
	if state, _, resolution := tk.slaState(created.Add(41 * time.Hour)); state != "breached" || resolution != "breached" {
		t.Fatalf("latched breach state=%s/%s", state, resolution)
	}
	// Reopening clears resolution timestamps and sets a fresh target.
	reopenAt := created.Add(50 * time.Hour)
	tk.setStatus("open", reopenAt)
	if tk.ResolvedAt != nil || tk.ClosedAt != nil || !tk.ResolutionDueAt.Equal(reopenAt.Add(24*time.Hour)) {
		t.Fatalf("reopen did not reset: resolved=%v closed=%v due=%s", tk.ResolvedAt, tk.ClosedAt, tk.ResolutionDueAt)
	}
	// Closed tickets can be reopened by the member for 14 days.
	tk.setStatus("closed", reopenAt)
	if !tk.memberCanReopen(reopenAt.Add(13*24*time.Hour)) || tk.memberCanReopen(reopenAt.Add(15*24*time.Hour)) {
		t.Fatal("reopen window should be 14 days")
	}
}

func supportPNG(t *testing.T, w, h int) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for x := 0; x < w; x++ {
		for y := 0; y < h; y++ {
			img.Set(x, y, color.RGBA{uint8(x), uint8(y), 90, 255})
		}
	}
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		t.Fatal(err)
	}
	return buf.Bytes()
}

func supportPDF(body string) []byte {
	return []byte("%PDF-1.4\n1 0 obj << /Type /Catalog " + body + " >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n")
}

func TestSupportAttachmentSanitising(t *testing.T) {
	t.Parallel()
	// JPEG with an EXIF segment carrying a marker: re-encoded without it.
	jpegWithExif := coverJPEG(t, 64, 48, "GPS-SECRET-LOCATION")
	upload, err := sanitizeSupportUpload(jpegWithExif)
	if err != nil {
		t.Fatal(err)
	}
	if upload.ContentType != "image/jpeg" || upload.Width != 64 || bytes.Contains(upload.Content, []byte("GPS-SECRET-LOCATION")) {
		t.Fatalf("jpeg not sanitised: %s %dx%d", upload.ContentType, upload.Width, upload.Height)
	}
	if upload, err = sanitizeSupportUpload(supportPNG(t, 20, 10)); err != nil || upload.ContentType != "image/png" {
		t.Fatalf("png rejected: %v", err)
	}
	if _, err = sanitizeSupportUpload(supportPDF("/Pages 2 0 R")); err != nil {
		t.Fatalf("plain pdf rejected: %v", err)
	}
	var compressed bytes.Buffer
	zw := zlib.NewWriter(&compressed)
	_, _ = zw.Write([]byte("<< /S /JS /JS (app.alert(1)) >>"))
	_ = zw.Close()
	hidden := append([]byte("%PDF-1.5\n4 0 obj << /Type /ObjStm /Filter /FlateDecode >>\nstream\n"), compressed.Bytes()...)
	hidden = append(hidden, []byte("\nendstream endobj\n%%EOF\n")...)
	for name, content := range map[string][]byte{
		"javascript":       supportPDF("/OpenAction << /S /JavaScript /JS (x) >>"),
		"escaped name":     supportPDF("/Names << /J#61vaScript 3 0 R >>"),
		"launch":           supportPDF("/AA << /O << /S /Launch /F (cmd.exe) >> >>"),
		"embedded file":    supportPDF("/EmbeddedFiles 5 0 R /Type /EmbeddedFile"),
		"compressed js":    hidden,
		"gif":              []byte("GIF89a\x01\x00\x01\x00"),
		"html":             []byte("<html><script>alert(1)</script></html>"),
		"empty":            {},
		"truncated pdf":    []byte("%PDF-1.4\n1 0 obj << >>"),
		"svg as png name":  []byte("<svg xmlns='http://www.w3.org/2000/svg'/>"),
		"oversized pixels": nil,
	} {
		if name == "oversized pixels" {
			continue
		}
		if _, err := sanitizeSupportUpload(content); err == nil {
			t.Errorf("%s accepted", name)
		}
	}
	if pdfNamesActive([]byte("/JSON /JSXGraph")) {
		t.Fatal("names that merely start with /JS must not match")
	}
	if got := supportAttachmentName("../../etc/My Screenshot.PNG", ".png"); got != "My_Screenshot.png" {
		t.Fatalf("attachment name %q", got)
	}
}

func TestSupportRoleAccessToAdminRoutes(t *testing.T) {
	t.Parallel()
	role := func(roles ...string) securityPrincipal {
		p := securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"user": true}}
		for _, r := range roles {
			p.Roles[r] = true
		}
		return p
	}
	cases := []struct {
		principal securityPrincipal
		method    string
		path      string
		want      bool
	}{
		{role("support"), http.MethodGet, "/v1/admin/support/tickets", true},
		{role("support"), http.MethodPatch, "/v1/admin/support/tickets/x", true},
		{role("support"), http.MethodPost, "/v1/admin/support/canned-responses", true},
		{role("support"), http.MethodGet, "/v1/admin/analytics/overview", true},
		{role("support"), http.MethodGet, "/v1/admin/users", false},
		{role("support"), http.MethodPost, "/v1/admin/users/x/ban", false},
		{role("support"), http.MethodGet, "/v1/admin/billing/payments", false},
		{role("trust_safety"), http.MethodPost, "/v1/admin/support/tickets/x/messages", true},
		{role("moderator"), http.MethodGet, "/v1/admin/support/dashboard", true},
		{role("ops_admin"), http.MethodPost, "/v1/admin/support/tickets/bulk", true},
		{role("analyst"), http.MethodGet, "/v1/admin/support/dashboard", true},
		{role("analyst"), http.MethodGet, "/v1/admin/support/tickets", false},
		{role("analyst"), http.MethodGet, "/v1/admin/support/tickets/export", false},
		{role("finance"), http.MethodGet, "/v1/admin/support/dashboard", false},
		{role(), http.MethodGet, "/v1/admin/support/tickets", false},
	}
	for _, c := range cases {
		if got := principalCanAccessAdminRoute(c.principal, "/v1", c.method, c.path); got != c.want {
			t.Errorf("%v %s %s = %v want %v", c.principal.Roles, c.method, c.path, got, c.want)
		}
	}
	if !isPublicSecurityPath("/v1", "/v1/support/contact", http.MethodPost) || isPublicSecurityPath("/v1", "/v1/support/tickets", http.MethodPost) {
		t.Fatal("only the contact form is public")
	}
	if featureFlagForRoute("/v1", "/v1/support/contact") != "support_ticketing_enabled" ||
		featureFlagForRoute("/v1", "/v1/support/attachments") != "support_ticketing_enabled" ||
		featureFlagForRoute("/v1", "/v1/admin/support/tickets") != "" {
		t.Fatal("member support routes must be gated; the operator queue must not")
	}
	if got := operatorRoleOf(role("support")); got != "support" {
		t.Fatalf("operator audit role %q", got)
	}
}

// ── Postgres harness ─────────────────────────────────────────────────────────

type supportHarness struct {
	t        *testing.T
	f        datePlanFixture
	s        *Server
	store    *mediastore.LocalStore
	operator string
	member   string
	other    string
}

func newSupportHarness(t *testing.T) supportHarness {
	t.Helper()
	f := newDatePlanFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('support.tickets') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 126_support_ticket_system is not applied")
	}
	root := filepath.Join(t.TempDir(), "media")
	store, err := mediastore.NewLocal(config.LocalStorageConfig{Root: root, Layout: config.LocalLayoutKinds, PublicDirMode: 0o750, PublicFileMode: 0o640})
	if err != nil {
		t.Fatal(err)
	}
	s := blogServer(f)
	s.media = store
	s.log = zap.NewNop()
	s.cfg.APIPrefix = "/v1"
	// An operator with the support role.
	operator := uuid.NewString()
	username := "supportqa_" + strings.ReplaceAll(operator[:8], "-", "")
	if _, err := f.db.Exec(`INSERT INTO user_management.users (id, username, name, date_of_birth, gender, email)
		VALUES ($1,$2,'Asha Agent','1990-01-01','female',$3)`, operator, username, username+"@example.test"); err != nil {
		t.Fatal(err)
	}
	if _, err := f.db.Exec(`INSERT INTO user_management.auth_credentials (user_id, username, password_hash) VALUES ($1,$2,'not-a-real-hash')`, operator, username); err != nil {
		t.Fatal(err)
	}
	if _, err := f.db.Exec(`INSERT INTO user_management.auth_account_roles (user_id, role) VALUES ($1,'support')`, operator); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		ctx := context.Background()
		_, _ = f.db.Exec(`DELETE FROM support.tickets WHERE requester_member_id IS NULL AND contact_email LIKE '%@support-qa.example'`)
		_, _ = f.db.Exec(`DELETE FROM support.canned_responses WHERE title LIKE 'QA %'`)
		_, _ = f.db.Exec(`DELETE FROM support.ticket_attachments WHERE uploader_id=$1 OR uploader_id=$2 OR uploader_id=$3`, f.proposer, f.invitee, operator)
		_, _ = f.db.Exec(`DELETE FROM user_management.auth_account_roles WHERE user_id=$1`, operator)
		_, _ = f.db.Exec(`DELETE FROM user_management.auth_credentials WHERE user_id=$1`, operator)
		deleteTestMember(ctx, f.db, operator)
	})
	supportContactLimiter = newClientErrorRateLimiter(time.Now)
	return supportHarness{t: t, f: f, s: s, store: store, operator: operator, member: f.proposer, other: f.invitee}
}

func supportRequest(method, query, body string, principal *securityPrincipal, params map[string]string) *http.Request {
	target := "/"
	if query != "" {
		target += "?" + query
	}
	r := httptest.NewRequest(method, target, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	rc := chi.NewRouteContext()
	for k, v := range params {
		rc.URLParams.Add(k, v)
	}
	ctx := context.WithValue(r.Context(), chi.RouteCtxKey, rc)
	if principal != nil {
		ctx = context.WithValue(ctx, securityPrincipalContextKey{}, *principal)
	}
	return r.WithContext(ctx)
}

func (h supportHarness) memberPrincipal(id string) *securityPrincipal {
	return &securityPrincipal{UserID: id, Roles: map[string]bool{"user": true}}
}

func (h supportHarness) operatorPrincipal(roles ...string) *securityPrincipal {
	p := &securityPrincipal{UserID: h.operator, Roles: map[string]bool{"user": true}}
	if len(roles) == 0 {
		roles = []string{"support"}
	}
	for _, r := range roles {
		p.Roles[r] = true
	}
	return p
}

func (h supportHarness) do(handler http.HandlerFunc, r *http.Request) (int, map[string]any) {
	h.t.Helper()
	rec := httptest.NewRecorder()
	handler(rec, r)
	out := map[string]any{}
	if strings.HasPrefix(rec.Header().Get("Content-Type"), "application/json") {
		if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
			h.t.Fatalf("decode %d %s: %v", rec.Code, rec.Body.String(), err)
		}
	}
	return rec.Code, out
}

func (h supportHarness) asMember(handler http.HandlerFunc, member, method, body string, params map[string]string) (int, map[string]any) {
	h.t.Helper()
	return h.do(handler, supportRequest(method, "", body, h.memberPrincipal(member), params))
}

func (h supportHarness) asOperator(handler http.HandlerFunc, method, query, body string, params map[string]string) (int, map[string]any) {
	h.t.Helper()
	return h.do(handler, supportRequest(method, query, body, h.operatorPrincipal(), params))
}

func (h supportHarness) create(member, category, subject, description string, attachments ...string) (int, map[string]any) {
	h.t.Helper()
	body, _ := json.Marshal(map[string]any{"category": category, "subject": subject, "description": description,
		"attachment_ids": attachments, "app_version": "1.4.0+42", "platform": "android", "os_version": "14", "device_model": "Pixel 7", "locale": "en"})
	return h.asMember(h.s.supportCreateTicket, member, http.MethodPost, string(body), nil)
}

func (h supportHarness) mustCreate(member, category, subject, description string, attachments ...string) map[string]any {
	h.t.Helper()
	code, out := h.create(member, category, subject, description, attachments...)
	if code != http.StatusCreated {
		h.t.Fatalf("create ticket: %d %v", code, out)
	}
	return out["ticket"].(map[string]any)
}

func (h supportHarness) upload(member string, content []byte, filename string) (int, map[string]any) {
	h.t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	fw, _ := mw.CreateFormFile("file", filename)
	_, _ = fw.Write(content)
	_ = mw.Close()
	r := supportRequest(http.MethodPost, "", body.String(), h.memberPrincipal(member), nil)
	r.Header.Set("Content-Type", mw.FormDataContentType())
	return h.do(h.s.supportUploadHandler, r)
}

func (h supportHarness) memberDetail(member, ticketID string) (int, map[string]any) {
	h.t.Helper()
	return h.asMember(h.s.supportGetTicket, member, http.MethodGet, "", map[string]string{"ticketID": ticketID})
}

func (h supportHarness) adminDetail(ticketID string) map[string]any {
	h.t.Helper()
	code, out := h.asOperator(h.s.adminSupportTicketDetail, http.MethodGet, "", "", map[string]string{"ticketID": ticketID})
	if code != http.StatusOK {
		h.t.Fatalf("admin detail: %d %v", code, out)
	}
	return out
}

func (h supportHarness) status(ticketID string) string {
	h.t.Helper()
	var status string
	if err := h.f.db.QueryRow(`SELECT status FROM support.tickets WHERE id=$1`, ticketID).Scan(&status); err != nil {
		h.t.Fatal(err)
	}
	return status
}

func (h supportHarness) events(ticketID, eventType string) int {
	h.t.Helper()
	var n int
	if err := h.f.db.QueryRow(`SELECT COUNT(*) FROM support.ticket_events WHERE ticket_id=$1 AND event_type=$2`, ticketID, eventType).Scan(&n); err != nil {
		h.t.Fatal(err)
	}
	return n
}

func bodies(messages []any) []string {
	out := []string{}
	for _, m := range messages {
		out = append(out, toString(m.(map[string]any)["body"]))
	}
	return out
}

// ── Postgres tests ───────────────────────────────────────────────────────────

func TestSupportTicketLifecyclePostgres(t *testing.T) {
	h := newSupportHarness(t)
	code, up := h.upload(h.member, supportPNG(t, 40, 30), "screen shot.png")
	if code != http.StatusCreated {
		t.Fatalf("upload: %d %v", code, up)
	}
	attachmentID := toString(up["attachment"].(map[string]any)["id"])
	ticket := h.mustCreate(h.member, "technical", "Chat screen freezes", "When I open a chat the screen freezes.", attachmentID)
	ticketID := toString(ticket["id"])
	if !supportReferencePattern.MatchString(toString(ticket["reference"])) || ticket["status"] != "new" || ticket["can_reply"] != true {
		t.Fatalf("created ticket %v", ticket)
	}
	if _, leaked := ticket["priority"]; leaked {
		t.Fatal("member view must not expose priority")
	}
	// Device context is stored for agents.
	admin := h.adminDetail(ticketID)
	at := admin["ticket"].(map[string]any)
	if at["team"] != "technical" || at["priority"] != "normal" || at["app_version"] != "1.4.0+42" || at["platform"] != "android" {
		t.Fatalf("admin ticket %v", at)
	}
	msgs := admin["messages"].([]any)
	if len(msgs) != 1 || len(msgs[0].(map[string]any)["attachments"].([]any)) != 1 {
		t.Fatalf("initial message with attachment: %v", msgs)
	}
	// The member can download their attachment.
	rec := httptest.NewRecorder()
	h.s.supportAttachmentHandler(rec, supportRequest(http.MethodGet, "", "", h.memberPrincipal(h.member), map[string]string{"ticketID": ticketID, "attachmentID": attachmentID}))
	if rec.Code != 200 || rec.Header().Get("Content-Type") != "image/png" || rec.Header().Get("Cache-Control") != "private, no-store" || rec.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatalf("attachment download %d %v", rec.Code, rec.Header())
	}

	// Claim, internal note, public reply.
	if code, out := h.asOperator(h.s.adminSupportClaim, http.MethodPost, "", "", map[string]string{"ticketID": ticketID}); code != 200 || out["ticket"].(map[string]any)["status"] != "open" {
		t.Fatalf("claim %d %v", code, out)
	}
	if code, out := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"Looks like build 42 regression, ask mobile team","visibility":"internal"}`, map[string]string{"ticketID": ticketID}); code != 201 {
		t.Fatalf("note %d %v", code, out)
	}
	if h.f.notifications(t, h.member, "support.reply") != 0 {
		t.Fatal("internal notes must not notify the member")
	}
	code, out := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"Thanks! Could you tell us your phone model?","visibility":"public"}`, map[string]string{"ticketID": ticketID})
	if code != 201 {
		t.Fatalf("reply %d %v", code, out)
	}
	if at := out["ticket"].(map[string]any); at["status"] != "pending_member" || at["first_responded_at"] == nil {
		t.Fatalf("public reply should wait on the member and record the first response: %v", at)
	}
	if h.f.notifications(t, h.member, "support.reply") != 1 {
		t.Fatal("public reply should notify the member")
	}
	var route, category string
	if err := h.f.db.QueryRow(`SELECT action_route, category FROM matching.notification_outbox WHERE recipient_user_id=$1 AND event_type='support.reply'`, h.member).Scan(&route, &category); err != nil {
		t.Fatal(err)
	}
	if route != "/support/tickets/"+ticketID || category != "system" {
		t.Fatalf("notification route=%s category=%s", route, category)
	}

	// The member sees the reply, never the note; the list shows it unread.
	code, list := h.asMember(h.s.supportListTickets, h.member, http.MethodGet, "", nil)
	if code != 200 || list["unread_total"].(float64) != 1 {
		t.Fatalf("list %d %v", code, list)
	}
	code, detail := h.memberDetail(h.member, ticketID)
	if code != 200 {
		t.Fatalf("detail %d %v", code, detail)
	}
	got := bodies(detail["messages"].([]any))
	if len(got) != 2 || strings.Contains(strings.Join(got, "|"), "regression") {
		t.Fatalf("member messages %v", got)
	}
	agentMsg := detail["messages"].([]any)[1].(map[string]any)
	if agentMsg["author"] != "agent" || agentMsg["author_name"] != supportAgentDisplayName {
		t.Fatalf("agent message %v", agentMsg)
	}
	if _, list = h.asMember(h.s.supportListTickets, h.member, http.MethodGet, "", nil); list["unread_total"].(float64) != 0 {
		t.Fatal("opening the ticket should mark replies read")
	}

	// Member reply resets pending_member.
	code, out = h.asMember(h.s.supportReply, h.member, http.MethodPost, `{"body":"Pixel 7, Android 14"}`, map[string]string{"ticketID": ticketID})
	if code != 201 || out["ticket"].(map[string]any)["status"] != "open" || out["message"].(map[string]any)["author"] != "member" {
		t.Fatalf("member reply %d %v", code, out)
	}
	if !h.adminDetail(ticketID)["ticket"].(map[string]any)["awaiting_agent"].(bool) {
		t.Fatal("ticket should await the agent after a member reply")
	}

	// Rating before resolution is refused; resolve notifies; rate once.
	if code, out = h.asMember(h.s.supportRateTicket, h.member, http.MethodPost, `{"rating":5}`, map[string]string{"ticketID": ticketID}); code != 409 || out["error_code"] != "SUPPORT_NOT_RESOLVED" {
		t.Fatalf("early rating %d %v", code, out)
	}
	if code, out = h.asOperator(h.s.adminSupportUpdateTicket, http.MethodPatch, "", `{"status":"resolved","tags":["android","build-42"]}`, map[string]string{"ticketID": ticketID}); code != 200 {
		t.Fatalf("resolve %d %v", code, out)
	}
	if h.f.notifications(t, h.member, "support.status") != 1 || h.events(ticketID, "status_changed") < 2 || h.events(ticketID, "tags_changed") != 1 {
		t.Fatal("resolution should notify the member and be recorded")
	}
	if code, out = h.asMember(h.s.supportRateTicket, h.member, http.MethodPost, `{"rating":4,"comment":"Quick, thanks"}`, map[string]string{"ticketID": ticketID}); code != 200 ||
		out["ticket"].(map[string]any)["satisfaction"].(map[string]any)["rating"].(float64) != 4 || out["ticket"].(map[string]any)["can_rate"] != false {
		t.Fatalf("rate %d %v", code, out)
	}
	if code, out = h.asMember(h.s.supportRateTicket, h.member, http.MethodPost, `{"rating":1}`, map[string]string{"ticketID": ticketID}); code != 409 || out["error_code"] != "SUPPORT_ALREADY_RATED" {
		t.Fatalf("second rating %d %v", code, out)
	}

	// Close, reopen inside the window, close again and let the window pass.
	if code, out = h.asMember(h.s.supportCloseTicket, h.member, http.MethodPost, `{}`, map[string]string{"ticketID": ticketID}); code != 200 || out["ticket"].(map[string]any)["can_reopen"] != true {
		t.Fatalf("close %d %v", code, out)
	}
	if code, out = h.asMember(h.s.supportReopenTicket, h.member, http.MethodPost, `{"reason":"It happened again"}`, map[string]string{"ticketID": ticketID}); code != 200 || out["ticket"].(map[string]any)["status"] != "open" {
		t.Fatalf("reopen %d %v", code, out)
	}
	if code, _ = h.asMember(h.s.supportCloseTicket, h.member, http.MethodPost, `{}`, map[string]string{"ticketID": ticketID}); code != 200 {
		t.Fatal("close again")
	}
	if _, err := h.f.db.Exec(`UPDATE support.tickets SET closed_at=NOW()-INTERVAL '15 days' WHERE id=$1`, ticketID); err != nil {
		t.Fatal(err)
	}
	if code, out = h.asMember(h.s.supportReopenTicket, h.member, http.MethodPost, ``, map[string]string{"ticketID": ticketID}); code != 409 || out["error_code"] != "SUPPORT_REOPEN_WINDOW_PASSED" {
		t.Fatalf("late reopen %d %v", code, out)
	}
	if code, out = h.asMember(h.s.supportReply, h.member, http.MethodPost, `{"body":"hello?"}`, map[string]string{"ticketID": ticketID}); code != 409 || out["error_code"] != "SUPPORT_TICKET_CLOSED" {
		t.Fatalf("late reply %d %v", code, out)
	}
	for _, event := range []string{"created", "assigned", "note_added", "agent_replied", "member_replied", "rated", "closed_by_member", "reopened"} {
		if h.events(ticketID, event) == 0 {
			t.Errorf("missing %s event", event)
		}
	}
}

func TestSupportPrivacyBetweenMembersPostgres(t *testing.T) {
	h := newSupportHarness(t)
	_, up := h.upload(h.member, supportPNG(t, 10, 10), "a.png")
	attachmentID := toString(up["attachment"].(map[string]any)["id"])
	ticketID := toString(h.mustCreate(h.member, "account_login", "Cannot log in", "Password rejected", attachmentID)["id"])
	if code, _ := h.memberDetail(h.other, ticketID); code != http.StatusNotFound {
		t.Fatalf("another member read the ticket: %d", code)
	}
	if code, _ := h.asMember(h.s.supportReply, h.other, http.MethodPost, `{"body":"hi"}`, map[string]string{"ticketID": ticketID}); code != http.StatusNotFound {
		t.Fatalf("another member replied: %d", code)
	}
	for _, handler := range []http.HandlerFunc{h.s.supportCloseTicket, h.s.supportReopenTicket} {
		if code, _ := h.asMember(handler, h.other, http.MethodPost, `{}`, map[string]string{"ticketID": ticketID}); code != http.StatusNotFound {
			t.Fatalf("another member changed the ticket: %d", code)
		}
	}
	rec := httptest.NewRecorder()
	h.s.supportAttachmentHandler(rec, supportRequest(http.MethodGet, "", "", h.memberPrincipal(h.other), map[string]string{"ticketID": ticketID, "attachmentID": attachmentID}))
	if rec.Code != http.StatusNotFound {
		t.Fatalf("another member downloaded the attachment: %d", rec.Code)
	}
	// Someone else's pending upload cannot be attached.
	_, up = h.upload(h.other, supportPNG(t, 10, 10), "b.png")
	foreign := toString(up["attachment"].(map[string]any)["id"])
	body, _ := json.Marshal(map[string]any{"body": "see", "attachment_ids": []string{foreign}})
	if code, out := h.asMember(h.s.supportReply, h.member, http.MethodPost, string(body), map[string]string{"ticketID": ticketID}); code != 400 {
		t.Fatalf("foreign attachment accepted: %d %v", code, out)
	}
	_, list := h.asMember(h.s.supportListTickets, h.other, http.MethodGet, "", nil)
	if len(list["tickets"].([]any)) != 0 {
		t.Fatal("list leaked another member's ticket")
	}
	// Members never get operator routes.
	code, _ := h.do(h.s.adminSupportQueue, supportRequest(http.MethodGet, "", "", h.memberPrincipal(h.member), nil))
	if code != http.StatusForbidden {
		t.Fatalf("member reached the queue: %d", code)
	}
	analyst := &securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"analyst": true}}
	if code, _ := h.do(h.s.adminSupportQueue, supportRequest(http.MethodGet, "", "", analyst, nil)); code != http.StatusForbidden {
		t.Fatalf("analyst reached the queue: %d", code)
	}
	if code, out := h.do(h.s.adminSupportDashboard, supportRequest(http.MethodGet, "days=7", "", analyst, nil)); code != 200 || out["window_days"].(float64) != 7 {
		t.Fatalf("analyst dashboard %d %v", code, out)
	}
	// Assigning to a non-operator is refused.
	if code, out := h.asOperator(h.s.adminSupportUpdateTicket, http.MethodPatch, "", `{"assignee_id":"`+h.other+`"}`, map[string]string{"ticketID": ticketID}); code != 400 {
		t.Fatalf("assigned to a member: %d %v", code, out)
	}
}

func TestSupportRateLimitsAndDuplicateGuardPostgres(t *testing.T) {
	h := newSupportHarness(t)
	first := h.mustCreate(h.member, "matches_chat", "Messages not sending", "Messages stay grey")
	code, dup := h.create(h.member, "matches_chat", "messages  not sending", "Messages stay   grey")
	if code != http.StatusOK || dup["duplicate"] != true || dup["ticket"].(map[string]any)["id"] != first["id"] {
		t.Fatalf("duplicate guard %d %v", code, dup)
	}
	for i := 0; i < supportTicketsPerHour-1; i++ {
		h.mustCreate(h.member, "other", "Question number "+string(rune('A'+i)), "Different question each time "+string(rune('A'+i)))
	}
	code, out := h.create(h.member, "other", "One too many", "This should be rate limited")
	if code != http.StatusTooManyRequests || out["error_code"] != "SUPPORT_RATE_LIMITED" || out["retry_after_seconds"] == nil {
		t.Fatalf("hourly limit %d %v", code, out)
	}
	// Ten unresolved tickets block an eleventh (older tickets, outside the rate windows).
	if _, err := h.f.db.Exec(`UPDATE support.tickets SET created_at=NOW()-INTERVAL '3 days' WHERE requester_member_id=$1`, h.member); err != nil {
		t.Fatal(err)
	}
	for i := 0; i < supportMaxOpenTickets-supportTicketsPerHour; i++ {
		if _, err := createSupportTicket(context.Background(), h.f.db, supportTicketInput{Category: "other", Subject: "Bulk seed " + string(rune('a'+i)), Description: "seed " + string(rune('a'+i))}, "app", h.member, "", "", time.Now().UTC().Add(-48*time.Hour)); err != nil {
			t.Fatal(err)
		}
	}
	if code, out = h.create(h.member, "other", "Eleventh", "Too many open"); code != http.StatusConflict || out["error_code"] != "SUPPORT_TOO_MANY_OPEN" {
		t.Fatalf("open limit %d %v", code, out)
	}
	// Validation.
	if code, out = h.create(h.member, "billing", "Refund", "wrong category"); code != 400 || out["error_code"] != "SUPPORT_INVALID_CATEGORY" {
		t.Fatalf("category %d %v", code, out)
	}
	if code, out = h.create(h.other, "technical", "Hi", "subject too short"); code != 400 || out["error_code"] != "SUPPORT_INVALID_SUBJECT" {
		t.Fatalf("subject %d %v", code, out)
	}
	if code, out = h.upload(h.other, []byte("<svg/>"), "x.svg"); code != http.StatusUnsupportedMediaType {
		t.Fatalf("svg upload %d %v", code, out)
	}
}

func TestSupportSafetyRoutingAndSLAWorkerPostgres(t *testing.T) {
	h := newSupportHarness(t)
	safety := h.mustCreate(h.member, "safety_harassment", "Someone is threatening me", "They keep sending threats after I unmatched")
	safetyID := toString(safety["id"])
	at := h.adminDetail(safetyID)["ticket"].(map[string]any)
	if at["team"] != "trust_safety" || at["priority"] != "high" {
		t.Fatalf("safety ticket routing %v", at)
	}
	due, _ := time.Parse(time.RFC3339, toString(at["first_response_due_at"]))
	created, _ := time.Parse(time.RFC3339, toString(at["created_at"]))
	if d := due.Sub(created); d > time.Hour+time.Second {
		t.Fatalf("safety first response target %s", d)
	}
	// Push it past its first-response target.
	if _, err := h.f.db.Exec(`UPDATE support.tickets SET created_at=NOW()-INTERVAL '2 hours', first_response_due_at=NOW()-INTERVAL '1 hour' WHERE id=$1`, safetyID); err != nil {
		t.Fatal(err)
	}
	code, q := h.asOperator(h.s.adminSupportQueue, http.MethodGet, "sla=breached&team=trust_safety&q="+toString(safety["reference"]), "", nil)
	if code != 200 || q["total"].(float64) != 1 || q["tickets"].([]any)[0].(map[string]any)["sla"].(map[string]any)["state"] != "breached" {
		t.Fatalf("breached queue %d %v", code, q)
	}
	result, err := h.s.runSupportMaintenance(context.Background(), h.f.db, time.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	if result.Breaches < 1 || h.events(safetyID, "sla_breached") != 1 {
		t.Fatalf("breach not latched: %+v", result)
	}
	var latched bool
	if err := h.f.db.QueryRow(`SELECT first_response_breached FROM support.tickets WHERE id=$1`, safetyID).Scan(&latched); err != nil || !latched {
		t.Fatal("first_response_breached not latched")
	}
	// Dashboard counts it in the Trust & Safety view.
	_, dash := h.asOperator(h.s.adminSupportDashboard, http.MethodGet, "", "", nil)
	if dash["safety"].(map[string]any)["breached"].(float64) < 1 || dash["open_by_team"].(map[string]any)["trust_safety"].(float64) < 1 {
		t.Fatalf("dashboard safety view %v", dash["safety"])
	}

	// Auto-close: resolved 8 days ago without a member reply.
	other := toString(h.mustCreate(h.member, "verification", "Selfie keeps failing", "It says try again")["id"])
	if code, _ := h.asOperator(h.s.adminSupportUpdateTicket, http.MethodPatch, "", `{"status":"resolved"}`, map[string]string{"ticketID": other}); code != 200 {
		t.Fatal("resolve")
	}
	if _, err := h.f.db.Exec(`UPDATE support.tickets SET resolved_at=NOW()-INTERVAL '8 days', last_member_message_at=NOW()-INTERVAL '9 days' WHERE id=$1`, other); err != nil {
		t.Fatal(err)
	}
	if result, err = h.s.runSupportMaintenance(context.Background(), h.f.db, time.Now().UTC()); err != nil || result.AutoClosed < 1 {
		t.Fatalf("auto-close %+v %v", result, err)
	}
	if h.status(other) != "closed" || h.events(other, "auto_closed") != 1 {
		t.Fatal("resolved ticket was not auto-closed")
	}
	// A member reply inside the reopen window reopens it.
	if code, out := h.asMember(h.s.supportReply, h.member, http.MethodPost, `{"body":"Still failing"}`, map[string]string{"ticketID": other}); code != 201 || out["ticket"].(map[string]any)["status"] != "open" {
		t.Fatalf("reply to auto-closed %d %v", code, out)
	}
	if h.events(other, "reopened") != 1 {
		t.Fatal("reopen not recorded")
	}
	// Category change to safety retargets and re-teams.
	if code, out := h.asOperator(h.s.adminSupportUpdateTicket, http.MethodPatch, "", `{"category":"safety_harassment"}`, map[string]string{"ticketID": other}); code != 200 ||
		out["ticket"].(map[string]any)["priority"] != "high" || out["ticket"].(map[string]any)["team"] != "trust_safety" {
		t.Fatalf("recategorise %d %v", code, out)
	}
	// Unattached uploads expire and their bytes are released.
	_, up := h.upload(h.other, supportPNG(t, 12, 12), "pending.png")
	pendingID := toString(up["attachment"].(map[string]any)["id"])
	var key string
	if err := h.f.db.QueryRow(`SELECT storage_path FROM support.ticket_attachments WHERE id=$1`, pendingID).Scan(&key); err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(key, "private/support/"+h.other+"/") {
		t.Fatalf("attachment key %s is not in the private support kind", key)
	}
	if spec, _, err := mediastore.Classify(key); err != nil || spec.Visibility != mediastore.VisibilityPrivate {
		t.Fatalf("attachment visibility %v %v", spec, err)
	}
	if _, err := h.f.db.Exec(`UPDATE support.ticket_attachments SET expires_at=NOW()-INTERVAL '1 minute' WHERE id=$1`, pendingID); err != nil {
		t.Fatal(err)
	}
	if _, err := h.s.runSupportMaintenance(context.Background(), h.f.db, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if ok, _ := h.store.Exists(context.Background(), key); ok {
		t.Fatal("expired upload still stored")
	}
}

func TestSupportMergeCannedAndBulkPostgres(t *testing.T) {
	h := newSupportHarness(t)
	a := h.mustCreate(h.member, "payments_billing", "Charged twice", "I was charged twice for Plus")
	b := h.mustCreate(h.member, "payments_billing", "Double charge again", "Same double charge, second message")
	c := h.mustCreate(h.other, "payments_billing", "Charged twice too", "Another member")
	aID, bID, cID := toString(a["id"]), toString(b["id"]), toString(c["id"])
	if code, out := h.asOperator(h.s.adminSupportMerge, http.MethodPost, "", `{"into_ticket_id":"`+cID+`"}`, map[string]string{"ticketID": bID}); code != 409 {
		t.Fatalf("cross-member merge %d %v", code, out)
	}
	code, out := h.asOperator(h.s.adminSupportMerge, http.MethodPost, "", `{"into_reference":"`+toString(a["reference"])+`"}`, map[string]string{"ticketID": bID})
	if code != 200 || out["ticket"].(map[string]any)["id"] != aID {
		t.Fatalf("merge %d %v", code, out)
	}
	if h.status(bID) != "closed" || h.events(bID, "merged_into") != 1 || h.events(aID, "merged") != 1 {
		t.Fatal("merge not recorded")
	}
	_, detail := h.memberDetail(h.member, aID)
	all := strings.Join(bodies(detail["messages"].([]any)), "|")
	if !strings.Contains(all, "second message") || !strings.Contains(all, "was merged into this one") {
		t.Fatalf("merged thread %s", all)
	}
	_, src := h.memberDetail(h.member, bID)
	if st := src["ticket"].(map[string]any); st["merged_into_reference"] != a["reference"] || st["can_reply"] != false || st["can_reopen"] != false {
		t.Fatalf("merged source %v", st)
	}

	// Canned responses: create, preview with placeholders, reply with it.
	code, created := h.asOperator(h.s.adminSupportCreateCanned, http.MethodPost, "", `{"title":"QA refund","body":"Hi {{member_name}}, refund for {{reference}} is on its way. {{agent_name}}","category":"payments_billing"}`, nil)
	if code != 201 {
		t.Fatalf("create canned %d %v", code, created)
	}
	cannedID := toString(created["canned_response"].(map[string]any)["id"])
	if code, _ := h.asOperator(h.s.adminSupportCreateCanned, http.MethodPost, "", `{"title":"qa REFUND","body":"x"}`, nil); code != 409 {
		t.Fatalf("duplicate canned title %d", code)
	}
	_, preview := h.asOperator(h.s.adminSupportCannedPreview, http.MethodGet, "", "", map[string]string{"ticketID": aID, "responseID": cannedID})
	if want := "Hi Priya, refund for " + toString(a["reference"]) + " is on its way. Asha"; preview["body"] != want {
		t.Fatalf("preview %q want %q", preview["body"], want)
	}
	if code, out = h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"canned_response_id":"`+cannedID+`","status":"resolved"}`, map[string]string{"ticketID": aID}); code != 201 ||
		out["ticket"].(map[string]any)["status"] != "resolved" || !strings.Contains(toString(out["message"].(map[string]any)["body"]), "refund for") {
		t.Fatalf("canned reply %d %v", code, out)
	}
	_, list := h.asOperator(h.s.adminSupportListCanned, http.MethodGet, "", "", nil)
	found := false
	for _, item := range list["canned_responses"].([]any) {
		if m := item.(map[string]any); m["id"] == cannedID && m["usage_count"].(float64) == 1 {
			found = true
		}
	}
	if !found {
		t.Fatal("canned usage not counted")
	}
	if code, out = h.asOperator(h.s.adminSupportDeleteCanned, http.MethodDelete, "", "", map[string]string{"responseID": cannedID}); code != 200 || out["canned_response"].(map[string]any)["is_active"] != false {
		t.Fatalf("deactivate %d %v", code, out)
	}

	// Bulk: priority on two tickets, one unknown id fails alone.
	missing := uuid.NewString()
	code, bulk := h.asOperator(h.s.adminSupportBulk, http.MethodPost, "", `{"ticket_ids":["`+cID+`","`+aID+`","`+missing+`"],"action":"priority","value":"urgent"}`, nil)
	if code != 200 || len(bulk["updated"].([]any)) != 2 || len(bulk["failed"].([]any)) != 1 {
		t.Fatalf("bulk %d %v", code, bulk)
	}
	at := h.adminDetail(cID)["ticket"].(map[string]any)
	due, _ := time.Parse(time.RFC3339, toString(at["first_response_due_at"]))
	if at["priority"] != "urgent" || time.Until(due) > time.Hour+time.Minute {
		t.Fatalf("urgent retarget %v", at)
	}
	if code, bulk = h.asOperator(h.s.adminSupportBulk, http.MethodPost, "", `{"ticket_ids":["`+cID+`"],"action":"claim"}`, nil); code != 200 || len(bulk["updated"].([]any)) != 1 {
		t.Fatalf("bulk claim %d %v", code, bulk)
	}
	_, mine := h.asOperator(h.s.adminSupportQueue, http.MethodGet, "assignee=me&status=all", "", nil)
	if mine["total"].(float64) < 1 {
		t.Fatal("assignee=me filter")
	}
	_, agents := h.asOperator(h.s.adminSupportAgents, http.MethodGet, "", "", nil)
	listed := false
	for _, agent := range agents["agents"].([]any) {
		if agent.(map[string]any)["id"] == h.operator {
			listed = true
		}
	}
	if !listed {
		t.Fatal("support operator missing from agents")
	}

	// CSV export: operational fields only.
	rec := httptest.NewRecorder()
	h.s.adminSupportExport(rec, supportRequest(http.MethodGet, "q="+toString(a["reference"]), "", h.operatorPrincipal(), nil))
	csvText := rec.Body.String()
	if rec.Code != 200 || !strings.HasPrefix(rec.Header().Get("Content-Type"), "text/csv") || !strings.Contains(csvText, toString(a["reference"])) ||
		strings.Contains(csvText, "Charged twice") || strings.Contains(csvText, "Priya") {
		t.Fatalf("export %d %q", rec.Code, csvText)
	}
}

func TestSupportWebsiteContactFormPostgres(t *testing.T) {
	h := newSupportHarness(t)
	email := "visitor." + strings.ReplaceAll(uuid.NewString()[:8], "-", "") + "@support-qa.example"
	post := func(body map[string]any) (int, map[string]any) {
		raw, _ := json.Marshal(body)
		r := supportRequest(http.MethodPost, "", string(raw), nil, nil)
		r.RemoteAddr = "203.0.113.7:4242"
		return h.do(h.s.supportContact, r)
	}
	form := map[string]any{"email": email, "name": "Visitor", "category": "account_login", "subject": "Locked out of my account",
		"description": "I can't sign in and have no recovery code", "locale": "en-GB", "website": ""}
	code, out := post(form)
	if code != http.StatusAccepted || !supportReferencePattern.MatchString(toString(out["reference"])) {
		t.Fatalf("contact %d %v", code, out)
	}
	var channel, contact, platform string
	var member any
	if err := h.f.db.QueryRow(`SELECT channel, contact_email, requester_member_id, COALESCE(platform,'') FROM support.tickets WHERE reference=$1`, out["reference"]).Scan(&channel, &contact, &member, &platform); err != nil {
		t.Fatal(err)
	}
	if channel != "website" || contact != email || member != nil || platform != "web" {
		t.Fatalf("website ticket channel=%s email=%s member=%v", channel, contact, member)
	}
	var accounts int
	if err := h.f.db.QueryRow(`SELECT COUNT(*) FROM user_management.users WHERE email=$1`, email).Scan(&accounts); err != nil || accounts != 0 {
		t.Fatal("contact form must never create an account")
	}
	// Agents see the address and reply by email; no notification is possible.
	ticketID := ""
	_ = h.f.db.QueryRow(`SELECT id::text FROM support.tickets WHERE reference=$1`, out["reference"]).Scan(&ticketID)
	at := h.adminDetail(ticketID)["ticket"].(map[string]any)
	if at["requester"].(map[string]any)["kind"] != "contact" || at["requester"].(map[string]any)["email"] != email {
		t.Fatalf("contact requester %v", at["requester"])
	}
	if code, _ := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"We've emailed you instructions."}`, map[string]string{"ticketID": ticketID}); code != 201 {
		t.Fatal("reply to website ticket")
	}
	// Honeypot: accepted silently, nothing stored.
	bot := map[string]any{}
	for k, v := range form {
		bot[k] = v
	}
	bot["website"] = "http://spam.example"
	bot["subject"] = "Buy now"
	before := 0
	_ = h.f.db.QueryRow(`SELECT COUNT(*) FROM support.tickets WHERE contact_email=$1`, email).Scan(&before)
	if code, out = post(bot); code != http.StatusAccepted || out["reference"] != nil {
		t.Fatalf("honeypot %d %v", code, out)
	}
	after := 0
	_ = h.f.db.QueryRow(`SELECT COUNT(*) FROM support.tickets WHERE contact_email=$1`, email).Scan(&after)
	if after != before {
		t.Fatal("honeypot submission stored")
	}
	bad := map[string]any{}
	for k, v := range form {
		bad[k] = v
	}
	bad["email"] = "not-an-email"
	if code, out = post(bad); code != 400 || out["error_code"] != "SUPPORT_INVALID_EMAIL" {
		t.Fatalf("bad email %d %v", code, out)
	}
	// Per-address limit: 3 per hour.
	for i := 0; i < 2; i++ {
		form["subject"] = "Another question " + string(rune('A'+i))
		form["description"] = "More detail " + string(rune('A'+i))
		if code, out = post(form); code != http.StatusAccepted {
			t.Fatalf("contact %d: %d %v", i, code, out)
		}
	}
	form["subject"], form["description"] = "Fourth question", "Over the address limit"
	if code, out = post(form); code != http.StatusTooManyRequests || out["error_code"] != "SUPPORT_RATE_LIMITED" {
		t.Fatalf("address limit %d %v", code, out)
	}
	// Per-IP limit (5 per hour) across addresses.
	supportContactLimiter = newClientErrorRateLimiter(time.Now)
	limited := false
	for i := 0; i < 7; i++ {
		form["email"] = "ip" + string(rune('a'+i)) + "." + email
		form["subject"] = "IP question " + string(rune('A'+i))
		if code, _ = post(form); code == http.StatusTooManyRequests {
			limited = true
			break
		}
	}
	if !limited {
		t.Fatal("per-IP limit not applied")
	}
}

func TestSupportErasureAndExportPostgres(t *testing.T) {
	h := newSupportHarness(t)
	_, up := h.upload(h.member, supportPNG(t, 16, 16), "mine.png")
	attachmentID := toString(up["attachment"].(map[string]any)["id"])
	ticketID := toString(h.mustCreate(h.member, "privacy_data", "Delete my photos", "Please remove my old photos from 2024", attachmentID)["id"])
	if code, _ := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"INTERNAL: member mentions photos from 2024","visibility":"internal"}`, map[string]string{"ticketID": ticketID}); code != 201 {
		t.Fatal("note")
	}
	if code, _ := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"Done, Priya — removed."}`, map[string]string{"ticketID": ticketID}); code != 201 {
		t.Fatal("reply")
	}
	// Export: the member's tickets with the public conversation only.
	var raw []byte
	for _, section := range accountExportSections() {
		if section.name == "support_tickets" {
			if err := h.f.db.QueryRow(section.query, h.member).Scan(&raw); err != nil {
				t.Fatal(err)
			}
		}
	}
	exported := string(raw)
	if !strings.Contains(exported, "Delete my photos") || !strings.Contains(exported, "Done, Priya") || !strings.Contains(exported, "mine.png") ||
		strings.Contains(exported, "INTERNAL") || strings.Contains(exported, "private/support") {
		t.Fatalf("export section %s", exported)
	}
	// Erasure scrubs the text and queues the bytes.
	var key string
	if err := h.f.db.QueryRow(`SELECT storage_path FROM support.ticket_attachments WHERE id=$1`, attachmentID).Scan(&key); err != nil {
		t.Fatal(err)
	}
	tx, err := h.f.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	for _, step := range accountErasureSteps() {
		if !strings.HasPrefix(step.label, "support_") {
			continue
		}
		args := []any{h.member}
		if step.usesTombstone {
			args = append(args, erasureTombstone)
		}
		if _, err := tx.Exec(step.query, args...); err != nil {
			_ = tx.Rollback()
			t.Fatal(step.label, err)
		}
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	var remaining int
	if err := h.f.db.QueryRow(`SELECT COUNT(*) FROM support.ticket_messages WHERE ticket_id=$1 AND body<>$2`, ticketID, erasureTombstone).Scan(&remaining); err != nil || remaining != 0 {
		t.Fatalf("%d messages survived erasure", remaining)
	}
	var subject string
	if err := h.f.db.QueryRow(`SELECT subject FROM support.tickets WHERE id=$1`, ticketID).Scan(&subject); err != nil || subject != erasureTombstone {
		t.Fatalf("subject %q", subject)
	}
	if _, err := h.s.runSupportMaintenance(context.Background(), h.f.db, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}
	if ok, _ := h.store.Exists(context.Background(), key); ok {
		t.Fatal("erased member's attachment still stored")
	}
	var rows int
	_ = h.f.db.QueryRow(`SELECT COUNT(*) FROM support.ticket_attachments WHERE id=$1`, attachmentID).Scan(&rows)
	if rows != 0 {
		t.Fatal("attachment row not released")
	}
}

// ── categories and member notifications (2026-10-02) ────────────────────────

// case: support.support_ticket_form.submit_support_ticket.api_contract
func TestSupportCategoriesEndpoint(t *testing.T) {
	t.Parallel()
	s := &Server{}
	rec := httptest.NewRecorder()
	s.supportListCategories(rec, supportRequest(http.MethodGet, "", "", nil, nil))
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("signed-out categories: %d, want 401", rec.Code)
	}
	rec = httptest.NewRecorder()
	member := &securityPrincipal{UserID: uuid.NewString(), Roles: map[string]bool{"user": true}}
	s.supportListCategories(rec, supportRequest(http.MethodGet, "", "", member, nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("categories: %d %s", rec.Code, rec.Body.String())
	}
	var out struct {
		Categories []struct {
			Key, Label string
			Safety     bool
		}
		Limits map[string]any
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatal(err)
	}
	if len(out.Categories) != len(supportCategories) {
		t.Fatalf("got %d categories, server accepts %d", len(out.Categories), len(supportCategories))
	}
	seen := map[string]bool{}
	for i, c := range out.Categories {
		if _, ok := supportCategories[c.Key]; !ok || seen[c.Key] || c.Label == "" {
			t.Fatalf("category %d %+v is unknown, repeated or unlabelled", i, c)
		}
		seen[c.Key] = true
		if c.Safety != (c.Key == "safety_harassment") {
			t.Fatalf("safety flag wrong on %s", c.Key)
		}
		// Every listed category is one the create validator accepts.
		if _, err := validateSupportTicketInput(map[string]any{"category": c.Key, "subject": "Help please", "description": "Details"}); err != nil {
			t.Fatalf("listed category %s is refused: %v", c.Key, err)
		}
	}
	if out.Categories[len(out.Categories)-1].Key != "other" {
		t.Fatal("'other' should be offered last")
	}
	if out.Limits["subject_max_chars"].(float64) != supportSubjectMaxRunes || out.Limits["attachments_per_message"].(float64) != supportMaxAttachmentsPerMs ||
		out.Limits["image_max_bytes"].(float64) != supportImageMaxBytes {
		t.Fatalf("limits %v do not match the server rules", out.Limits)
	}
}

// case: notifications.notification_inbox.inkwell_ontap.api_contract
func TestSupportStatusNotificationsPostgres(t *testing.T) {
	h := newSupportHarness(t)
	ticketID := toString(h.mustCreate(h.member, "technical", "Photos fail to upload", "Upload spins forever.")["id"])
	params := map[string]string{"ticketID": ticketID}

	// Waiting on the member without a public reply (status only) tells them.
	if code, out := h.asOperator(h.s.adminSupportUpdateTicket, http.MethodPatch, "", `{"status":"pending_member"}`, params); code != 200 {
		t.Fatalf("pending_member %d %v", code, out)
	}
	if h.f.notifications(t, h.member, "support.status") != 1 {
		t.Fatal("setting pending_member should notify the member")
	}
	var payloadStatus, route string
	if err := h.f.db.QueryRow(`SELECT payload->>'status', action_route FROM matching.notification_outbox
		WHERE recipient_user_id=$1 AND event_type='support.status'`, h.member).Scan(&payloadStatus, &route); err != nil {
		t.Fatal(err)
	}
	if payloadStatus != "pending_member" || route != "/support/tickets/"+ticketID {
		t.Fatalf("status notification payload status=%q route=%q", payloadStatus, route)
	}

	// A plain public reply notifies once as a reply.
	if code, out := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"Which phone is this on?"}`, params); code != 201 {
		t.Fatalf("reply %d %v", code, out)
	}
	if h.f.notifications(t, h.member, "support.reply") != 1 || h.f.notifications(t, h.member, "support.status") != 1 {
		t.Fatal("a public reply should add exactly one reply notification")
	}

	// A reply that resolves the ticket sends one notification: the resolution.
	if code, out := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"Fixed in 1.4.1.","status":"resolved"}`, params); code != 201 ||
		out["ticket"].(map[string]any)["status"] != "resolved" {
		t.Fatalf("resolving reply %d %v", code, out)
	}
	if h.f.notifications(t, h.member, "support.reply") != 1 || h.f.notifications(t, h.member, "support.status") != 2 {
		t.Fatalf("resolving reply: reply=%d status=%d, want 1 and 2",
			h.f.notifications(t, h.member, "support.reply"), h.f.notifications(t, h.member, "support.status"))
	}

	// Internal notes never notify, even with no status change.
	if code, _ := h.asOperator(h.s.adminSupportReply, http.MethodPost, "", `{"body":"Root cause: CDN timeout","visibility":"internal"}`, params); code != 201 {
		t.Fatal("note")
	}
	if h.f.notifications(t, h.member, "support.reply") != 1 || h.f.notifications(t, h.member, "support.status") != 2 {
		t.Fatal("internal notes must not notify")
	}
}
