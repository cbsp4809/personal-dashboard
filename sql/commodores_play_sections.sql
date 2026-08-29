-- Coach-controlled sections and ordering for Commodores plays.
-- Run manually on the Commodores project only (adjnmtpjoyxvmlogjjpz).
-- Do not run on Studio Pod (daddiljpnhfuxcdqsulg) or CBP.
--
-- Idempotent. Existing plays start in Playbook in their current numeric order.
-- New rows default to Upcoming. Coaches can move plays in either direction and
-- arrange each section in plays.html.

alter table public.commodores_plays
  add column if not exists section text,
  add column if not exists sort_order integer;

update public.commodores_plays
set section = 'playbook'
where section is null;

with ranked as (
  select number, row_number() over (order by number::integer) * 10 as position
  from public.commodores_plays
)
update public.commodores_plays as play
set sort_order = ranked.position
from ranked
where play.number = ranked.number
  and play.sort_order is null;

alter table public.commodores_plays
  alter column section set default 'upcoming',
  alter column section set not null,
  alter column sort_order set default 0,
  alter column sort_order set not null;

alter table public.commodores_plays
  drop constraint if exists commodores_plays_section_ok,
  drop constraint if exists commodores_plays_sort_order_ok;

alter table public.commodores_plays
  add constraint commodores_plays_section_ok
    check (section in ('playbook', 'upcoming')),
  add constraint commodores_plays_sort_order_ok
    check (sort_order >= 0);

create index if not exists commodores_plays_section_order_idx
  on public.commodores_plays (section, sort_order, number);

comment on column public.commodores_plays.section is
  'Coach grouping shown in the animator and published watch snapshot: playbook or upcoming.';
comment on column public.commodores_plays.sort_order is
  'Coach-controlled display order within a section. Smaller values appear first.';
