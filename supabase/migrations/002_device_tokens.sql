-- Run this in Supabase Dashboard → SQL Editor

-- Device tokens for push notifications
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.profiles ON DELETE CASCADE NOT NULL UNIQUE,
  token       TEXT NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users manage own tokens"
  ON public.device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Auto-update updated_at
CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- Schedule morning brief at 7:00 AM UTC daily (uses pg_cron + pg_net)
-- Enable extensions first if not already enabled:
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.schedule(
  'morning-brief-daily',
  '0 7 * * *',
  $$
  SELECT net.http_post(
    url     := 'https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/morning-brief',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body    := '{}'::jsonb
  ) AS request_id;
  $$
);
