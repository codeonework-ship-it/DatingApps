package mobile

import (
	"context"
	"encoding/json"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func richFixtureDoc() map[string]any {
	return map[string]any{
		"version": float64(1),
		"style":   "journal",
		"blocks": []any{
			map[string]any{"type": "heading", "spans": []any{map[string]any{"text": "Sunday"}}},
			map[string]any{"type": "paragraph", "align": "center", "spans": []any{
				map[string]any{"text": "Coffee, "},
				map[string]any{"text": "a bookshop", "marks": []any{"italic", "bold"}},
				map[string]any{"text": " and a walk."},
			}},
			map[string]any{"type": "paragraph"},
			map[string]any{"type": "bullet", "spans": []any{map[string]any{"text": "Oat latte"}}},
			map[string]any{"type": "numbered", "spans": []any{map[string]any{"text": "Wake"}}},
			map[string]any{"type": "numbered", "spans": []any{map[string]any{"text": "Read", "marks": []any{"highlight"}}}},
			map[string]any{"type": "divider"},
			map[string]any{"type": "quote", "spans": []any{map[string]any{"text": "Slow is fine."}}},
			map[string]any{"type": "callout", "spans": []any{
				map[string]any{"text": "Shop", "marks": []any{"link", "underline"}, "href": "https://books.example/shop?q=1"},
			}},
		},
	}
}

const richFixturePlain = "Sunday\nCoffee, a bookshop and a walk.\n\n• Oat latte\n1. Wake\n2. Read\n* * *\nSlow is fine.\nShop"

func TestRichTextDerivesPlainTextAndNormalises(t *testing.T) {
	doc, err := parseRichDoc(richFixtureDoc(), blogRichLimits)
	if err != nil {
		t.Fatal(err)
	}
	if got := richPlainText(doc); got != richFixturePlain {
		t.Fatalf("plain text:\n%q\nwant\n%q", got, richFixturePlain)
	}
	if got := doc.Blocks[1].Spans[1].Marks; strings.Join(got, ",") != "bold,italic" {
		t.Fatalf("marks not canonical: %v", got)
	}
	if doc.Blocks[8].Spans[0].Href != "https://books.example/shop?q=1" {
		t.Fatal("link lost", doc.Blocks[8])
	}
	// Adjacent spans with the same marks merge; empty spans disappear.
	merged, err := parseRichDoc(map[string]any{"version": float64(1), "blocks": []any{map[string]any{"type": "paragraph", "align": "start", "spans": []any{
		map[string]any{"text": "a"}, map[string]any{"text": ""}, map[string]any{"text": "b", "marks": []any{}},
	}}}}, blogRichLimits)
	if err != nil || len(merged.Blocks[0].Spans) != 1 || merged.Blocks[0].Spans[0].Text != "ab" || merged.Blocks[0].Align != "" || merged.Style != "modern" {
		t.Fatalf("normalise: %+v %v", merged, err)
	}
	// Round trip: what we store is what we read back.
	raw, _ := json.Marshal(doc)
	if back := decodeStoredRichDoc(raw); !richDocEqual(back, doc) {
		t.Fatal("round trip changed the document")
	}
}

func TestRichTextValidationRejectsUnsafeOrUnknownFormatting(t *testing.T) {
	mutate := func(edit func(doc map[string]any)) map[string]any {
		doc := richFixtureDoc()
		edit(doc)
		return doc
	}
	block := func(doc map[string]any, i int) map[string]any { return doc["blocks"].([]any)[i].(map[string]any) }
	span := func(doc map[string]any, b, s int) map[string]any {
		return block(doc, b)["spans"].([]any)[s].(map[string]any)
	}
	cases := map[string]any{
		"html string":       "<p onclick=alert(1)>hi</p>",
		"array":             []any{"paragraph"},
		"unknown key html":  mutate(func(d map[string]any) { block(d, 0)["html"] = "<b>x</b>" }),
		"unknown root key":  mutate(func(d map[string]any) { d["css"] = "body{}" }),
		"wrong version":     mutate(func(d map[string]any) { d["version"] = float64(2) }),
		"unknown style":     mutate(func(d map[string]any) { d["style"] = "comic-sans" }),
		"unknown block":     mutate(func(d map[string]any) { block(d, 0)["type"] = "script" }),
		"unknown align":     mutate(func(d map[string]any) { block(d, 0)["align"] = "justify" }),
		"unknown mark":      mutate(func(d map[string]any) { span(d, 1, 1)["marks"] = []any{"blink"} }),
		"duplicate mark":    mutate(func(d map[string]any) { span(d, 1, 1)["marks"] = []any{"bold", "bold"} }),
		"newline in span":   mutate(func(d map[string]any) { span(d, 0, 0)["text"] = "two\nlines" }),
		"control char":      mutate(func(d map[string]any) { span(d, 0, 0)["text"] = "bell\a" }),
		"divider with text": mutate(func(d map[string]any) { block(d, 6)["spans"] = []any{map[string]any{"text": "x"}} }),
		"href without link": mutate(func(d map[string]any) { span(d, 0, 0)["href"] = "https://example.com" }),
		"link without href": mutate(func(d map[string]any) { delete(span(d, 8, 0), "href") }),
		"javascript link":   mutate(func(d map[string]any) { span(d, 8, 0)["href"] = "javascript:alert(1)" }),
		"http link":         mutate(func(d map[string]any) { span(d, 8, 0)["href"] = "http://books.example" }),
		"data link":         mutate(func(d map[string]any) { span(d, 8, 0)["href"] = "data:text/html,<script>x</script>" }),
		"relative link":     mutate(func(d map[string]any) { span(d, 8, 0)["href"] = "//books.example" }),
		"credentials link":  mutate(func(d map[string]any) { span(d, 8, 0)["href"] = "https://user:pass@books.example" }),
		"spaced link":       mutate(func(d map[string]any) { span(d, 8, 0)["href"] = " https://books.example" }),
		"oversize text":     map[string]any{"version": float64(1), "blocks": []any{map[string]any{"type": "paragraph", "spans": []any{map[string]any{"text": strings.Repeat("日", 8001)}}}}},
		"too many blocks": map[string]any{"version": float64(1), "blocks": func() []any {
			out := []any{}
			for i := 0; i < 401; i++ {
				out = append(out, map[string]any{"type": "paragraph"})
			}
			return out
		}()},
		"oversize serialise": map[string]any{"version": float64(1), "blocks": []any{map[string]any{"type": "paragraph", "spans": func() []any {
			out := []any{}
			for i := 0; i < 150; i++ {
				out = append(out, map[string]any{"text": strings.Repeat("x", 700), "marks": []any{[]string{"bold", "italic"}[i%2]}})
			}
			return out
		}()}}},
	}
	for name, raw := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := parseRichDoc(raw, blogRichLimits); err == nil || !isRichTextError(err) {
				t.Fatalf("accepted or untyped error: %v", err)
			}
		})
	}
	// A story has a tighter limit than a chapter.
	long := map[string]any{"version": float64(1), "blocks": []any{map[string]any{"type": "paragraph", "spans": []any{map[string]any{"text": strings.Repeat("a", 401)}}}}}
	if _, err := parseRichDoc(long, storyRichLimits); err == nil {
		t.Fatal("story over 400 characters accepted")
	}
}

