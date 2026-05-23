create table public.notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.profiles on delete cascade not null,
  title      text not null,
  content    text not null default '',
  source     text not null default 'user' check (source in ('user', 'ava')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index notes_user_idx on public.notes (user_id, created_at);

alter table public.notes enable row level security;

create policy "own notes"
  on public.notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create trigger notes_updated_at
  before update on public.notes
  for each row execute procedure public.set_updated_at();
