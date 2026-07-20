-- Photo uploads in chat (roadmap #16): private storage bucket + per-message
-- image reference. Monthly cap (50) is enforced in the chat edge function.

alter table public.messages
  add column if not exists image_path text;

insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', false)
on conflict (id) do nothing;

drop policy if exists "chat images upload" on storage.objects;
create policy "chat images upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "chat images read" on storage.objects;
create policy "chat images read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
