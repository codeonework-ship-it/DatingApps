-- Story 1.2 smoke compatibility schema for Supabase REST when only public schema is exposed.

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY,
  phoneNumber TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  dateOfBirth DATE NOT NULL,
  gender TEXT NOT NULL,
  bio TEXT,
  education TEXT,
  profession TEXT,
  isVerified BOOLEAN DEFAULT FALSE,
  isActive BOOLEAN DEFAULT TRUE,
  lastLogin TIMESTAMPTZ DEFAULT NOW(),
  createdAt TIMESTAMPTZ DEFAULT NOW(),
  updatedAt TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  seekingGenders TEXT[] DEFAULT ARRAY['M','F'],
  minAgeYears INTEGER DEFAULT 18,
  maxAgeYears INTEGER DEFAULT 60,
  maxDistanceKm INTEGER DEFAULT 50,
  educationFilter TEXT[] DEFAULT ARRAY[]::TEXT[],
  seriousOnly BOOLEAN DEFAULT TRUE,
  verifiedOnly BOOLEAN DEFAULT FALSE,
  updatedAt TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  photoUrl TEXT NOT NULL,
  storagePath TEXT NOT NULL DEFAULT '',
  ordering INTEGER NOT NULL DEFAULT 0,
  uploadedAt TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(userId, ordering)
);

CREATE TABLE IF NOT EXISTS public.swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  targetUserId UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  isLike BOOLEAN NOT NULL,
  createdAt TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(userId, targetUserId)
);

CREATE TABLE IF NOT EXISTS public.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  userId1 UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  userId2 UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  createdAt TIMESTAMPTZ DEFAULT NOW(),
  user1Status TEXT DEFAULT 'active',
  user2Status TEXT DEFAULT 'active',
  lastMessageAt TIMESTAMPTZ,
  UNIQUE(userId1, userId2)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  matchId UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  senderId UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  createdAt TIMESTAMPTZ DEFAULT NOW(),
  deliveredAt TIMESTAMPTZ,
  readAt TIMESTAMPTZ,
  isDeleted BOOLEAN DEFAULT FALSE,
  deletedAt TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_public_swipes_user ON public.swipes(userId, targetUserId);
CREATE INDEX IF NOT EXISTS idx_public_matches_user1 ON public.matches(userId1);
CREATE INDEX IF NOT EXISTS idx_public_matches_user2 ON public.matches(userId2);
CREATE INDEX IF NOT EXISTS idx_public_messages_match_created ON public.messages(matchId, createdAt DESC);

CREATE TABLE IF NOT EXISTS public.match_unlock_states (
  match_id UUID PRIMARY KEY REFERENCES public.matches(id) ON DELETE CASCADE,
  unlock_state TEXT NOT NULL DEFAULT 'matched',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.match_quest_templates (
  match_id UUID PRIMARY KEY REFERENCES public.matches(id) ON DELETE CASCADE,
  template_id TEXT NOT NULL,
  creator_user_id UUID NOT NULL,
  prompt_template TEXT NOT NULL,
  min_chars INTEGER NOT NULL,
  max_chars INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.match_quest_workflows (
  match_id UUID PRIMARY KEY REFERENCES public.matches(id) ON DELETE CASCADE,
  template_id TEXT,
  unlock_state TEXT NOT NULL DEFAULT 'matched',
  status TEXT NOT NULL DEFAULT 'pending',
  submitter_user_id UUID,
  reviewer_user_id UUID,
  response_text TEXT,
  review_reason TEXT,
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  window_started_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
