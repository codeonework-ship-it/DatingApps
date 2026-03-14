-- Community groups persistence tables for user-created city/fanclub groups and invite flows.
-- Safe to run repeatedly on Supabase/Postgres.

CREATE TABLE IF NOT EXISTS matching.community_groups (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  topic TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN ('private', 'public')),
  created_by_user_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_groups_city_topic
  ON matching.community_groups(city, topic, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_groups_creator
  ON matching.community_groups(created_by_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS matching.community_group_members (
  group_id UUID NOT NULL REFERENCES matching.community_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'moderator', 'member')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'left', 'removed')),
  invited_by_user_id UUID,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  PRIMARY KEY (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_group_members_user
  ON matching.community_group_members(user_id, status, joined_at DESC);

CREATE TABLE IF NOT EXISTS matching.community_group_invites (
  id UUID PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES matching.community_groups(id) ON DELETE CASCADE,
  inviter_user_id UUID NOT NULL,
  invitee_user_id UUID NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE (group_id, invitee_user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_group_invites_invitee
  ON matching.community_group_invites(invitee_user_id, status, invited_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_group_invites_group
  ON matching.community_group_invites(group_id, status, invited_at DESC);
