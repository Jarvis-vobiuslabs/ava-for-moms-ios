-- Per-account timezone so scheduled notifications fire at local time.
-- The app writes TimeZone.current.identifier on every launch (AuthManager).
-- Default 'UTC' keeps behavior unchanged for users who haven't updated yet
-- (the old morning-brief cron fired at 07:00 UTC for everyone).

alter table public.profiles
  add column if not exists timezone text not null default 'UTC';

-- Morning brief becomes an hourly sweep: the function itself decides which
-- users are currently at 7am local time and only notifies those.
do $$
begin
  perform cron.unschedule('morning-brief-daily');
exception when others then
  null;  -- job may not exist on fresh databases
end $$;

select cron.schedule(
  'morning-brief-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url     := 'https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/morning-brief',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body    := '{}'::jsonb
  ) as request_id;
  $$
);
