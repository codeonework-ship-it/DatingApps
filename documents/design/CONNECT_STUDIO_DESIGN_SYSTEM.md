# Connect Studio

This direction supersedes the Afterglow visual treatment. It replaces the abstract orbit, oversized serif typography, pink gradients, and glowing surfaces with editorial photography, consistent sans-serif typography, and a restrained ink / ivory / lime system.

## Product expression

- Lead with people and an invitation to connect. Keep campaign photography distinct from actual member profiles; never imply that illustrative subjects are verified members.
- Put one primary action at the end of a clear hierarchy. The welcome screen adapts from a vertical phone composition to a two-column tablet composition.
- Use Figtree for both headings and interface text. Reserve large headlines for the welcome screen; keep functional screens compact and readable.
- Use quiet borders and mostly flat surfaces. Avoid decorative orbits, background blooms, and colored button shadows.
- Preserve existing authentication, navigation, discovery, preference persistence, and QA semantics.

## Tokens

| Role | Color |
| --- | --- |
| Light ground | `#F6F7F2` |
| Light surface | `#FFFFFF` |
| Primary ink | `#18231D` |
| Secondary ink | `#59665D` |
| Light-mode action | `#365B36` |
| Signature lime / dark-mode action | `#D5F478` |
| Dark ground | `#141A17` |
| Dark surface | `#202923` |
| Dark primary text | `#F7FAF3` |
| Dark secondary text | `#C6CFC7` |

Legacy color identifiers in `AppTheme` remain compatible with existing consumers. New components should use semantic `ColorScheme` roles where possible. Lime carries dark ink, never white text. Authentication uses a fixed dark composition; the welcome campaign uses a fixed ivory composition. Signed-in surfaces follow the account appearance setting.

## Original image asset

Saved asset: `app/assets/images/connect-cafe.png`.

Generated using the built-in imagegen tool. This is fictional adult campaign imagery, not a member photo or testimonial. No remote image service is required at runtime.

Final generation prompt:

> Use case: photorealistic-natural. Asset type: original welcome hero photograph for a premium dating app named Connect. Create a beautifully art-directed candid editorial photograph of two fictional adults around age 28-32, an Indian woman with shoulder-length dark hair wearing an ivory linen shirt and an Indian man with short curly hair wearing a dark olive overshirt, enjoying an unposed warm laugh together at a sunny outdoor cafe. Natural chemistry, contemporary real city life, sophisticated indie magazine photography, warm daylight, subtle film grain, realistic skin texture. Portrait 3:4 composition with both faces in the upper middle of the image, medium waist-up framing, clean pale concrete architecture and soft green foliage behind them, unobtrusive table at bottom. Earthy greens, warm ivory, charcoal. Camera eye level, no artificial glamour, no neon, no heart symbols, no phones. No text, no logos, no watermark, no UI. Subjects are clearly adults. This is illustrative campaign imagery, not actual member profiles.

## Review artifacts

Real Flutter widget renders, with bundled fonts, are stored in `qa/results/2026-09-26-connect-studio/`. These include welcome, sign-in, preferences, and settings in both theme configurations. The settings fixture defaults to the Light preference even when rendering the dark theme; this is fixture state, not a captured preference-change flow.

This redesign has not undergone user research or conversion testing; visual preference and engagement outcomes remain to be validated with users.
