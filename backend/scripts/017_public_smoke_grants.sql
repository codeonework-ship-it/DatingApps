-- Story 1.2 smoke policy bootstrap for public schema tables.

ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.preferences DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_unlock_states DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_quest_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_quest_workflows DISABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.users,
  public.preferences,
  public.photos,
  public.swipes,
  public.matches,
  public.messages,
  public.match_unlock_states,
  public.match_quest_templates,
  public.match_quest_workflows
TO anon, authenticated;
