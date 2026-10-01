-- Chat mutes: room moderation mutes and per-conversation notification mutes.
--
--  * Room mute (moderation). A room's hosts and moderators, or an operator,
--    can mute a member for a while: the member keeps reading the room's chat
--    but cannot post until conversation_room_participants.muted_until passes.
--    The shared chat engine (migration 115) exposes this as read-only
--    membership. Mutes and unmutes are logged in
--    conversation_room_moderation_actions (actions 'mute' and 'unmute').
--  * Notification mute (member preference). Any member can silence
--    notifications for one conversation (a friend chat or group chat) for a
--    while or until they turn them back on: social_channel_prefs.muted_until,
--    'infinity' meaning until turned back on. Real-time events still flow.
--  * social.channel.updated: a real-time event telling a member their own
--    standing in a conversation changed (muted or unmuted), so an open chat
--    refreshes its composer at once.
--
-- Idempotent: safe to run more than once.
BEGIN;

-- ---------------------------------------------------------------------------
-- Room mutes
-- ---------------------------------------------------------------------------
ALTER TABLE matching.conversation_room_participants ADD COLUMN IF NOT EXISTS muted_until TIMESTAMPTZ;
ALTER TABLE matching.conversation_room_participants ADD COLUMN IF NOT EXISTS muted_by_user_id UUID REFERENCES user_management.users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS conversation_room_participants_muted
  ON matching.conversation_room_participants(room_id, muted_until) WHERE muted_until IS NOT NULL;

ALTER TABLE matching.conversation_room_moderation_actions DROP CONSTRAINT IF EXISTS conversation_room_moderation_actions_action_check;
ALTER TABLE matching.conversation_room_moderation_actions ADD CONSTRAINT conversation_room_moderation_actions_action_check
  CHECK (action IN ('warn','mute','unmute','remove','close','set_role')) NOT VALID;

-- ---------------------------------------------------------------------------
-- Per-conversation notification preferences
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS matching.social_channel_prefs (
  channel_id UUID NOT NULL REFERENCES matching.social_channels(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
  -- Notifications for this conversation are silenced until then; 'infinity'
  -- means until the member turns them back on; NULL means not muted.
  muted_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (channel_id, user_id)
);
CREATE INDEX IF NOT EXISTS social_channel_prefs_user ON matching.social_channel_prefs(user_id);

-- ---------------------------------------------------------------------------
-- Real-time event: a member's standing in a conversation changed.
-- ---------------------------------------------------------------------------
ALTER TABLE matching.realtime_outbox DROP CONSTRAINT IF EXISTS realtime_outbox_event_type_check;
ALTER TABLE matching.realtime_outbox ADD CONSTRAINT realtime_outbox_event_type_check CHECK (
  event_type IN (
    'match.created','match.unmatched',
    'message.created','message.delivered','message.read','message.deleted',
    'social.message.created','social.message.deleted','social.channel.updated'
  )
);

DO $$ BEGIN
  PERFORM platform.register_event_source('matching','social_channel_prefs','social.social_channel_prefs');
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('social.social_channel_prefs','mobile-bff.social','matching','social_channel_prefs','one row per member and conversation','set and clear are idempotent upserts')
  ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('social.social_channel_prefs') ON CONFLICT DO NOTHING;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('119_chat_mutes') ON CONFLICT DO NOTHING;
COMMIT;
