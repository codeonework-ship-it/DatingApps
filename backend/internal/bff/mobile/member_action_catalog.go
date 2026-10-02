package mobile

import (
	"net/http"
	"sort"
	"strings"

	"github.com/go-chi/chi/v5"
)

// Member action catalog: what each member-facing route means.
//
// The activity middleware (server.go) looks every API request up here by its
// method and chi route template, relative to the API prefix ("POST /swipe"),
// and stores the stable key, a human label and a category with the activity
// row. Admin routes are not catalogued: operator actions have their own
// immutable trail (audit.security_events via operatorAuditMiddleware).
//
// Every non-admin POST/PUT/PATCH/DELETE route must have an entry:
// TestMemberActionCatalogCoversEveryMutatingRoute walks the live router and
// fails when one is missing, and /admin/activity/catalog reports the same
// coverage at runtime. Reads are catalogued only where the read itself is
// meaningful (opening a chat, viewing a profile, the discovery feed); other
// reads are recorded under their route template without a key.

type memberActionDef struct {
	Key      string `json:"key"`
	Label    string `json:"label"`
	Category string `json:"category"`
}

const (
	memberCategoryAuth       = "Auth"
	memberCategoryProfile    = "Profile"
	memberCategoryDiscovery  = "Discovery"
	memberCategoryMatches    = "Matches & chat"
	memberCategoryDates      = "Dates"
	memberCategorySocial     = "Social"
	memberCategorySafety     = "Safety"
	memberCategoryBilling    = "Billing & coins"
	memberCategoryEngagement = "Engagement"
	memberCategorySupport    = "Support"
	memberCategorySettings   = "Settings"
	memberCategoryOther      = "Other"
)

// memberActionCategories is the fixed, ordered category list.
var memberActionCategories = []string{
	memberCategoryAuth, memberCategoryProfile, memberCategoryDiscovery, memberCategoryMatches,
	memberCategoryDates, memberCategorySocial, memberCategorySafety, memberCategoryBilling,
	memberCategoryEngagement, memberCategorySupport, memberCategorySettings, memberCategoryOther,
}

func isMemberActionCategory(value string) bool {
	for _, category := range memberActionCategories {
		if category == value {
			return true
		}
	}
	return false
}

func act(key, label, category string) memberActionDef {
	return memberActionDef{Key: key, Label: label, Category: category}
}

