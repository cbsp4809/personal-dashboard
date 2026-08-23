-- Commodores staff comments and practice plans.
-- Run manually on Studio Pod (daddiljpnhfuxcdqsulg).
-- NEW tables only. Do not read or write ops_cards / ops_alerts.
-- commodores.html is a PIN-gated static GitHub Pages file (same client pattern
-- as Ops). It uses the existing public URL + publishable/anon key, never a
-- service_role key. Anon must be able to select/insert/update these two tables.

create table if not exists public.commodores_comments (
  id text primary key default gen_random_uuid()::text,
  author_first text not null default 'staff'
    check (author_first in ('Peter', 'Chris', 'Ben', 'staff')),
  body text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists commodores_comments_created_at_idx
  on public.commodores_comments (created_at desc);

comment on table public.commodores_comments is
  'Shared Commodores staff notes. Reserved ids: after-practice, next-install. Other rows are the comments thread.';
comment on column public.commodores_comments.id is
  'Text id. Use after-practice and next-install for the two note boxes; uuid text for staff comments.';
comment on column public.commodores_comments.author_first is
  'Optional coach first name: Peter, Chris, Ben, or staff.';
comment on column public.commodores_comments.body is
  'Note or comment text.';
comment on column public.commodores_comments.created_at is
  'Insert time. Upserts of reserved note ids keep the original created_at.';

create table if not exists public.commodores_plans (
  id text primary key,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists commodores_plans_updated_at_idx
  on public.commodores_plans (updated_at desc);

comment on table public.commodores_plans is
  'Shared Commodores practice plans. Agents upsert a row; the staff page uses it when updated_at is newer than local.';
comment on column public.commodores_plans.id is
  'Plan id, same as payload.id (for example 2026-08-27 or 2026-08-30-scrimmage).';
comment on column public.commodores_plans.payload is
  'Full plan JSON: { id, date, time, location, duration, goal, stations: [{ minutes, name, detail, coach, concurrent? }] }.';
comment on column public.commodores_plans.updated_at is
  'Set to now() on every upsert so the next page load prefers this row over an older local copy.';

alter table public.commodores_comments enable row level security;
alter table public.commodores_plans enable row level security;

drop policy if exists commodores_comments_read on public.commodores_comments;
drop policy if exists commodores_comments_insert on public.commodores_comments;
drop policy if exists commodores_comments_update on public.commodores_comments;
drop policy if exists commodores_plans_read on public.commodores_plans;
drop policy if exists commodores_plans_insert on public.commodores_plans;
drop policy if exists commodores_plans_update on public.commodores_plans;

-- UPDATE also needs the SELECT policy.
create policy commodores_comments_read
  on public.commodores_comments
  for select
  to anon, authenticated
  using (true);

create policy commodores_comments_insert
  on public.commodores_comments
  for insert
  to anon, authenticated
  with check (true);

create policy commodores_comments_update
  on public.commodores_comments
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy commodores_plans_read
  on public.commodores_plans
  for select
  to anon, authenticated
  using (true);

create policy commodores_plans_insert
  on public.commodores_plans
  for insert
  to anon, authenticated
  with check (true);

create policy commodores_plans_update
  on public.commodores_plans
  for update
  to anon, authenticated
  using (true)
  with check (true);

revoke all on public.commodores_comments from anon;
revoke all on public.commodores_comments from authenticated;
revoke all on public.commodores_plans from anon;
revoke all on public.commodores_plans from authenticated;

grant select, insert, update on public.commodores_comments to anon, authenticated;
grant select, insert, update on public.commodores_plans to anon, authenticated;
grant all on public.commodores_comments to service_role;
grant all on public.commodores_plans to service_role;
