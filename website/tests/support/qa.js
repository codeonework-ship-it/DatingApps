// Locating Flutter web controls by their qa.* automation id.
//
// QaId (app/lib/core/widgets/qa_id.dart) sets a semantics *identifier*, which
// Flutter web renders as `flt-semantics-identifier="qa.x"` on the control's
// flt-semantics node. The accessible name stays the localized label (the
// sign-in button is named "Sign in"), so qa ids are never matched with
// getByRole({name}) / getByLabel: screen readers must not see them.
//
// For a button the identifier sits on the button node itself (role="button",
// clickable). For a text field it sits on a wrapper; the editable <input> or
// <textarea> is inside it — use qaField().

const attr = 'flt-semantics-identifier';
const quote = value => JSON.stringify(String(value));

/** The node whose qa id is exactly `id`. `scope` is a Page or a Locator. */
export const qaId = (scope, id) => scope.locator(`flt-semantics[${attr}=${quote(id)}]`);

/**
 * Nodes whose qa id starts with `prefix`, for per-item ids such as
 * `qa.matches.match_row.<matchId>` or `qa.chat.message.<messageId>`.
 */
export const qaIdPrefix = (scope, prefix) => scope.locator(`flt-semantics[${attr}^=${quote(prefix)}]`);

/** The editable input of the text field whose qa id is `id`. */
export const qaField = (scope, id) => qaId(scope, id).locator('input, textarea');

/** The qa id of the node `locator` resolves to. */
export const qaIdOf = locator => locator.getAttribute(attr);