// memberActionCatalog maps "METHOD /route/template" (without the API prefix)
// to its action.
var memberActionCatalog = map[string]memberActionDef{
	// ── Auth ───────────────────────────────────────────────────────────────
	"POST /auth/login":                       {Key: "auth.login", Label: "Signed in", Category: memberCategoryAuth},
	"POST /auth/signup":                      {Key: "auth.signup", Label: "Created an account", Category: memberCategoryAuth},
	"POST /auth/signup/bootstrap":            {Key: "auth.signup.bootstrap", Label: "Started sign-up setup", Category: memberCategoryAuth},
	"POST /auth/refresh":                     {Key: "auth.refresh", Label: "Refreshed the session", Category: memberCategoryAuth},
	"POST /auth/logout":                      {Key: "auth.logout", Label: "Signed out", Category: memberCategoryAuth},
	"POST /auth/sessions/revoke":             {Key: "auth.sessions.revoke", Label: "Signed out other sessions", Category: memberCategoryAuth},
	"POST /auth/password/change":             {Key: "auth.password.change", Label: "Changed password", Category: memberCategoryAuth},
	"POST /auth/password/recover":            {Key: "auth.password.recover", Label: "Recovered password with a recovery code", Category: memberCategoryAuth},
	"POST /auth/recovery-code/rotate":        {Key: "auth.recovery_code.rotate", Label: "Generated a new recovery code", Category: memberCategoryAuth},
	"POST /auth/recovery/assistance":         {Key: "auth.recovery.assistance", Label: "Asked for account recovery help", Category: memberCategoryAuth},
	"PATCH /users/{userID}/agreements/terms": {Key: "auth.terms.accept", Label: "Accepted the terms", Category: memberCategoryAuth},

	// ── Profile ────────────────────────────────────────────────────────────
	"PUT /profile/{userID}":                     act("profile.update", "Updated profile", memberCategoryProfile),
	"PATCH /profile/{userID}/draft":             act("profile.draft.update", "Saved a profile draft", memberCategoryProfile),
	"POST /profile/{userID}/complete":           act("profile.complete", "Completed profile setup", memberCategoryProfile),
	"POST /profile/{userID}/photos":             act("profile.photo.add", "Added a profile photo", memberCategoryProfile),
	"DELETE /profile/{userID}/photos/{photoID}": act("profile.photo.delete", "Deleted a profile photo", memberCategoryProfile),
	"POST /profile/{userID}/photos/reorder":     act("profile.photo.reorder", "Reordered profile photos", memberCategoryProfile),
	"PUT /profile/{userID}/showcase/consent":    act("profile.showcase.consent", "Changed profile showcase consent", memberCategoryProfile),
	"PUT /profile/{userID}/stories":             act("profile.stories.update", "Updated profile stories", memberCategoryProfile),
	"POST /profile/views":                       act("profile.view.record", "Viewed a profile", memberCategoryProfile),
	"POST /verification/{userID}/submit":        act("profile.verification.submit", "Submitted identity verification", memberCategoryProfile),
	"PUT /chapters/comfort":                     act("profile.chapters.comfort", "Updated chapter comfort settings", memberCategoryProfile),
	"POST /chapters/publications":               act("profile.chapters.publish", "Published a chapter", memberCategoryProfile),
	"DELETE /chapters/publications/{shareID}":   act("profile.chapters.unpublish", "Unpublished a chapter", memberCategoryProfile),
	"GET /profile/{userID}":                     act("profile.view", "Opened a profile", memberCategoryProfile),
	"GET /profile/{userID}/viewers":             act("profile.viewers.list", "Checked who viewed their profile", memberCategoryProfile),

	// ── Discovery ──────────────────────────────────────────────────────────
	"POST /swipe": act("discovery.swipe", "Swiped on a profile", memberCategoryDiscovery),
	"PATCH /discovery/{userID}/filters/trust":  act("discovery.filters.trust", "Changed discovery trust filters", memberCategoryDiscovery),
	"PUT /account/{userID}/dating-preferences": act("discovery.preferences.update", "Updated dating preferences", memberCategoryDiscovery),
	"POST /account/{userID}/discovery/pause":   act("discovery.pause", "Paused discovery", memberCategoryDiscovery),
	"POST /account/{userID}/discovery/resume":  act("discovery.resume", "Resumed discovery", memberCategoryDiscovery),
	"GET /discovery/{userID}":                  act("discovery.feed", "Opened the discovery feed", memberCategoryDiscovery),
	"GET /discovery/{userID}/today":            act("discovery.today", "Opened Today's picks", memberCategoryDiscovery),
	"GET /discovery/{userID}/liked-me":         act("discovery.liked_me", "Opened who liked them", memberCategoryDiscovery),

	// ── Matches & chat ─────────────────────────────────────────────────────
	"POST /chat/{matchID}/messages":                         act("message.send", "Sent a message", memberCategoryMatches),
	"DELETE /chat/{matchID}/messages/{messageID}":           act("message.delete", "Deleted a message", memberCategoryMatches),
	"POST /chat/{matchID}/gifts/send":                       act("chat.gift.send", "Sent a gift in chat", memberCategoryMatches),
	"POST /chat/{matchID}/gifts/events":                     act("chat.gift.event", "Recorded a chat gift event", memberCategoryMatches),
	"POST /chat/{matchID}/messages/{messageID}/gift/hide":   act("chat.gift.hide", "Hid a received gift", memberCategoryMatches),
	"POST /chat/{matchID}/messages/{messageID}/gift/report": act("chat.gift.report", "Reported a received gift", memberCategoryMatches),
	"POST /calls/start":                                     act("call.start", "Started a call", memberCategoryMatches),
	"POST /calls/{callID}/end":                              act("call.end", "Ended a call", memberCategoryMatches),
	"DELETE /matches/{matchID}":                             act("match.unmatch", "Unmatched", memberCategoryMatches),
	"POST /matches/{matchID}/read":                          act("match.read", "Marked a conversation read", memberCategoryMatches),
	"POST /matches/{matchID}/unlock-requirements":           act("match.unlock_requirements", "Set chat unlock requirements", memberCategoryMatches),
	"POST /matches/{matchID}/copilot/draft":                 act("match.copilot.draft", "Asked the copilot for a draft", memberCategoryMatches),
	"POST /matches/{matchID}/gestures":                      act("match.gesture.send", "Sent a gesture", memberCategoryMatches),
	"POST /matches/{matchID}/gestures/{gestureID}/decision": act("match.gesture.decide", "Decided on a gesture", memberCategoryMatches),
	"POST /matches/{matchID}/gestures/{gestureID}/respond":  act("match.gesture.respond", "Responded to a gesture", memberCategoryMatches),
	"POST /matches/{matchID}/chapter":                       act("match.chapter.update", "Updated the connection chapter", memberCategoryMatches),
	"PUT /matches/{matchID}/chapter/green-light":            act("match.chapter.green_light", "Gave a chapter green light", memberCategoryMatches),
	"POST /matches/{matchID}/moments":                       act("match.moment.create", "Started a chemistry moment", memberCategoryMatches),
	"POST /matches/{matchID}/moments/{momentID}/answer":     act("match.moment.answer", "Answered a chemistry moment", memberCategoryMatches),
	"POST /matches/{matchID}/activities/start":              act("match.activity.start", "Started a shared activity", memberCategoryMatches),
	"PUT /matches/{matchID}/quest-template":                 act("match.quest_template.set", "Set the match quest", memberCategoryMatches),
	"POST /matches/{matchID}/quest-workflow/submit":         act("match.quest.submit", "Submitted a match quest", memberCategoryMatches),
	"POST /matches/{matchID}/quest-workflow/review":         act("match.quest.review", "Reviewed a match quest", memberCategoryMatches),
	"POST /matches/{matchID}/quests/submit":                 act("match.quest.submit_legacy", "Submitted a match quest (legacy)", memberCategoryMatches),
	"POST /matches/{matchID}/quests/{submissionID}/review":  act("match.quest.review_legacy", "Reviewed a match quest (legacy)", memberCategoryMatches),
	"POST /engagement/matches/{matchID}/resume":             act("match.resume", "Resumed a quiet match", memberCategoryMatches),
	"GET /chat/{matchID}/messages":                          act("chat.open", "Opened a chat", memberCategoryMatches),
	"GET /matches/{userID}":                                 act("match.list", "Opened their matches", memberCategoryMatches),
	"GET /realtime/chat":                                    act("chat.realtime.connect", "Connected to live chat", memberCategoryMatches),

	// ── Dates ──────────────────────────────────────────────────────────────
	"POST /matches/{matchID}/plans":                              act("date_plan.propose", "Proposed a date", memberCategoryDates),
	"POST /matches/{matchID}/plans/{planID}/decision":            act("date_plan.decide", "Accepted or declined a date", memberCategoryDates),
	"POST /matches/{matchID}/plans/{planID}/counter":             act("date_plan.counter", "Suggested a different date plan", memberCategoryDates),
	"POST /matches/{matchID}/plans/{planID}/cancel":              act("date_plan.cancel", "Cancelled a date", memberCategoryDates),
	"POST /matches/{matchID}/plans/{planID}/checkin":             act("date_plan.checkin", "Checked in during a date", memberCategoryDates),
	"POST /matches/{matchID}/plans/{planID}/debrief":             act("date_plan.debrief", "Debriefed after a date", memberCategoryDates),
	"POST /matches/{matchID}/plans/{planID}/sharing":             act("date_plan.share", "Shared a date plan with friends", memberCategoryDates),
	"POST /matches/{matchID}/graduation":                         act("graduation.propose", "Proposed graduating the match", memberCategoryDates),
	"POST /matches/{matchID}/graduation/{graduationID}/decision": act("graduation.decide", "Decided on graduating the match", memberCategoryDates),
	"POST /matches/{matchID}/graduation/{graduationID}/withdraw": act("graduation.withdraw", "Withdrew a graduation proposal", memberCategoryDates),

	// ── Social ─────────────────────────────────────────────────────────────
	"POST /friends/{userID}":                                                 act("friend.request.send", "Sent a friend request", memberCategorySocial),
	"POST /friends/{userID}/{friendUserID}/decision":                         act("friend.request.decide", "Answered a friend request", memberCategorySocial),
	"DELETE /friends/{userID}/{friendUserID}":                                act("friend.remove", "Removed a friend", memberCategorySocial),
	"PUT /friends/{userID}/search-visibility":                                act("friend.search_visibility", "Changed friend search visibility", memberCategorySocial),
	"POST /friends/{userID}/intros":                                          act("friend.intro.create", "Introduced two friends", memberCategorySocial),
	"POST /friends/{userID}/intros/{introID}/decision":                       act("friend.intro.decide", "Answered an introduction", memberCategorySocial),
	"POST /friends/{userID}/vouches":                                         act("friend.vouch.create", "Vouched for a friend", memberCategorySocial),
	"DELETE /friends/{userID}/vouches/{vouchID}":                             act("friend.vouch.delete", "Withdrew a vouch", memberCategorySocial),
	"POST /friends/{userID}/vouches/{vouchID}/decision":                      act("friend.vouch.decide", "Accepted or declined a vouch", memberCategorySocial),
	"POST /social/friends/{friendID}/channel":                                act("social.channel.open_friend", "Opened a friend chat", memberCategorySocial),
	"POST /social/channels/{channelID}/messages":                             act("social.message.send", "Sent a social message", memberCategorySocial),
	"DELETE /social/channels/{channelID}/messages/{messageID}":               act("social.message.delete", "Deleted a social message", memberCategorySocial),
	"PUT /social/channels/{channelID}/mute":                                  act("social.channel.mute", "Muted a chat", memberCategorySocial),
	"DELETE /social/channels/{channelID}/mute":                               act("social.channel.unmute", "Unmuted a chat", memberCategorySocial),
	"POST /social/channels/{channelID}/read":                                 act("social.channel.read", "Marked a chat read", memberCategorySocial),
	"POST /rooms":                                                            act("room.create", "Created a room", memberCategorySocial),
	"POST /rooms/{roomID}/join":                                              act("room.join", "Joined a room", memberCategorySocial),
	"POST /rooms/{roomID}/leave":                                             act("room.leave", "Left a room", memberCategorySocial),
	"POST /rooms/{roomID}/moderate":                                          act("room.moderate", "Moderated a room", memberCategorySocial),
	"POST /rooms/{roomID}/presence":                                          act("room.presence", "Updated room presence", memberCategorySocial),
	"POST /engagement/groups":                                                act("group.create", "Created a group", memberCategorySocial),
	"PATCH /engagement/groups/{groupID}":                                     act("group.update", "Updated a group", memberCategorySocial),
	"DELETE /engagement/groups/{groupID}":                                    act("group.delete", "Deleted a group", memberCategorySocial),
	"PUT /engagement/groups/{groupID}/cover":                                 act("group.cover.set", "Set a group cover", memberCategorySocial),
	"DELETE /engagement/groups/{groupID}/cover":                              act("group.cover.delete", "Removed a group cover", memberCategorySocial),
	"POST /engagement/groups/{groupID}/invites":                              act("group.invite", "Invited someone to a group", memberCategorySocial),
	"POST /engagement/groups/{groupID}/invites/respond":                      act("group.invite.respond", "Answered a group invite", memberCategorySocial),
	"POST /engagement/groups/{groupID}/join":                                 act("group.join", "Joined a group", memberCategorySocial),
	"POST /engagement/groups/{groupID}/leave":                                act("group.leave", "Left a group", memberCategorySocial),
	"POST /engagement/groups/{groupID}/members/{userID}":                     act("group.member.manage", "Managed a group member", memberCategorySocial),
	"POST /engagement/group-coffee-polls":                                    act("group.coffee_poll.create", "Started a group coffee poll", memberCategorySocial),
	"POST /engagement/group-coffee-polls/{pollID}/votes":                     act("group.coffee_poll.vote", "Voted in a coffee poll", memberCategorySocial),
	"POST /engagement/group-coffee-polls/{pollID}/finalize":                  act("group.coffee_poll.finalize", "Finalised a coffee poll", memberCategorySocial),
	"POST /blog/responses":                                                   act("blog.response.create", "Wrote a blog response", memberCategorySocial),
	"POST /blog/responses/{responseID}":                                      act("blog.response.update", "Edited a blog response", memberCategorySocial),
	"DELETE /blog/responses/{responseID}":                                    act("blog.response.delete", "Deleted a blog response", memberCategorySocial),
	"POST /blog/publications":                                                act("blog.publication.create", "Published a blog share", memberCategorySocial),
	"POST /blog/publications/{shareID}":                                      act("blog.publication.update", "Updated a blog share", memberCategorySocial),
	"DELETE /blog/publications/{shareID}":                                    act("blog.publication.delete", "Unpublished a blog share", memberCategorySocial),
	"PUT /blog/posts/{postID}":                                               act("blog.post.save", "Saved a blog post", memberCategorySocial),
	"DELETE /blog/posts/{postID}":                                            act("blog.post.delete", "Deleted a blog post", memberCategorySocial),
	"PUT /blog/posts/{postID}/photos/{photoID}":                              act("blog.photo.save", "Added a blog photo", memberCategorySocial),
	"DELETE /blog/posts/{postID}/photos/{photoID}":                           act("blog.photo.delete", "Removed a blog photo", memberCategorySocial),
	"PUT /blog/posts/{postID}/like":                                          act("blog.post.like", "Liked a blog post", memberCategorySocial),
	"DELETE /blog/posts/{postID}/like":                                       act("blog.post.unlike", "Unliked a blog post", memberCategorySocial),
	"PUT /blog/posts/{postID}/comments/{commentID}":                          act("blog.comment.save", "Commented on a blog post", memberCategorySocial),
	"DELETE /blog/posts/{postID}/comments/{commentID}":                       act("blog.comment.delete", "Deleted a blog comment", memberCategorySocial),
	"POST /blog/posts/{postID}/comments/{commentID}/decision":                act("blog.comment.decide", "Approved or hid a blog comment", memberCategorySocial),
	"PUT /blog/authors/{authorID}/subscription":                              act("blog.author.follow", "Followed a writer", memberCategorySocial),
	"DELETE /blog/authors/{authorID}/subscription":                           act("blog.author.unfollow", "Unfollowed a writer", memberCategorySocial),
	"PUT /themes/{themeID}/entries/{entryID}":                                act("theme.entry.save", "Posted a photo theme entry", memberCategorySocial),
	"DELETE /themes/{themeID}/entries/{entryID}":                             act("theme.entry.delete", "Deleted a photo theme entry", memberCategorySocial),
	"PUT /themes/{themeID}/entries/{entryID}/like":                           act("theme.entry.like", "Liked a photo theme entry", memberCategorySocial),
	"DELETE /themes/{themeID}/entries/{entryID}/like":                        act("theme.entry.unlike", "Unliked a photo theme entry", memberCategorySocial),
	"PUT /themes/{themeID}/entries/{entryID}/comments/{commentID}":           act("theme.comment.save", "Commented on a photo theme entry", memberCategorySocial),
	"DELETE /themes/{themeID}/entries/{entryID}/comments/{commentID}":        act("theme.comment.delete", "Deleted a photo theme comment", memberCategorySocial),
	"POST /themes/{themeID}/entries/{entryID}/comments/{commentID}/decision": act("theme.comment.decide", "Approved or hid a photo theme comment", memberCategorySocial),
	"POST /themes/{themeID}/entries/{entryID}/featuring":                     act("theme.entry.feature", "Changed featuring of a photo theme entry", memberCategorySocial),
	"PUT /clubs/{clubID}":                                                    act("club.save", "Created or updated a club", memberCategorySocial),
	"POST /clubs/{clubID}/membership":                                        act("club.membership", "Joined or left a club", memberCategorySocial),
	"POST /clubs/{clubID}/members/{userID}":                                  act("club.member.manage", "Managed a club member", memberCategorySocial),
	"PUT /clubs/{clubID}/posts/{postID}":                                     act("club.post.save", "Posted in a club", memberCategorySocial),
	"DELETE /clubs/{clubID}/posts/{postID}":                                  act("club.post.delete", "Deleted a club post", memberCategorySocial),
	"POST /clubs/{clubID}/posts/{postID}/visibility":                         act("club.post.visibility", "Changed a club post's visibility", memberCategorySocial),
	"PUT /clubs/{clubID}/selections/{weekStart}":                             act("club.selection.set", "Set the club's weekly pick", memberCategorySocial),
	"PUT /clubs/titles/{titleID}":                                            act("club.title.save", "Added or updated a title", memberCategorySocial),
	"PUT /clubs/titles/{titleID}/reviews/{reviewID}":                         act("club.review.save", "Reviewed a title", memberCategorySocial),
	"DELETE /clubs/reviews/{reviewID}":                                       act("club.review.delete", "Deleted a title review", memberCategorySocial),
	"PUT /clubs/lists/{listID}":                                              act("club.list.save", "Saved a list", memberCategorySocial),
	"DELETE /clubs/lists/{listID}":                                           act("club.list.delete", "Deleted a list", memberCategorySocial),
	"PUT /clubs/lists/{listID}/items/{titleID}":                              act("club.list.item.add", "Added a title to a list", memberCategorySocial),
	"DELETE /clubs/lists/{listID}/items/{titleID}":                           act("club.list.item.remove", "Removed a title from a list", memberCategorySocial),
	"POST /introducer/invites":                                               act("introducer.invite.create", "Created an introducer invite", memberCategorySocial),
	"DELETE /introducer/invites":                                             act("introducer.invite.revoke", "Revoked an introducer invite", memberCategorySocial),
	"POST /introducer/redeem":                                                act("introducer.invite.redeem", "Redeemed an introducer invite", memberCategorySocial),
	"POST /introducer/connections/{consentID}/approve":                       act("introducer.connection.approve", "Approved an introducer connection", memberCategorySocial),
	"DELETE /introducer/connections/{consentID}":                             act("introducer.connection.remove", "Removed an introducer connection", memberCategorySocial),
	"POST /city-pilot/membership":                                            act("city_pilot.join", "Joined the city pilot", memberCategorySocial),
	"DELETE /city-pilot/membership":                                          act("city_pilot.leave", "Left the city pilot", memberCategorySocial),
	"POST /city-pilot/events/{eventID}/registration":                         act("city_pilot.event.register", "Registered for a city pilot event", memberCategorySocial),
	"DELETE /city-pilot/events/{eventID}/registration":                       act("city_pilot.event.unregister", "Cancelled a city pilot registration", memberCategorySocial),
	"POST /city-pilot/events/{eventID}/feedback":                             act("city_pilot.event.feedback", "Gave city pilot event feedback", memberCategorySocial),
	"POST /growth/events/{eventID}/registration":                             act("growth.event.register", "Registered for an event", memberCategorySocial),
	"DELETE /growth/events/{eventID}/registration":                           act("growth.event.unregister", "Cancelled an event registration", memberCategorySocial),
	"POST /growth/referrals/me":                                              act("growth.referral.create", "Created a referral code", memberCategorySocial),
	"POST /growth/referrals/redeem":                                          act("growth.referral.redeem", "Redeemed a referral code", memberCategorySocial),
	"GET /social/channels/{channelID}/messages":                              act("social.channel.view", "Opened a social chat", memberCategorySocial),
	"GET /friends/{userID}":                                                  act("friend.list", "Opened their friends", memberCategorySocial),
	"GET /rooms/{roomID}":                                                    act("room.view", "Opened a room", memberCategorySocial),
	"GET /blog/posts/{postID}":                                               act("blog.post.view", "Read a blog post", memberCategorySocial),

	// ── Safety ─────────────────────────────────────────────────────────────
	"POST /safety/report":                             act("safety.report", "Reported a member", memberCategorySafety),
	"POST /safety/block":                              act("safety.block", "Blocked a member", memberCategorySafety),
	"POST /safety/unblock":                            act("safety.unblock", "Unblocked a member", memberCategorySafety),
	"POST /safety/sos":                                act("safety.sos.raise", "Raised an SOS alert", memberCategorySafety),
	"POST /safety/sos/{alertID}/resolve":              act("safety.sos.resolve", "Resolved an SOS alert", memberCategorySafety),
	"POST /emergency-contacts/{userID}":               act("safety.emergency_contact.add", "Added an emergency contact", memberCategorySafety),
	"PUT /emergency-contacts/{userID}/{contactID}":    act("safety.emergency_contact.update", "Updated an emergency contact", memberCategorySafety),
	"DELETE /emergency-contacts/{userID}/{contactID}": act("safety.emergency_contact.delete", "Removed an emergency contact", memberCategorySafety),
	"POST /moderation/appeals":                        act("safety.appeal.create", "Appealed a moderation decision", memberCategorySafety),
	"POST /blog/posts/{postID}/report":                act("safety.report.blog_post", "Reported a blog post", memberCategorySafety),
	"POST /blog/public/{shareID}/report":              act("safety.report.blog_public", "Reported a public blog share", memberCategorySafety),
	"POST /blog/reports/{kind}/{contentID}":           act("safety.report.blog_content", "Reported blog content", memberCategorySafety),
	"POST /blog/notices/{caseID}/appeal":              act("safety.appeal.blog", "Appealed a blog moderation notice", memberCategorySafety),
	"GET /safety/sos/{userID}":                        act("safety.sos.view", "Opened their SOS alerts", memberCategorySafety),

	// ── Billing & coins ────────────────────────────────────────────────────
	"POST /billing/checkout":                                act("billing.checkout.start", "Started a checkout", memberCategoryBilling),
	"POST /billing/subscribe":                               act("billing.subscribe", "Subscribed", memberCategoryBilling),
	"POST /billing/subscription/{userID}/cancel":            act("billing.subscription.cancel", "Cancelled their subscription", memberCategoryBilling),
	"POST /billing/subscription/{userID}/resume":            act("billing.subscription.resume", "Resumed their subscription", memberCategoryBilling),
	"POST /billing/subscription/{userID}/change-plan":       act("billing.subscription.change_plan", "Changed subscription plan", memberCategoryBilling),
	"POST /billing/sandbox/checkout/{sessionID}":            act("billing.sandbox.checkout", "Completed a sandbox checkout", memberCategoryBilling),
	"POST /billing/sandbox/subscriptions/{userID}/simulate": act("billing.sandbox.simulate", "Simulated a sandbox subscription event", memberCategoryBilling),
	"POST /billing/webhooks/{provider}":                     act("billing.webhook.receive", "Payment provider webhook", memberCategoryBilling),
	"POST /wallet/{userID}/coins/buy":                       act("wallet.coins.buy", "Bought coins", memberCategoryBilling),
	"POST /wallet/{userID}/coins/top-up":                    act("wallet.coins.top_up", "Topped up coins", memberCategoryBilling),
	"POST /growth/admirer-gifts":                            act("growth.admirer_gift", "Tried to send an admirer gift", memberCategoryBilling),
	"POST /growth/paid-xp":                                  act("growth.paid_xp", "Tried to buy XP", memberCategoryBilling),
	"GET /wallet/{userID}/coins":                            act("wallet.view", "Opened their wallet", memberCategoryBilling),

	// ── Engagement ─────────────────────────────────────────────────────────
	"POST /engagement/daily-prompt/{userID}/answer":          act("engagement.daily_prompt.answer", "Answered the daily prompt", memberCategoryEngagement),
	"POST /engagement/circles/{circleID}/join":               act("engagement.circle.join", "Joined a circle", memberCategoryEngagement),
	"POST /engagement/circles/{circleID}/challenge/entries":  act("engagement.circle.challenge_entry", "Entered a circle challenge", memberCategoryEngagement),
	"POST /engagement/match-nudges/send":                     act("engagement.nudge.send", "Sent a match nudge", memberCategoryEngagement),
	"POST /engagement/match-nudges/{nudgeID}/click":          act("engagement.nudge.click", "Opened a match nudge", memberCategoryEngagement),
	"POST /engagement/voice-icebreakers/start":               act("engagement.voice_icebreaker.start", "Recorded a voice icebreaker", memberCategoryEngagement),
	"POST /engagement/voice-icebreakers/{icebreakerID}/send": act("engagement.voice_icebreaker.send", "Sent a voice icebreaker", memberCategoryEngagement),
	"POST /engagement/voice-icebreakers/{icebreakerID}/play": act("engagement.voice_icebreaker.play", "Played a voice icebreaker", memberCategoryEngagement),
	"POST /activities/sessions/start":                        act("engagement.activity_session.start", "Started an activity session", memberCategoryEngagement),
	"POST /activities/sessions/{sessionID}/submit":           act("engagement.activity_session.submit", "Submitted activity answers", memberCategoryEngagement),
	"POST /activities/{sessionID}/responses":                 act("engagement.activity_session.respond", "Answered an activity", memberCategoryEngagement),
	"POST /progression/{userID}/rewards/claim":               act("engagement.reward.claim", "Claimed a reward", memberCategoryEngagement),
	"POST /walls/views":                                      act("engagement.wall.view", "Viewed wall content", memberCategoryEngagement),
	"POST /walls/celebrations/{celebrationID}/seen":          act("engagement.celebration.seen", "Saw a celebration", memberCategoryEngagement),

	// ── Support ────────────────────────────────────────────────────────────
	"POST /support/tickets":                     act("support.ticket.create", "Opened a support ticket", memberCategorySupport),
	"POST /support/tickets/{ticketID}/messages": act("support.ticket.reply", "Replied on a support ticket", memberCategorySupport),
	"POST /support/tickets/{ticketID}/close":    act("support.ticket.close", "Closed a support ticket", memberCategorySupport),
	"POST /support/tickets/{ticketID}/reopen":   act("support.ticket.reopen", "Reopened a support ticket", memberCategorySupport),
	"POST /support/tickets/{ticketID}/rating":   act("support.ticket.rate", "Rated a support ticket", memberCategorySupport),
	"POST /support/attachments":                 act("support.attachment.upload", "Uploaded a support attachment", memberCategorySupport),
	"POST /support/contact":                     act("support.contact", "Sent the website contact form", memberCategorySupport),
	"GET /support/tickets/{ticketID}":           act("support.ticket.view", "Opened a support ticket", memberCategorySupport),

	// ── Settings ───────────────────────────────────────────────────────────
	"PATCH /settings/{userID}":                           act("settings.update", "Changed settings", memberCategorySettings),
	"PATCH /notifications/{userID}/preferences":          act("settings.notifications.update", "Changed notification preferences", memberCategorySettings),
	"POST /notifications/{userID}/devices":               act("settings.push_device.register", "Registered a push device", memberCategorySettings),
	"DELETE /notifications/{userID}/devices/{deviceID}":  act("settings.push_device.remove", "Removed a push device", memberCategorySettings),
	"POST /notifications/{userID}/read-all":              act("notification.read_all", "Marked all notifications read", memberCategorySettings),
	"POST /notifications/{userID}/{notificationID}/read": act("notification.read", "Read a notification", memberCategorySettings),
	"DELETE /notifications/{userID}/{notificationID}":    act("notification.delete", "Deleted a notification", memberCategorySettings),
	"POST /account/{userID}/deactivate":                  act("account.deactivate", "Deactivated their account", memberCategorySettings),
	"POST /account/{userID}/reactivate":                  act("account.reactivate", "Reactivated their account", memberCategorySettings),
	"POST /account/{userID}/deletion":                    act("account.deletion.request", "Requested account deletion", memberCategorySettings),
	"DELETE /account/{userID}/deletion":                  act("account.deletion.cancel", "Cancelled account deletion", memberCategorySettings),
	"POST /account/{userID}/export":                      act("account.export.request", "Requested a data export", memberCategorySettings),
	"PUT /growth/imports/consents":                       act("settings.import_consent.grant", "Allowed a social import", memberCategorySettings),
	"DELETE /growth/imports/consents/{provider}":         act("settings.import_consent.revoke", "Revoked a social import", memberCategorySettings),
	"POST /growth/history/preferences":                   act("settings.history.preferences", "Saved preference history", memberCategorySettings),
	"POST /growth/history/location-checkins":             act("settings.history.location_checkin", "Checked in a location", memberCategorySettings),
	"DELETE /growth/history":                             act("settings.history.delete", "Deleted their growth history", memberCategorySettings),
	"GET /notifications/{userID}":                        act("notification.list", "Opened notifications", memberCategorySettings),
	"GET /account/{userID}/export":                       act("account.export.download", "Downloaded their data export", memberCategorySettings),
	"GET /realtime/notifications":                        act("notification.realtime.connect", "Connected to live notifications", memberCategorySettings),

	// ── Other ──────────────────────────────────────────────────────────────
	"POST /client/errors": act("client.error_report", "Sent an app error report", memberCategoryOther),
}

