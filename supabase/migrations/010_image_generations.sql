-- Higgsfield image generation (roadmap #17): 10/month for all plans.
-- Rows with status 'refunded' don't count against the cap.

create table if not exists public.image_generations (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.profiles on delete cascade not null,
  prompt     text not null,
  status     text not null default 'queued'
               check (status in ('queued', 'completed', 'failed', 'refunded')),
  image_path text,
  created_at timestamptz not null default now()
);

create index if not exists image_generations_user_idx
  on public.image_generations (user_id, created_at);

alter table public.image_generations enable row level security;

drop policy if exists "read own generations" on public.image_generations;
create policy "read own generations" on public.image_generations
  for select using (auth.uid() = user_id);
-- writes come only from the generate-image edge function (service role)
