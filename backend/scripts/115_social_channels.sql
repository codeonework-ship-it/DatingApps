-- Shared chat engine for friend conversations, Conversation Rooms and groups.
--
-- One channel per friend pair, per room and per group. Who may read and post
-- is decided live from the owning feature's tables (accepted friendship, active
-- room participant, active group member), so leaving a room or group, ending a
-- friendship or blocking someone takes effect at once. New messages fan out to
-- members through matching.realtime_outbox, the same websocket match chat uses.
BEGIN;

CREATE TABLE IF NOT EXISTS matching.social_channels (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 kind TEXT NOT NULL CHECK (kind IN ('friend','room','group')),
 -- The room or group this channel belongs to (room and group channels).
 ref_id UUID,
 -- The two friends, lower id first (friend channels).
 user_low UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
 user_high UUID REFERENCES user_management.users(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 last_message_at TIMESTAMPTZ,
 CONSTRAINT social_channels_shape CHECK (
  (kind='friend' AND ref_id IS NULL AND user_low IS NOT NULL AND user_high IS NOT NULL AND user_low<user_high)
  OR (kind<>'friend' AND ref_id IS NOT NULL AND user_low IS NULL AND user_high IS NULL)
 )
);
CREATE UNIQUE INDEX IF NOT EXISTS social_channels_ref ON matching.social_channels(kind,ref_id) WHERE ref_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS social_channels_pair ON matching.social_channels(user_low,user_high) WHERE kind='friend';

CREATE TABLE IF NOT EXISTS matching.social_messages (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 channel_id UUID NOT NULL REFERENCES matching.social_channels(id) ON DELETE CASCADE,
 sender_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 body TEXT NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 2000),
 -- Client-generated id so a retried send never posts twice.
 client_message_id UUID NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 -- Deleted by the sender, or removed by a room host, group owner or moderator.
 deleted_at TIMESTAMPTZ,
 deleted_by UUID REFERENCES user_management.users(id) ON DELETE SET NULL,
 moderation_state TEXT NOT NULL DEFAULT 'active' CHECK (moderation_state IN ('active','removed')),
 -- Bumped by moderation decisions (shared case queue).
 version INTEGER NOT NULL DEFAULT 1,
 UNIQUE (sender_id,client_message_id)
);
ALTER TABLE matching.social_messages ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;
CREATE INDEX IF NOT EXISTS social_messages_channel ON matching.social_messages(channel_id,created_at DESC,id);
CREATE INDEX IF NOT EXISTS social_messages_sender_recent ON matching.social_messages(sender_id,created_at DESC);

CREATE TABLE IF NOT EXISTS matching.social_channel_reads (
 channel_id UUID NOT NULL REFERENCES matching.social_channels(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES user_management.users(id) ON DELETE CASCADE,
 last_read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 PRIMARY KEY (channel_id,user_id)
);

-- Real-time fan-out through the existing chat websocket.
ALTER TABLE matching.realtime_outbox ADD COLUMN IF NOT EXISTS channel_id UUID REFERENCES matching.social_channels(id) ON DELETE CASCADE;
ALTER TABLE matching.realtime_outbox DROP CONSTRAINT IF EXISTS realtime_outbox_event_type_check;
ALTER TABLE matching.realtime_outbox ADD CONSTRAINT realtime_outbox_event_type_check CHECK (
 event_type IN (
  'match.created','match.unmatched',
  'message.created','message.delivered','message.read','message.deleted',
  'social.message.created','social.message.deleted'
 )
);

-- Reports of chat messages flow through the existing moderation case queue.
ALTER TABLE matching.blog_cases DROP CONSTRAINT IF EXISTS blog_cases_content_type_check;
ALTER TABLE matching.blog_cases ADD CONSTRAINT blog_cases_content_type_check
 CHECK(content_type IN ('post','response','publication','theme_entry','club','club_post','review','list','comment','photo_comment','social_message'));

INSERT INTO matching.platform_feature_flags(key,value_bool,description,updated_by) VALUES
 ('social_chat_enabled',TRUE,'Friend conversations, Conversation Room chat and group chat','migration_115')
ON CONFLICT (key) DO NOTHING;

DO $$ DECLARE item TEXT; BEGIN
 FOREACH item IN ARRAY ARRAY['social_channels','social_messages','social_channel_reads'] LOOP
  PERFORM platform.register_event_source('matching',item,'social.'||item);
  INSERT INTO platform.aggregate_ownership(aggregate_type,owner_component,source_schema,source_table,transaction_boundary,recovery_strategy)
  VALUES('social.'||item,'mobile-bff.social','matching',item,'sender lock then message; atomic with realtime fan-out','client message id makes sends idempotent; membership checked live') ON CONFLICT DO NOTHING;
  INSERT INTO platform.required_aggregates(aggregate_type) VALUES('social.'||item) ON CONFLICT DO NOTHING;
 END LOOP;
END $$;

INSERT INTO public.schema_migrations(version) VALUES('115_social_channels') ON CONFLICT DO NOTHING;
COMMIT;