// lookupMemberAction finds the catalog entry for a method and full route
// template ("/v1/swipe").
func lookupMemberAction(prefix, method, route string) (memberActionDef, bool) {
	relative := strings.TrimPrefix(route, prefix)
	if relative == route && prefix != "" {
		return memberActionDef{}, false
	}
	def, ok := memberActionCatalog[strings.ToUpper(method)+" "+relative]
	return def, ok
}

func isMutatingMethod(method string) bool {
	switch strings.ToUpper(method) {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	}
	return false
}

// isMemberRoute reports whether a route template is a member route under the
// API prefix (admin routes excluded).
func isMemberRoute(prefix, route string) bool {
	if !strings.HasPrefix(route, prefix+"/") {
		return false
	}
	return route != prefix+"/admin" && !strings.HasPrefix(route, prefix+"/admin/")
}

// memberActionCoverage is the catalog's coverage of the live router,
// computed once at startup.
type memberActionCoverage struct {
	MutatingRoutes int      `json:"mutating_routes"`
	Catalogued     int      `json:"catalogued"`
	Uncatalogued   []string `json:"uncatalogued"`
	CataloguedRead int      `json:"catalogued_reads"`
	// Stale lists catalog entries whose route no longer exists.
	Stale []string `json:"stale"`
}

