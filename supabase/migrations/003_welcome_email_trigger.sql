-- Paste in Supabase Dashboard → SQL Editor
-- Fires welcome-email edge function every time a new user signs up

CREATE EXTENSION IF NOT EXISTS pg_net;

-- Update the existing handle_new_user function to also send welcome email
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Create profile row
  INSERT INTO public.profiles (id)
  VALUES (new.id);

  -- Create subscription row (default tier: none)
  INSERT INTO public.subscriptions (user_id)
  VALUES (new.id);

  -- Fire welcome email (best-effort, won't block signup if it fails)
  PERFORM net.http_post(
    url     := 'https://syhzfjrvbrqrsesxubtx.supabase.co/functions/v1/welcome-email',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body    := json_build_object(
      'userId', new.id,
      'email',  new.email
    )::jsonb
  );

  RETURN new;
END;
$$;
