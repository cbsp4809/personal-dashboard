-- Personal Home tab for Ops (Chris). Run manually on Studio Pod
-- (daddiljpnhfuxcdqsulg). This repository does not apply production SQL.
-- Do not put a service-role key in ops.html.
--
-- Shared-table model matches other ops_* tables: any signed-in Studio Pod
-- user (Chris, Sydney) can read and write. Anon stays revoked. service_role
-- keeps full access for Sydney's writers. The Ops page does not send email,
-- pull Gmail, Canvas, or SchoolCafé.
--
-- Sydney:
--   * Insert school pins after she reads a parent/school email.
--   * Upsert this week's lunch row (week_of = Monday, America/Chicago).
--   * Insert Virginia Hub tests/quizzes/assignments.
--   * After emailing Regan, set emailed_at on that day's gratitude row.
--     Do not expect the browser to send mail.
--
-- Lunch jsonb per school (frostwood / memorial), keys Mon..Fri:
--   { "Mon": { "flag": "buy"|"pack"|"menu", "items": ["..."] }, ... }
-- Teddy / Frostwood: buy Mon/Wed/Thu, pack Tue/Fri.
-- Virginia / Memorial: menu only (flag "menu"). Do not invent buy/pack
-- for Virginia.

create table if not exists public.ops_home_gratitude (
  id uuid primary key default gen_random_uuid(),
  gratitude_date date not null,
  body text not null,
  copy_text text not null,
  emailed_at timestamptz,
  email_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (gratitude_date)
);

comment on table public.ops_home_gratitude is
  'One gratitude note per Chicago calendar date. Chris writes; Sydney emails Regan separately and stamps emailed_at.';

comment on column public.ops_home_gratitude.gratitude_date is
  'America/Chicago calendar date. Unique. Writers should use (timezone(''America/Chicago'', now()))::date.';

comment on column public.ops_home_gratitude.body is
  'What Chris wrote. The UI does not add Dear Regan or other labels.';

comment on column public.ops_home_gratitude.copy_text is
  'Paste-ready Apple Notes block: long Chicago date, blank line, then body.';

comment on column public.ops_home_gratitude.emailed_at is
  'Set by Sydney after she emails regan.l.bailey@gmail.com. The page never sends mail.';