func computeMemberActionCoverage(router chi.Routes, prefix string) memberActionCoverage {
	coverage := memberActionCoverage{Uncatalogued: []string{}, Stale: []string{}}
	if router == nil {
		return coverage
	}
	seen := map[string]bool{}
	_ = chi.Walk(router, func(method, route string, _ http.Handler, _ ...func(http.Handler) http.Handler) error {
		if !isMemberRoute(prefix, route) {
			return nil
		}
		key := strings.ToUpper(method) + " " + strings.TrimPrefix(route, prefix)
		if seen[key] {
			return nil
		}
		seen[key] = true
		_, catalogued := memberActionCatalog[key]
		if isMutatingMethod(method) {
			coverage.MutatingRoutes++
			if catalogued {
				coverage.Catalogued++
			} else {
				coverage.Uncatalogued = append(coverage.Uncatalogued, strings.ToUpper(method)+" "+route)
			}
		} else if catalogued {
			coverage.CataloguedRead++
		}
		return nil
	})
	for key := range memberActionCatalog {
		if !seen[key] {
			coverage.Stale = append(coverage.Stale, key)
		}
	}
	sort.Strings(coverage.Uncatalogued)
	sort.Strings(coverage.Stale)
	return coverage
}

// memberActionCatalogEntries lists the catalog for the admin API, ordered by
// category then key.
func memberActionCatalogEntries(prefix string) []map[string]any {
	order := map[string]int{}
	for i, category := range memberActionCategories {
		order[category] = i
	}
	type entry struct {
		route string
		def   memberActionDef
	}
	entries := make([]entry, 0, len(memberActionCatalog))
	for route, def := range memberActionCatalog {
		entries = append(entries, entry{route: route, def: def})
	}
	sort.Slice(entries, func(i, j int) bool {
		a, b := entries[i], entries[j]
		if order[a.def.Category] != order[b.def.Category] {
			return order[a.def.Category] < order[b.def.Category]
		}
		if a.def.Key != b.def.Key {
			return a.def.Key < b.def.Key
		}
		return a.route < b.route
	})
	out := make([]map[string]any, 0, len(entries))
	for _, item := range entries {
		method, path, _ := strings.Cut(item.route, " ")
		out = append(out, map[string]any{
			"key": item.def.Key, "label": item.def.Label, "category": item.def.Category,
			"method": method, "route": prefix + path, "mutating": isMutatingMethod(method),
		})
	}
	return out
}

