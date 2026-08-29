-- Per-play route runners and optional roster jersey numbers.
-- Run manually on the Commodores project only (adjnmtpjoyxvmlogjjpz).
-- Do not run on Studio Pod (daddiljpnhfuxcdqsulg) or CBP.
--
-- Idempotent. Existing play geometry and roster names are unchanged.

alter table public.commodores_roster
  add column if not exists jersey text;

alter table public.commodores_roster
  drop constraint if exists commodores_roster_jersey_ok;

alter table public.commodores_roster
  add constraint commodores_roster_jersey_ok
    check (jersey is null or jersey ~ '^[0-9]{1,2}$');

comment on column public.commodores_roster.jersey is
  'Optional one- or two-digit jersey label. Null means show first name only.';

alter table public.commodores_plays
  add column if not exists assignees jsonb not null
    default '{"A":{},"B":{}}'::jsonb;

alter table public.commodores_plays
  drop constraint if exists commodores_plays_assignees_object;

alter table public.commodores_plays
  add constraint commodores_plays_assignees_object
    check (jsonb_typeof(assignees) = 'object');

comment on column public.commodores_plays.assignees is
  'Per-quarter-unit route runner first names keyed by internal unit A/B and offense letter. Geometry remains in spots.';