func TestBlogDraftAcceptsLegacyPlainTextAndDerivesBodyFromContent(t *testing.T) {
	legacy := map[string]any{"expected_version": float64(0), "audience": "private", "title": "Old client", "body": "  Plain words\n\nstay plain  "}
	d, err := parseBlogDraft(legacy)
	if err != nil || d.Content != nil || d.Body != "Plain words\n\nstay plain" {
		t.Fatalf("legacy: %+v %v", d, err)
	}
	rich := map[string]any{"expected_version": float64(0), "audience": "friends", "title": "New client", "body": "a stale or forged body", "content": richFixtureDoc()}
	d, err = parseBlogDraft(rich)
	if err != nil || d.Content == nil || d.Body != richFixturePlain {
		t.Fatalf("server must derive body from content: %q %v", d.Body, err)
	}
	empty := map[string]any{"expected_version": float64(0), "audience": "friends", "title": "x", "content": map[string]any{"version": float64(1), "blocks": []any{}}}
	if _, err = parseBlogDraft(empty); err == nil {
		t.Fatal("published an empty formatted story")
	}
	rich["content"] = "<b>html</b>"
	if _, err = parseBlogDraft(rich); err == nil {
		t.Fatal("html content accepted")
	}
}

func TestProfileStoriesAcceptRichContent(t *testing.T) {
	body := map[string]any{"published": true, "expected_version": float64(0), "stories": []any{
		map[string]any{"prompt_id": "little_joy", "text": "ignored", "content": map[string]any{"version": float64(1), "style": "poetic", "blocks": []any{
			map[string]any{"type": "paragraph", "align": "center", "spans": []any{map[string]any{"text": "Tea at six", "marks": []any{"italic"}}}},
		}}},
		map[string]any{"prompt_id": "weekend", "text": "Plain story from an older app"},
	}}
	out, err := parseProfileStories(body)
	if err != nil {
		t.Fatal(err)
	}
	if out.Stories[0].Text != "Tea at six" || out.Stories[0].Content.Style != "poetic" || out.Stories[1].Content != nil || out.Stories[1].Text != "Plain story from an older app" {
		t.Fatalf("stories: %+v", out.Stories)
	}
	body["stories"].([]any)[0].(map[string]any)["content"] = map[string]any{"version": float64(1), "blocks": []any{map[string]any{"type": "iframe"}}}
	if _, err = parseProfileStories(body); err == nil {
		t.Fatal("unknown story block accepted")
	}
}