// memberEventCategoryRules classify explicit events, security events and
// domain events (which carry a name, not a route) into the same categories.
// The first matching pattern wins; patterns are POSIX regular expressions
// matched case-insensitively against the event name and, for domain events,
// the aggregate type. They are constants and are rendered into SQL verbatim.
var memberEventCategoryRules = []struct {
	Pattern  string
	Category string
}{
	{`^(auth|session)[._]|auth_sessions|auth_credentials|auth_recovery|account_recovery|signup|terms`, memberCategoryAuth},
	{`(safety|sos|block|report|moderation|fraud|emergency|appeal|felt_unsafe|need_help)`, memberCategorySafety},
	{`(billing|wallet|coin|payment|subscription|checkout|purchase)`, memberCategoryBilling},
	{`(date_plan|graduation|debrief|checkin)`, memberCategoryDates},
	{`(message|chat|match|call|gesture|copilot|chemistry|quest|gift)`, memberCategoryMatches},
	{`(swipe|discovery|spotlight|dating_pref|liked)`, memberCategoryDiscovery},
	{`(friend|intro|vouch|group|room|social|blog|club|theme|city_pilot|growth|referral|wall)`, memberCategorySocial},
	{`(profile|photo|media|verification|stor(y|ies)|chapter|showcase|users)`, memberCategoryProfile},
	{`(support|ticket)`, memberCategorySupport},
	{`(engagement|prompt|xp|progression|level|reward|celebration|nudge|icebreaker|circle|activity_session)`, memberCategoryEngagement},
	{`(setting|notification|preference|account|device|export|lifecycle|deactivat|deletion)`, memberCategorySettings},
}

