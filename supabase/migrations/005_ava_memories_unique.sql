-- ============================================================
-- Fix: ava_memories upsert requires a unique constraint
-- ============================================================
-- extract-memory upserts with onConflict "user_id,key", but the initial
-- schema never created a unique constraint on (user_id, key). Without it,
-- Postgres rejects the upsert (42P10) and — because the function ignored
-- the error — memories were silently never saved.
--
-- Safe to run repeatedly: skips if a unique index on (user_id, key)
-- already exists (e.g. added manually in the dashboard).

do $$
declare
  has_unique boolean;
begin
  select exists (
    select 1
    from pg_index i
    join pg_class t on t.oid = i.indrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'ava_memories'
      and i.indisunique
      and (
        select array_agg(a.attname order by a.attname)
        from unnest(i.indkey) with ordinality as k(attnum, ord)
        join pg_attribute a on a.attrelid = t.oid and a.attnum = k.attnum
      ) = array['key', 'user_id']::name[]
  ) into has_unique;

  if not has_unique then
    -- Dedupe first: keep the most recently updated row per (user_id, key)
    delete from public.ava_memories a
    using public.ava_memories b
    where a.user_id = b.user_id
      and a.key = b.key
      and a.id <> b.id
      and (a.updated_at < b.updated_at
           or (a.updated_at = b.updated_at and a.id < b.id));

    alter table public.ava_memories
      add constraint ava_memories_user_key_unique unique (user_id, key);
  end if;
end $$;