func TestRichSliceKeepsFormattingForExactExcerpt(t *testing.T) {
	doc, err := parseRichDoc(richFixtureDoc(), blogRichLimits)
	if err != nil {
		t.Fatal(err)
	}
	slice := richSlice(doc, "a bookshop and a walk.\n\n• Oat")
	if slice == nil || richPlainText(slice) != "a bookshop and a walk.\n\n• Oat" {
		t.Fatalf("slice: %q", richPlainText(slice))
	}
	if slice.Style != "journal" || slice.Blocks[0].Align != "center" || slice.Blocks[0].Spans[0].Text != "a bookshop" || strings.Join(slice.Blocks[0].Spans[0].Marks, ",") != "bold,italic" || slice.Blocks[2].Type != "bullet" {
		t.Fatalf("slice formatting: %+v", slice)
	}
	if richSlice(doc, "not in the chapter") != nil {
		t.Fatal("unbound excerpt produced formatting")
	}
	if full := richSlice(doc, richFixturePlain); !richDocEqual(full, doc) {
		t.Fatal("whole-document excerpt changed formatting")
	}
}

func TestRichChapterRoundTripPublicPreviewAndExportPostgres(t *testing.T) {
	f := newBlogTrustFixture(t)
	ctx := context.Background()
	blogEligible(t, f, f.proposer)
	blogEligible(t, f, f.invitee)
	d, err := parseBlogDraft(map[string]any{"expected_version": float64(0), "audience": "community", "title": "Formatted Sunday", "content": richFixtureDoc()})
	if err != nil {
		t.Fatal(err)
	}
	id := uuid.NewString()
	p, err := saveBlog(ctx, f.db, f.proposer, id, d)
	if err != nil {
		t.Fatal(err)
	}
	if p.Body != richFixturePlain || !richDocEqual(p.Content, d.Content) {
		t.Fatalf("saved: %q %+v", p.Body, p.Content)
	}
	// Readers get the same formatting; body stays the plain text.
	read, err := readBlog(ctx, f.db, f.invitee, id)
	if err != nil || !richDocEqual(read.Content, d.Content) || read.Body != richFixturePlain {
		t.Fatalf("reader: %+v %v", read, err)
	}
	// A lost-success retry with the same content is a readback, not a conflict.
	if _, err = saveBlog(ctx, f.db, f.proposer, id, d); err != nil {
		t.Fatal("identical retry", err)
	}
	// Public preview of an excerpt carries only that excerpt's formatting.
	pub, err := createBlogPublication(ctx, f.db, f.proposer, map[string]any{"id": uuid.NewString(), "post_id": id, "approved": true, "expected_version": float64(p.Version), "excerpt": "Coffee, a bookshop and a walk.\n\n• Oat latte"})
	if err != nil {
		t.Fatal(err)
	}
	rec := httptest.NewRecorder()
	blogServer(f).blogPublicHandler(rec, blogRoute("GET", "", "", map[string]string{"shareID": pub.ID}))
	if rec.Code != 200 {
		t.Fatal(rec.Body.String())
	}
	var public struct {
		Excerpt string   `json:"excerpt"`
		Content *richDoc `json:"content"`
	}
	if err = json.Unmarshal(rec.Body.Bytes(), &public); err != nil || public.Content == nil {
		t.Fatal("public content missing", rec.Body.String())
	}
	if richPlainText(public.Content) != public.Excerpt || strings.Contains(rec.Body.String(), "Sunday\\n") || strings.Contains(rec.Body.String(), "Slow is fine") {
		t.Fatalf("public formatting is not limited to the excerpt: %s", rec.Body.String())
	}
	// Account export includes the formatted document.
	for _, section := range accountExportSections() {
		if section.name != "blog_posts" {
			continue
		}
		var raw []byte
		if err = f.db.QueryRowContext(ctx, section.query, f.proposer).Scan(&raw); err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(raw), `"content"`) || !strings.Contains(string(raw), `"journal"`) {
			t.Fatalf("export lacks rich content: %s", raw)
		}
	}
	// An older client saving plain text clears formatting so body and content never disagree.
	p, err = saveBlog(ctx, f.db, f.proposer, id, blogDraft{Title: "Formatted Sunday", Body: "Plain edit", Audience: "community", Version: p.Version})
	if err != nil || p.Content != nil || p.Body != "Plain edit" {
		t.Fatalf("legacy edit: %+v %v", p, err)
	}
	// The database refuses documents the BFF would never write.
	if _, err = f.db.ExecContext(ctx, `UPDATE matching.blog_posts SET content='{"version":1,"style":"wingdings","blocks":[]}' WHERE id=$1`, id); err == nil {
		t.Fatal("database accepted an unknown writing style")
	}
}