// memberEventCategorySQL renders the category rules as a CASE over expr. A
// leading schema name ("matching.", "user_management." …, as domain events
// carry) is ignored so "matching.friend_connections.created" is Social, not
// Matches & chat.
func memberEventCategorySQL(expr string) string {
	expr = `regexp_replace(` + expr + `, '^(matching|user_management|progression|audit|platform|growth|blog|themes|social|support)\.', '')`
	var builder strings.Builder
	builder.WriteString("CASE")
	for _, rule := range memberEventCategoryRules {
		builder.WriteString(" WHEN " + expr + " ~* '" + strings.ReplaceAll(rule.Pattern, "'", "''") + "' THEN '" +
			strings.ReplaceAll(rule.Category, "'", "''") + "'")
	}
	builder.WriteString(" ELSE '" + memberCategoryOther + "' END")
	return builder.String()
}

// memberEventLabels names the explicit events whose humanised name reads
// poorly. Anything else gets "Account deletion requested" style labels from
// humaniseEventName.
var memberEventLabels = map[string]string{
	"wallet.coins.purchase":      "Bought coins",
	"account.deletion_requested": "Requested account deletion",
	"account.deactivate":         "Deactivated their account",
	"account.export_created":     "Requested a data export",
	"safety.user.blocked":        "Blocked a member",
	"safety.user.unblocked":      "Unblocked a member",
	"date_plan.proposed":         "Proposed a date",
	"date_plan.accepted":         "Accepted a date",
	"date_plan.cancelled":        "Cancelled a date",
	"chat.locked":                "Chat was locked",
}

// humaniseEventName turns "account.deletion_requested" into
// "Account deletion requested".
func humaniseEventName(name string) string {
	name = strings.TrimSpace(name)
	if label, ok := memberEventLabels[name]; ok {
		return label
	}
	text := strings.Join(strings.Fields(strings.NewReplacer(".", " ", "_", " ", "-", " ", ":", " ").Replace(name)), " ")
	if text == "" {
		return ""
	}
	return strings.ToUpper(text[:1]) + text[1:]
}
