# Blog topics, Top rated, subscriptions and rewards

Delivered 2026-10-01. Migration: `backend/scripts/113_blog_topics_subscriptions_rewards.sql`.

The product idea: Connect is where members' feelings are heard and acknowledged. Members share them through
chapters (blog posts), stories and photos on the wall. Every meaningful contribution is rewarded, good
writing rises to the top, and readers can subscribe to writers they love.

## Topics

Ten seeded topics. A chapter has at most one topic (optional).

| slug | title |
|---|---|
| feelings | Feelings & healing |
| love | Love & relationships |
| growth | Self-growth |
| family | Family & friends |
| travel | Travel & places |
| food | Food & home |
| culture | Books, films & music |
| work | Work & ambition |
| humour | Funny moments |
| reflection | Faith & reflection |

## Rewards (XP)

Rewards use the existing level and XP system: each source has a base XP and daily caps, and an award can
never be granted twice. Rewards go to creators for what readers do, never to readers for tapping, so liking
cannot be farmed.

| Source | Who earns | XP | Daily cap |
|---|---|---|---|
| `story_published` | Author, first time a chapter is shared beyond Only me | 25 | 50 (2 a day) |
| `photo_shared` | Author of a Photo Themes photo | 20 | 40 (2 a day) |
| `like_received` | Author of a chapter or photo, per member who likes it | 2 | 40 (20 a day) |
| `comment_received` | Author, when they approve a comment | 5 | 50 (10 a day) |
| `comment_approved` | Commenter, when the author approves it | 5 | 30 (6 a day) |
| `subscriber_gained` | Writer, per new subscriber | 10 | 100 (10 a day) |
| `wall_tier_reached` | Author, per new wall tier | 50 | 150 (3 a day) |
| `cover_of_week` | Author of the Cover of the Week | 150 | 150 (1 a day) |

Awards are queued in the same transaction as the action and granted by the progression worker within a second.
Where XP is excluded from the release, no awards are queued.

## Subscriptions

A member can subscribe to a writer whose chapters they can see. When the writer first shares a chapter beyond
Only me, subscribers who can see it get a notification ("New chapter from a writer you follow"). The writer is
told "A member subscribed to your chapters" without the subscriber's name. Blocks remove nothing silently but
hide the writer's chapters as before.

## API

Chapter (`post`) JSON gains:

```json
{"topic": "feelings", "topic_title": "Feelings & healing",
 "author_subscribed": true, "author_subscriber_count": 12}
```

| Method and path | Body | Response |
|---|---|---|
| `GET /v1/blog/topics` | none | `{"topics": [{"slug","title","description","post_count"}]}` |
| `PUT /v1/blog/posts/{postID}` | existing body plus optional `"topic": slug or ""` | `{"post": Post}` |
| `GET /v1/blog/posts?scope=top&topic=` | none | `{"posts": [Post], "next_cursor": ""}`: top rated community chapters from the last 30 days, ranked by likes, approved comments, then unique views; up to 20 |
| `GET /v1/blog/posts?scope=subscriptions&before=&topic=` | none | `{"posts": [Post], "next_cursor"}`: newest chapters from writers I subscribe to |
| `GET /v1/blog/posts?scope=community&topic=feelings` | none | existing feeds now accept a `topic` filter on every scope |
| `PUT /v1/blog/authors/{authorID}/subscription` | none | `{"subscribed": true, "subscriber_count": n}` |
| `DELETE /v1/blog/authors/{authorID}/subscription` | none | `{"subscribed": false, "subscriber_count": n}` |
| `GET /v1/blog/subscriptions` | none | `{"writers": [{"author_id","name","subscriber_count","latest_title","latest_post_id"}]}` |

Errors: `400` unknown topic, `403` subscribing to yourself or not eligible, `404` writer not visible.
