-- ============================================================
-- Ava for Moms — Initial Schema
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- pgvector for Ava memory semantic search
create extension if not exists vector;

-- ============================================================
-- TABLES
-- ============================================================

-- Profiles — one row per auth user, created automatically on signup
create table public.profiles (
  id                    uuid references auth.users on delete cascade primary key,
  name                  text not null default '',
  work_status           text not null default 'full_time',
  has_school_pickup     boolean not null default false,
  school_pickup_time    time,
  mental_load_areas     text[] not null default '{}',
  onboarding_completed  boolean not null default false,
  avatar_url            text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- Family members — partner + kids
create table public.family_members (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references public.profiles on delete cascade not null,
  name         text not null,
  relationship text not null check (relationship in ('partner', 'child', 'other')),
  age          integer,
  color_hex    text not null default '#A5C09A',
  created_at   timestamptz not null default now()
);

-- Tasks
create table public.tasks (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references public.profiles on delete cascade not null,
  title            text not null,
  note             text,
  due_date         timestamptz,
  priority         text not null default 'normal' check (priority in ('urgent', 'normal', 'low')),
  completed        boolean not null default false,
  completed_at     timestamptz,
  family_member_id uuid references public.family_members on delete set null,
  source           text not null default 'user' check (source in ('user', 'ava')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Calendar events
create table public.calendar_events (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references public.profiles on delete cascade not null,
  title            text not null,
  detail           text,
  starts_at        timestamptz not null,
  ends_at          timestamptz,
  all_day          boolean not null default false,
  color_hex        text not null default '#D46A47',
  family_member_id uuid references public.family_members on delete set null,
  source           text not null default 'manual' check (source in ('ava', 'eventkit', 'manual')),
  external_id      text,  -- EventKit identifier for synced events
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Grocery lists — one active list per user at a time (typically)
create table public.grocery_lists (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles on delete cascade not null,
  store_name  text,
  pickup_time timestamptz,
  archived    boolean not null default false,
  created_at  timestamptz not null default now()
);

-- Grocery items
create table public.grocery_items (
  id         uuid primary key default gen_random_uuid(),
  list_id    uuid references public.grocery_lists on delete cascade not null,
  user_id    uuid references public.profiles on delete cascade not null,
  name       text not null,
  quantity   text,
  category   text check (category in ('produce', 'pantry', 'dairy', 'meat', 'bakery', 'frozen', 'other')),
  tag        text,  -- e.g. 'dinner', "mia's snack"
  checked    boolean not null default false,
  added_by   text not null default 'user' check (added_by in ('user', 'ava')),
  created_at timestamptz not null default now()
);

-- Conversations — each chat session with Ava
create table public.conversations (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.profiles on delete cascade not null,
  title           text,
  last_message_at timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

-- Messages — individual messages in a conversation
create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations on delete cascade not null,
  user_id         uuid references public.profiles on delete cascade not null,
  role            text not null check (role in ('user', 'assistant')),
  content         text not null,
  model           text,     -- 'claude-haiku-4-5' | 'claude-sonnet-4-6' etc.
  input_tokens    integer,
  output_tokens   integer,
  created_at      timestamptz not null default now()
);

-- Ava memories — key facts Ava remembers about the user
create table public.ava_memories (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.profiles on delete cascade not null,
  key        text not null,
  value      text not null,
  category   text not null default 'general'
               check (category in ('preference', 'routine', 'family', 'health', 'general')),
  embedding  vector(1536),  -- for semantic search via pgvector
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Subscriptions — synced from RevenueCat webhooks (written by Edge Function only)
create table public.subscriptions (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid references public.profiles on delete cascade not null unique,
  revenuecat_customer_id  text,
  tier                    text not null default 'none'
                            check (tier in ('none', 'standard', 'pro')),
  status                  text not null default 'inactive'
                            check (status in ('active', 'inactive', 'trial', 'cancelled', 'grace_period')),
  is_annual               boolean not null default false,
  current_period_ends_at  timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

-- ============================================================
-- INDEXES
-- ============================================================

create index tasks_user_id_idx           on public.tasks (user_id);
create index tasks_due_date_idx          on public.tasks (due_date) where not completed;
create index calendar_events_user_idx    on public.calendar_events (user_id, starts_at);
create index grocery_items_list_idx      on public.grocery_items (list_id);
create index messages_conversation_idx   on public.messages (conversation_id, created_at);
create index ava_memories_user_idx       on public.ava_memories (user_id, category);

-- Vector similarity index for Ava memory search
create index ava_memories_embedding_idx on public.ava_memories
  using ivfflat (embedding vector_cosine_ops) with (lists = 100);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles        enable row level security;
alter table public.family_members  enable row level security;
alter table public.tasks           enable row level security;
alter table public.calendar_events enable row level security;
alter table public.grocery_lists   enable row level security;
alter table public.grocery_items   enable row level security;
alter table public.conversations   enable row level security;
alter table public.messages        enable row level security;
alter table public.ava_memories    enable row level security;
alter table public.subscriptions   enable row level security;

-- Profiles
create policy "own profile"
  on public.profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Family members
create policy "own family members"
  on public.family_members for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Tasks
create policy "own tasks"
  on public.tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Calendar events
create policy "own calendar events"
  on public.calendar_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Grocery lists
create policy "own grocery lists"
  on public.grocery_lists for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Grocery items
create policy "own grocery items"
  on public.grocery_items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Conversations
create policy "own conversations"
  on public.conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Messages
create policy "own messages"
  on public.messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Ava memories
create policy "own ava memories"
  on public.ava_memories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Subscriptions: users can read only — writes come from Edge Functions via service role
create policy "read own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-create profile + subscription row when a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id);

  insert into public.subscriptions (user_id)
  values (new.id);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto-update updated_at on any row change
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

create trigger tasks_updated_at
  before update on public.tasks
  for each row execute procedure public.set_updated_at();

create trigger calendar_events_updated_at
  before update on public.calendar_events
  for each row execute procedure public.set_updated_at();

create trigger ava_memories_updated_at
  before update on public.ava_memories
  for each row execute procedure public.set_updated_at();

create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- HELPER: semantic memory search (called from Edge Functions)
-- ============================================================
create or replace function search_ava_memories(
  p_user_id  uuid,
  p_embedding vector(1536),
  p_limit     int default 10
)
returns table (id uuid, key text, value text, category text, similarity float)
language sql stable
as $$
  select
    id, key, value, category,
    1 - (embedding <=> p_embedding) as similarity
  from public.ava_memories
  where user_id = p_user_id
    and embedding is not null
  order by embedding <=> p_embedding
  limit p_limit;
$$;
