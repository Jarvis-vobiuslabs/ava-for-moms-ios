-- Opt-in motivational quote in the 7am morning brief (Account screen toggle)
alter table public.profiles
  add column if not exists quote_of_day boolean not null default false;
