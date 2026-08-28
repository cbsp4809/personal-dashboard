-- Drawn Commodores plays for the play animator (plays.html).
-- Run manually on the Commodores project only (adjnmtpjoyxvmlogjjpz).
-- Do not run on Studio Pod (daddiljpnhfuxcdqsulg) or CBP.
--
-- Idempotent. Safe to re-run.
-- RLS matches the other Commodores tables: allowlisted coaches only
-- via public.commodores_is_coach(). Anon cannot read or write.

create table if not exists public.commodores_plays (
  number text primary key,
  title text not null default '',
  flip_partner text,
  spots jsonb not null default '[]'::jsonb,
  looks jsonb not null default '[]'::jsonb,
  family text not null default '',
  bullets jsonb not null default '[]'::jsonb,
  updated_by text,
  updated_at timestamptz not null default now(),
  constraint commodores_plays_number_ok
    check (number ~ '^[0-9]{1,4}$'),
  constraint commodores_plays_spots_array
    check (jsonb_typeof(spots) = 'array')
);

create index if not exists commodores_plays_updated_at_idx
  on public.commodores_plays (updated_at desc);

comment on table public.commodores_plays is
  'Coach-drawn play routes for plays.html. One row per play number (23, 26, 38).';
comment on column public.commodores_plays.number is
  'Play number as coaches call it: 23, 26, 38, 2, 19, 68, 6.';
comment on column public.commodores_plays.title is
  'Short title, for example Post Corner or Overload.';
comment on column public.commodores_plays.flip_partner is
  'Other-direction number when one exists (23↔26, 2↔19). Null if Flip is a live X-mirror.';
comment on column public.commodores_plays.spots is
  'Array of {letter, x, y, sit, route:[{x,y}], fieldW?}. Letters Q C X A B Y Z. Field is 480×400 (legacy 360×400 scaled on load), line at y=300.';
comment on column public.commodores_plays.looks is
  'Optional read chips: [{id, label, target, cue}]. Empty for drawn plays is fine.';
comment on column public.commodores_plays.updated_by is
  'Coach first name who last saved (Chris, Peter, Ben).';

alter table public.commodores_plays enable row level security;

drop policy if exists commodores_plays_read on public.commodores_plays;
drop policy if exists commodores_plays_insert on public.commodores_plays;
drop policy if exists commodores_plays_update on public.commodores_plays;
drop policy if exists commodores_plays_delete on public.commodores_plays;

create policy commodores_plays_read
  on public.commodores_plays
  for select
  to authenticated
  using (public.commodores_is_coach());

create policy commodores_plays_insert
  on public.commodores_plays
  for insert
  to authenticated
  with check (public.commodores_is_coach());

create policy commodores_plays_update
  on public.commodores_plays
  for update
  to authenticated
  using (public.commodores_is_coach())
  with check (public.commodores_is_coach());

create policy commodores_plays_delete
  on public.commodores_plays
  for delete
  to authenticated
  using (public.commodores_is_coach());

revoke all on public.commodores_plays from anon;
revoke all on public.commodores_plays from authenticated;

grant select, insert, update, delete on public.commodores_plays to authenticated;
grant all on public.commodores_plays to service_role;
