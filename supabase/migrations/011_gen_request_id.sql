-- Async image generation: store Higgsfield's request id so the app can
-- poll for completion instead of holding one long function call open.
alter table public.image_generations
  add column if not exists hf_request_id text;
