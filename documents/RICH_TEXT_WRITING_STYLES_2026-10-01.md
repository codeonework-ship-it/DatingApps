# Rich text and writing styles for Open Chapters and profile stories (2026-10-01)

The owner asked for this: "for blogs and stories we need the text editor to be added as a
functionality so that the user can change the writing styles".

Members can now format chapters (Open Chapters) and profile stories, and choose a
**writing style** that sets the overall look. Plain-text chapters and stories, and
older app versions, keep working without changes.

## Decision: a constrained block model, not HTML

Formatting is stored as a small JSON document that the BFF validates strictly. We
never store or render HTML, so member text cannot become markup anywhere.

```json
{
  "version": 1,
  "style": "journal",
  "blocks": [
    {"type": "heading", "spans": [{"text": "Sunday"}]},
    {"type": "paragraph", "align": "center", "spans": [
      {"text": "Coffee, "},
      {"text": "a bookshop", "marks": ["bold", "italic"]},
      {"text": "Shop", "marks": ["link"], "href": "https://books.example"}
    ]},
    {"type": "bullet", "spans": [{"text": "Oat latte"}]},
    {"type": "divider"}
  ]
}
```

- **One block per line.** Each block is one line of the plain text, joined with `\n`.
  A blank line is an empty paragraph, so legacy text converts to paragraphs and back
  without any change.
- **Block types:** `paragraph`, `heading`, `subheading`, `quote`, `bullet`, `numbered`,
  `divider`, `callout`. **Alignment:** `start` (the default, omitted), `center`, `end`.
- **Inline marks:** `bold`, `italic`, `underline`, `strikethrough`, `highlight`, `link`.
  A `link` needs an `href`, and an `href` needs `link`. The `href` must be an absolute
  `https://` URL with a host and no credentials, at most 2,048 bytes. Readers see a
  confirmation ("Open this link?") before the link leaves the app. On the website
  links carry `rel="nofollow ugc noopener noreferrer"`.
- **Writing styles:** `classic`, `modern` (the default, and how plain chapters always
  looked), `journal`, `typewriter`, `poetic`.

### The plain text is derived and stays authoritative for everything else

The server works out the plain text from the document: one line per block, `• ` before
bullets, `N. ` before numbered items (numbering restarts after any other block), and
`* * *` for a divider. It stores that text in the existing column:
`matching.blog_posts.body` for chapters, and `text` for each story. Search, excerpts,
notifications, report snapshots, wall and Today cards, public-link excerpts and older
clients all keep reading `body` or `text`.

| Client sends | Server stores |
|---|---|
| `content` (current app) | the validated `content`; `body`/`text` is derived from it, and any `body`/`text` the client sent is ignored |
| `body`/`text` only (older app) | a plain-text chapter or story. For a chapter, earlier formatting is cleared (`content = NULL`) so the two can never disagree |
| nothing new (existing rows) | unchanged; renders exactly as before |

### Validation (`backend/internal/bff/mobile/rich_text.go`)

The server rejects all of the following with a 400 and a message the member can act on:

- content that is not an object, such as an HTML string;
- unknown keys at any level (decoded with `DisallowUnknownFields`);
- `version` other than 1, or an unknown style, block type, alignment or mark;
- the same mark listed twice;
- line breaks, U+2028/2029 or control characters (tab is allowed) inside span text;
- text on a divider;
- `href` without `link`, `link` without `href`, and any link that is not https, has
  credentials, has spaces, or is relative;
- more than 400 blocks (40 for a story), more than 200 spans in a block, or more than
  96 KB of JSON (12 KB for a story);
- derived text longer than 8,000 characters (400 for a story).

The server also normalises what it stores: it puts marks in a fixed order, merges
neighbouring spans with the same formatting, drops empty spans, and leaves out
`align: start`. A retry of a save that may already have succeeded compares the
normalised content, so a repeated identical save reads back the saved version instead
of returning a 409 conflict.

