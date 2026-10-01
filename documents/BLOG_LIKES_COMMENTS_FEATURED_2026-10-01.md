# Blog likes, comments and Featured Stories

Delivered 2026-10-01. Members can like and comment on chapters. A chapter that the community loves can be
promoted to **Featured Stories**, a wall every member sees on Today and in the Blog.

Migration: `backend/scripts/108_blog_likes_comments_featuring.sql`. Routes live under `/v1/blog/` and
follow the existing `intentional_dating_enabled` flag, like the rest of the blog.

## How a story reaches other members' walls

The wall is each member's **Today** screen ("On your wall"). Reach is tiered:

| Engagement on the chapter | Reach |
|---|---|
| 50 likes + 5 approved comments | 50 members' walls |
| 100 likes + 10 approved comments | 100 members' walls |

Tiers are set with `BLOG_WALL_TIERS` as `likes:comments:walls,...` (local development uses
`3:1:50,5:2:100`). More tiers can be added without code changes.

Rules:

1. Only **Connect community** chapters whose author turned on **Allow featuring**. Turning it off takes the
   chapter off every wall immediately.
2. The chapter must be active with **no open report**. A pending report pauses it everywhere until a moderator
   decides.
3. Likes and approved comments count only from active members. Reach only grows: unliking does not pull a
   chapter off walls it already reached.
4. Who is reached first: the author's friends, then members in the same city, then a stable pseudo-random
   order. Only adult, active members with a complete profile who have no block with the author are reached.
5. The author is notified once per new tier. A chapter stays on walls for 14 days after it first qualified.

## Comments are approved by the author

A comment starts as `pending` and is visible only to its writer and the chapter's author. The author approves
or declines it. Only approved comments count toward featuring and are shown to everyone. Writers and authors
can delete a comment. Every comment can be reported (`kind` = `comment`) through the existing report endpoint.

Limits: a member cannot like or comment on their own chapter, comments are 1–500 characters, 30 comments and
300 likes per member per day.

## API

Chapter (`post`) JSON gains these fields everywhere a post is returned:

```json
{"like_count": 12, "liked_by_me": true, "comment_count": 3, "pending_comment_count": 1,
 "allow_featuring": true, "featured": true, "wall_reach": 50,
 "next_tier": {"likes": 100, "comments": 10, "reach": 100, "likes_needed": 88, "comments_needed": 7}}
```

`pending_comment_count` and `next_tier` are only for the author (`next_tier` is null when no higher tier exists). `featured` is true while the chapter is on walls, and `wall_reach` is how many walls it is on.

Comment JSON:

```json
{"id": "uuid", "post_id": "uuid", "author_id": "uuid", "author_name": "Priya",
 "body": "This made me want to go to that bookshop.", "status": "pending|approved|declined",
 "mine": true, "can_moderate": false, "created_at": "RFC3339"}
```

| Method and path | Body | Response |
|---|---|---|
| `PUT /v1/blog/posts/{postID}` | existing body plus optional `"allow_featuring": bool` | `{"post": Post}` |
| `PUT /v1/blog/posts/{postID}/like` | none | `{"post": Post}` |
| `DELETE /v1/blog/posts/{postID}/like` | none | `{"post": Post}` |
| `GET /v1/blog/posts/{postID}/comments` | none | `{"comments": [Comment]}`, oldest first, up to 200 |
| `PUT /v1/blog/posts/{postID}/comments/{commentID}` | `{"body"}` with a client-generated UUID | `{"comment": Comment}` |
| `POST /v1/blog/posts/{postID}/comments/{commentID}/decision` | `{"decision": "approve\|decline"}` (chapter author) | `{"comment": Comment}` |
| `DELETE /v1/blog/posts/{postID}/comments/{commentID}` | none (comment writer or chapter author) | `{"deleted": true}` |
| `GET /v1/blog/featured` | none | `{"posts": [Post]}`: chapters on my wall, newest delivery first, up to 20 |
| `POST /v1/blog/reports/comment/{commentID}` | `{"reason","description"}` | existing report response |

Errors use the existing blog shapes: `400` invalid input, `403` not allowed (own chapter, not the author),
`404` not visible, `409` conflict, `429` daily limit.
