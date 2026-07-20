-- Evening brief: hourly sweep, function notifies users at 8pm local time
-- (companion to morning-brief-hourly; see 006_profile_timezone.sql)

select cron.schedule(
  'evening-brief-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url     := 'https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/evening-brief',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body    := '{}'::jsonb
  ) as request_id;
  $$
);
