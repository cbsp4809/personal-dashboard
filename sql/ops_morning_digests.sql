-- Morning digest rows for the Ops Digest tab.
-- Run manually on Studio Pod (daddiljpnhfuxcdqsulg). This repository does not
-- apply production SQL. Do not put a service-role key in ops.html.
--
-- digest_date is the Chicago calendar date, one row per day.
-- Sydney's weekday 7am routine should INSERT/UPSERT today's row and set
-- archived_at on yesterday (and any older unarchived rows). The Ops page
-- only reads this table; it does not fetch calendars in the browser.
--
-- Example writer (service_role or a signed-in Studio Pod user):
--   update public.ops_morning_digests
--     set archived_at = now(), updated_at = now()
--     where digest_date < (timezone('America/Chicago', now()))::date
--       and archived_at is null;
--   insert into public.ops_morning_digests
--     (digest_date, summary, lunch, needs_you, sections, body)
--   values
--     (
--       (timezone('America/Chicago', now()))::date,
--       'Short day summary',
--       'Frostwood for Teddy',
--       'Anything that needs Chris',
--       '{"meetings":"","shoots":"","family":""}'::jsonb,
--       ''
--     )
--   on conflict (digest_date) do update set
--     summary = excluded.summary,
--     lunch = excluded.lunch,
--     needs_you = excluded.needs_you,
--     sections = excluded.sections,
--     body = excluded.body,
--     archived_at = null,
--     updated_at = now();

create table if not exists public.ops_morning_digests (
  id uuid primary key default gen_random_uuid(),
  digest_date date not null,
  summary text not null default '',
  lunch text not null default '',
  needs_you text not null default '',
  sections jsonb not null default '{}'::jsonb,
  body text not null default '',
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists ops_morning_digests_digest_date_uidx
  on public.ops_morning_digests (digest_date);

create index if not exists ops_morning_digests_archived_date_idx
  on public.ops_morning_digests (digest_date desc)
  where archived_at is not null;

comment on table public.ops_morning_digests is
  'One Ops morning digest per Chicago calendar date. Sydney writes; the dashboard reads.';

comment on column public.ops_morning_digests.digest_date is
  'Chicago calendar date for this digest. Unique. Writers should use (timezone(''America/Chicago'', now()))::date.';

comment on column public.ops_morning_digests.summary is
  'Short day summary (meetings / shoots / family).';

comment on column public.ops_morning_digests.lunch is
  'Kids lunch note, e.g. Frostwood for Teddy.';

comment on column public.ops_morning_digests.needs_you is
  'Anything that needs Chris today.';

comment on column public.ops_morning_digests.sections is
  'Optional extra blocks. Object map {heading: text} or array of {title, body}.';

comment on column public.ops_morning_digests.body is
  'Optional full-text fallback when summary is empty.';

comment on column public.ops_morning_digests.archived_at is
  'Set by Sydney after the Chicago day has passed. The page also treats past dates as archive.';

alter table public.ops_morning_digests enable row level security;

drop policy if exists ops_morning_digests_auth_all on public.ops_morning_digests;

-- Same shared-table model as ops_cards: any signed-in Studio Pod user can
-- read and write. Anon stays revoked. service_role keeps full access for Sydney.
create policy ops_morning_digests_auth_all
  on public.ops_morning_digests
  for all
  to authenticated
  using (true)
  with check (true);

revoke all on public.ops_morning_digests from anon;
revoke all on public.ops_morning_digests from authenticated;
grant select, insert, update on public.ops_morning_digests to authenticated;
grant all on public.ops_morning_digests to service_role;
