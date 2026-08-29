-- Practice offense/defense tags and optional roster jersey numbers.
-- Run manually on the Commodores project only (adjnmtpjoyxvmlogjjpz).
-- Do not run on Studio Pod (daddiljpnhfuxcdqsulg) or CBP.
--
-- Idempotent. Existing play geometry and roster names are unchanged. Game-day
-- labels continue to come from commodores_plans row staff-lineup.

alter table public.commodores_roster
  add column if not exists jersey text,
  add column if not exists offense_tags text[] not null default '{}'::text[],
  add column if not exists defense_tags text[] not null default '{}'::text[];

alter table public.commodores_roster
  drop constraint if exists commodores_roster_jersey_ok,
  drop constraint if exists commodores_roster_offense_tags_ok,
  drop constraint if exists commodores_roster_defense_tags_ok;

alter table public.commodores_roster
  add constraint commodores_roster_jersey_ok
    check (jersey is null or jersey ~ '^[0-9]{1,2}$'),
  add constraint commodores_roster_offense_tags_ok
    check (offense_tags <@ array['Q','C','X','A','B','Y','Z']::text[]),
  add constraint commodores_roster_defense_tags_ok
    check (defense_tags <@ array['D1','D2','D3','D4','D5','D6','D7']::text[]);

comment on column public.commodores_roster.jersey is
  'Optional one- or two-digit jersey label. Null means show first name only.';
comment on column public.commodores_roster.offense_tags is
  'Practice route letters this player learns. Multiple players may share each letter.';
comment on column public.commodores_roster.defense_tags is
  'Practice coverage zones D1-D7 this player learns. Multiple players may share each zone.';

-- An earlier unmerged draft stored per-play assignments. The locked model uses
-- roster tags for practice and the game lineup for coaches, so remove that draft.
alter table public.commodores_plays
  drop column if exists assignees;
