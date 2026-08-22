-- Ops card stack ordering. Run on Studio Pod (daddiljpnhfuxcdqsulg) only if
-- ops_cards does not already have the `sort` column/index.
--
-- The current Studio Pod table already has both as of 2026-08-22, so no live
-- database change is required for the reorder UI.

alter table public.ops_cards
  add column if not exists sort integer default 0;

update public.ops_cards
set sort = 0
where sort is null;

alter table public.ops_cards
  alter column sort set default 0;

create index if not exists ops_cards_column_idx
  on public.ops_cards (column_key, sort);

-- Give existing open cards an unambiguous 0-based position in each stack.
with ranked as (
  select
    id,
    row_number() over (
      partition by column_key
      order by sort, created_at, id
    ) - 1 as stack_position
  from public.ops_cards
  where done_at is null
)
update public.ops_cards as card
set sort = ranked.stack_position
from ranked
where card.id = ranked.id
  and card.sort is distinct from ranked.stack_position;