func TestRichProfileStoryRoundTripPostgres(t *testing.T) {
	f := newDatePlanFixture(t)
	ctx := context.Background()
	draft, err := parseProfileStories(map[string]any{"published": false, "expected_version": float64(0), "stories": []any{
		map[string]any{"prompt_id": "care", "content": map[string]any{"version": float64(1), "style": "typewriter", "blocks": []any{
			map[string]any{"type": "bullet", "spans": []any{map[string]any{"text": "Soup when you are ill", "marks": []any{"bold"}}}},
		}}},
	}})
	if err != nil {
		t.Fatal(err)
	}
	if err = saveProfileStories(ctx, f.db, f.proposer, draft); err != nil {
		t.Fatal(err)
	}
	own, err := readProfileStories(ctx, f.db, f.proposer, f.proposer)
	if err != nil || len(own.Stories) != 1 || own.Stories[0].Text != "• Soup when you are ill" || own.Stories[0].Content == nil || own.Stories[0].Content.Style != "typewriter" {
		t.Fatalf("story: %+v %v", own, err)
	}
	for _, section := range accountExportSections() {
		if section.name != "profile_stories" {
			continue
		}
		var raw []byte
		if err = f.db.QueryRowContext(ctx, section.query, f.proposer).Scan(&raw); err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(raw), `"typewriter"`) {
			t.Fatalf("export lacks story formatting: %s", raw)
		}
	}
}