create table if not exists public.ops_home_pins (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'gmail',
  source_ref text,
  from_name text,
  subject text,
  summary text not null,
  received_at timestamptz,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ops_home_pins_read_received_idx
  on public.ops_home_pins (read_at, received_at desc);

create index if not exists ops_home_pins_unread_received_idx
  on public.ops_home_pins (received_at desc)
  where read_at is null;

comment on table public.ops_home_pins is
  'School email summary pins. Sydney inserts; Chris checks off after reading.';

comment on column public.ops_home_pins.source_ref is
  'Optional Gmail message or thread id. The page does not fetch Gmail.';

comment on column public.ops_home_pins.summary is
  'Short plain-English summary Sydney writes.';

comment on column public.ops_home_pins.read_at is
  'Set when Chris taps Got it. Hidden from the Home list once set.';

create table if not exists public.ops_home_lunch (
  id uuid primary key default gen_random_uuid(),
  week_of date not null,
  frostwood jsonb not null default '{}'::jsonb,
  memorial jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (week_of)
);

comment on table public.ops_home_lunch is
  'One lunch card per school week. week_of is the Monday in America/Chicago.';

comment on column public.ops_home_lunch.week_of is
  'Monday of the school week (America/Chicago). Unique.';

comment on column public.ops_home_lunch.frostwood is
  'Teddy / Frostwood days Mon-Fri: {flag: buy|pack|menu, items: [...]}.';

comment on column public.ops_home_lunch.memorial is
  'Virginia / Memorial days Mon-Fri: menu only (flag menu).';

create table if not exists public.ops_home_virginia (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  kind text not null default 'assignment',
  due_at timestamptz,
  notes text,
  source_ref text,
  done_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ops_home_virginia_kind_chk'
      and conrelid = 'public.ops_home_virginia'::regclass
  ) then
    alter table public.ops_home_virginia
      add constraint ops_home_virginia_kind_chk
      check (kind in ('test', 'quiz', 'assignment'));
  end if;
end
$$;

create index if not exists ops_home_virginia_open_due_idx
  on public.ops_home_virginia (due_at)
  where done_at is null;

create index if not exists ops_home_virginia_done_at_idx
  on public.ops_home_virginia (done_at);

comment on table public.ops_home_virginia is
  'Virginia Hub tests, quizzes, and assignments for the Home tab. Sydney writes.';

comment on column public.ops_home_virginia.kind is
  'test, quiz, or assignment.';

comment on column public.ops_home_virginia.source_ref is
  'Optional Hub identifier. The page does not fetch Canvas.';

create table if not exists public.ops_home_prayers (
  id uuid primary key default gen_random_uuid(),
  who text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  done_at timestamptz
);

create index if not exists ops_home_prayers_done_created_idx
  on public.ops_home_prayers (done_at, created_at desc);

create index if not exists ops_home_prayers_open_updated_idx
  on public.ops_home_prayers (updated_at desc)
  where done_at is null;

comment on table public.ops_home_prayers is
  'Thoughts & Prayers board on Ops Home. Chris adds, edits, and archives. Private — the page never emails or shares.';

comment on column public.ops_home_prayers.who is
  'Person or situation Chris is holding in thought.';

comment on column public.ops_home_prayers.note is
  'Optional note: what to hold them in (surgery, job, grief, a date).';

comment on column public.ops_home_prayers.done_at is
  'Set when Chris taps Amen / Done. Leaves the open board.';

-- RLS: enable on every table. One permissive policy per action for
-- authenticated. Shared Studio Pod users (using true). No anon writes.
-- auth.uid() is not consulted (same as ops_cards / ops_morning_digests);
-- wrap it as (select auth.uid()) if a later policy needs the caller.

alter table public.ops_home_gratitude enable row level security;
alter table public.ops_home_pins enable row level security;
alter table public.ops_home_lunch enable row level security;
alter table public.ops_home_virginia enable row level security;
alter table public.ops_home_prayers enable row level security;

drop policy if exists ops_home_gratitude_select on public.ops_home_gratitude;
drop policy if exists ops_home_gratitude_insert on public.ops_home_gratitude;
drop policy if exists ops_home_gratitude_update on public.ops_home_gratitude;
drop policy if exists ops_home_pins_select on public.ops_home_pins;
drop policy if exists ops_home_pins_insert on public.ops_home_pins;
drop policy if exists ops_home_pins_update on public.ops_home_pins;
drop policy if exists ops_home_lunch_select on public.ops_home_lunch;
drop policy if exists ops_home_lunch_insert on public.ops_home_lunch;
drop policy if exists ops_home_lunch_update on public.ops_home_lunch;
drop policy if exists ops_home_virginia_select on public.ops_home_virginia;
drop policy if exists ops_home_virginia_insert on public.ops_home_virginia;
drop policy if exists ops_home_virginia_update on public.ops_home_virginia;
drop policy if exists ops_home_prayers_select on public.ops_home_prayers;
drop policy if exists ops_home_prayers_insert on public.ops_home_prayers;
drop policy if exists ops_home_prayers_update on public.ops_home_prayers;

create policy ops_home_gratitude_select
  on public.ops_home_gratitude
  for select
  to authenticated
  using (true);

create policy ops_home_gratitude_insert
  on public.ops_home_gratitude
  for insert
  to authenticated
  with check (true);

create policy ops_home_gratitude_update
  on public.ops_home_gratitude
  for update
  to authenticated
  using (true)
  with check (true);

create policy ops_home_pins_select
  on public.ops_home_pins
  for select
  to authenticated
  using (true);

create policy ops_home_pins_insert
  on public.ops_home_pins
  for insert
  to authenticated
  with check (true);

create policy ops_home_pins_update
  on public.ops_home_pins
  for update
  to authenticated
  using (true)
  with check (true);

create policy ops_home_lunch_select
  on public.ops_home_lunch
  for select
  to authenticated
  using (true);

create policy ops_home_lunch_insert
  on public.ops_home_lunch
  for insert
  to authenticated
  with check (true);

create policy ops_home_lunch_update
  on public.ops_home_lunch
  for update
  to authenticated
  using (true)
  with check (true);

create policy ops_home_virginia_select
  on public.ops_home_virginia
  for select
  to authenticated
  using (true);

create policy ops_home_virginia_insert
  on public.ops_home_virginia
  for insert
  to authenticated
  with check (true);

create policy ops_home_virginia_update
  on public.ops_home_virginia
  for update
  to authenticated
  using (true)
  with check (true);

create policy ops_home_prayers_select
  on public.ops_home_prayers
  for select
  to authenticated
  using (true);

create policy ops_home_prayers_insert
  on public.ops_home_prayers
  for insert
  to authenticated
  with check (true);

create policy ops_home_prayers_update
  on public.ops_home_prayers
  for update
  to authenticated
  using (true)
  with check (true);

revoke all on public.ops_home_gratitude from public;
revoke all on public.ops_home_gratitude from anon;
revoke all on public.ops_home_gratitude from authenticated;
grant select, insert, update on public.ops_home_gratitude to authenticated;
grant all on public.ops_home_gratitude to service_role;

revoke all on public.ops_home_pins from public;
revoke all on public.ops_home_pins from anon;
revoke all on public.ops_home_pins from authenticated;
grant select, insert, update on public.ops_home_pins to authenticated;
grant all on public.ops_home_pins to service_role;

revoke all on public.ops_home_lunch from public;
revoke all on public.ops_home_lunch from anon;
revoke all on public.ops_home_lunch from authenticated;
grant select, insert, update on public.ops_home_lunch to authenticated;
grant all on public.ops_home_lunch to service_role;

revoke all on public.ops_home_virginia from public;
revoke all on public.ops_home_virginia from anon;
revoke all on public.ops_home_virginia from authenticated;
grant select, insert, update on public.ops_home_virginia to authenticated;
grant all on public.ops_home_virginia to service_role;

revoke all on public.ops_home_prayers from public;
revoke all on public.ops_home_prayers from anon;
revoke all on public.ops_home_prayers from authenticated;
grant select, insert, update on public.ops_home_prayers to authenticated;
grant all on public.ops_home_prayers to service_role;