Span text is plain text. It may contain characters such as `<`. Every renderer (Flutter,
the website's DOM `textContent`, Django autoescape) shows it as text.

## Data

- Migration `backend/scripts/127_rich_text_writing_styles.sql` adds
  `matching.blog_posts.content JSONB` (NULL means a plain-text chapter). A CHECK
  constraint guards the shape (version 1, a known style, a blocks array of at most 400,
  at most 128 KB). The migration is registered in `scripts_run_order.txt` and
  `scripts/migrate_local_postgres.sh`.
- Profile stories need no migration. Each story object in
  `user_management.profile_stories.stories` gains an optional `content` key.
- Account export already serialises both tables whole, so it includes the formatted
  documents. Erasure deletes the rows. The cleanup of deleted chapters now clears
  `content` together with `title` and `body`.
- Report snapshots store the whole `blogPost`, so they now include `content`.

## API (OpenAPI `RichDocument` schema)

- `PUT /v1/blog/posts/{id}` accepts an optional `content`. `body` is optional when
  `content` is sent. Responses include `content` (null for plain chapters).
- `GET/PUT /v1/profile/{id}/stories`: each story accepts and returns an optional
  `content`.
- `GET /v1/blog/public/{shareID}` adds `content`: the formatting of exactly the
  approved excerpt (`richSlice`), whose derived text equals `excerpt`. It is null for
  plain and joint chapters. The excerpt is bound to the pinned source version, so this
  is the same text the member approved.

## Writing styles (bundled fonts only, nothing downloaded)

| Style | App (Flutter) | Website (public preview) |
|---|---|---|
| Classic | Bodoni Moda 18, line height 1.7 | self-hosted Bodoni Moda, Georgia fallback |
| Modern (default) | Figtree 16, line height 1.65: the look plain chapters already had | self-hosted Figtree, system-ui fallback |
| Journal | Bodoni Moda italic 18, line height 1.8 | Bodoni, italic |
| Typewriter | Chakra Petch 15, letter-spacing 0.6 | system monospace stack (Chakra Petch is not shipped on the website) |
| Poetic | Bodoni Moda 19, line height 2.0, centred: start-aligned blocks render centred and `end` still wins | Bodoni, centred |

Profile stories default to Classic, which matches the existing story card.
`WritingStyleSpec` (`app/lib/core/rich_text/writing_styles.dart`) takes every colour
from the `ColorScheme`. Highlight uses `tertiaryContainer` with `onTertiaryContainer`,
and callouts use `secondaryContainer` with `onSecondaryContainer`. These are contrast
pairs in every theme, including Daylight, Ember and the cinematic presets.

## App (`app/lib/core/rich_text/`)

- `rich_document.dart`: the model, a defensive `tryParse` (unknown types become
  paragraphs, unknown marks and unsafe links are dropped), `plainText`, `wordCount`,
  `isSafeRichHref`.
- `rich_text_controller.dart`: a lightweight editor built on a `TextEditingController`
  subclass. We chose not to use flutter_quill because of its size, its font and network
  behaviour, and the delta-to-blocks conversion it would need. The editable text is
  exactly the plain body, list markers and dividers included. A per-character list holds
  the inline marks and a per-line list holds the block formats. Every text change
  (typing, IME, paste, autocorrect) is compared with the previous text and both lists are
  updated to match. Behaviour:
  - Enter continues a list; Enter on an empty list item ends the list.
  - Enter after a heading starts a paragraph.
  - Backspace into a list marker removes the list formatting.
  - The caret is kept out of list markers.
  - Numbering is updated automatically.
  - Typing next to a link does not extend it.
  - Pasted text is plain: carriage returns are normalised, control characters are
    stripped, and it takes the formatting at the cursor.
  - Undo and redo cover text, formatting and style. They are routed away from the text
    field's own text-only history.
- `rich_text_editor.dart`: the formatting toolbar, the field, the word count and the
  `WritingStylePicker`. Each style chip is drawn in its own typeface, and the editor
  changes typeface as soon as a style is picked.
  - Toolbar: undo, redo, bold, italic, underline, strikethrough, highlight, link,
    text-style menu (paragraph, heading, subheading, quote, callout), bulleted list,
    numbered list, section break, alignment menu, clear formatting.
  - Buttons are at least 48 pt, with tooltips and a toggled state for screen readers.
  - Shortcuts work on web and desktop with Ctrl or ⌘:
    - B, I and U: bold, italic, underline;
    - Shift+X: strikethrough; Shift+H: highlight; K: link;
    - Alt+1 and Alt+2: heading and subheading;
    - Shift+8 and Shift+7: bulleted and numbered list;
    - \\: clear formatting;
    - Z: undo; Shift+Z or Y: redo.
- `rich_document_view.dart`: `RichDocumentView` and `RichBody`. `RichBody` falls back
  to the exact legacy `SelectableText` or `Text` when there is no formatting.
  - Headings are semantic headers.
  - A divider has the screen-reader label "Section break".
  - Text can be selected across blocks with `SelectionArea`.
  - Text follows the system text size.

### Where it is used

| Surface | Change |
|---|---|
| Chapter editor (`blog_editor.dart`) | `RichTextEditor` replaces the story field. Save sends `content` and the derived `body`. Preview renders `RichDocumentView`. Picking a style or formatting counts as an edit, so the existing "Leave without saving?" guard (`PopScope`) still applies. "Use saved version" reloads the formatting. |
| Chapter detail (`BlogDetailScreen`) | `RichBody`: formatted chapters use their writing style; legacy chapters render as before. |
| Profile stories editor and `StoryMomentCard` | Profile details uses these through `ProfileStoriesSection`. Each story has its own editor and style. Cards render `RichBody` at 1.2 scale (Classic ≈ the old 22 pt Bodoni); plain stories keep the original style. |
| Cards (Today wall, writers, featured, social) | Unchanged. They show the derived plain `body` as an excerpt. |
| Public website (`website/public/story.js` and `story.css`) | Builds the formatted excerpt with DOM nodes and `textContent` only, never `innerHTML`. Unknown blocks degrade to text. No inline styles, so it works under the site's CSP. |
| Control panel moderation (`templates/control_panel/_rich_snapshot.html`) | Formatted snapshots render with autoescaped text and simple tags, labelled block types and the writing style. Links appear as `[link: address]`, not as clickable anchors. |

### Localisation

The editor and reader have 46 new ARB keys (`rich*`) in all 10 locales. `richL10n()`
falls back to English when a host has no app localizations (embedded previews and
tests). The existing chapter-editor and story-editor copy was hard-coded English before
this change and is unchanged.

## Known limits

- **Alignment in the editor.** A single text field cannot show per-paragraph
  alignment. The toolbar shows the current block's alignment, the editor says
  "Alignment and spacing show in Preview and for readers", and Preview and every
  reader show it.
- **Numbering in public excerpts.** A public excerpt that starts partway through a
  numbered list is numbered from 1 in the formatted view. The plain `excerpt` keeps the
  original numbers.
- **Plain-text saves from older apps.** Saving from an older app clears a chapter's
  formatting. This is intentional, so the formatting never disagrees with the text.
- **Links in the editor.** A link in the editor cannot be tapped. Links work in the
  reader, after a confirmation.

## Tests

- **Go** (`backend/internal/bff/mobile/rich_text_test.go`):
  - validation rejects unsafe or unknown formatting, HTML strings and oversize
    documents;
  - the derived plain text is correct;
  - legacy body-only drafts are still accepted;
  - stories accept content;
  - excerpt slicing keeps the right formatting;
  - Postgres round trip: chapter save, readers, the retry readback, the public preview
    limited to the excerpt, export of chapters and stories, an older-client plain save
    clearing formatting, and the database CHECK.
  - `blog_connections_test.go` now expects the public allowlist to include `content`.
- **Flutter:**
  - `test/core/rich_text/rich_text_controller_test.dart`: model and editor behaviour;
  - `test/core/rich_text/rich_text_widgets_test.dart`: toolbar, shortcuts, link dialog,
    style picker, German localisation, 320 px and 1280 px at 2× text, 48 pt targets,
    semantic headings, highlight contrast in dark mode, legacy rendering;
  - `test/features/blog/blog_rich_text_test.dart`: the save payload, a legacy round
    trip, the PopScope guard, detail rendering;
  - `test/features/intentional_dating/profile_stories_rich_text_test.dart`.
- **Website:** `website/tests/blog-public.spec.js` checks the formatted excerpt is safe
  DOM (no injected elements, https-only nofollow links) and that plain excerpts are
  unchanged.
- **Control panel:** `control_panel/tests/test_blog.py` checks the formatted snapshot
  is escaped and its links cannot be clicked.
