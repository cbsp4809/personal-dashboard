-- "Quiet" a card: still on the list, greyed, sunk to the bottom.
--
-- APPLIED 2026-10-08 to daddiljpnhfuxcdqsulg. Recorded here for the repo.
--
-- For work that is blocked on somebody else — not done, not urgent, but it must
-- not vanish. Raising it brings it back to the top of its list, because if the
-- block has cleared it is now the live thing.
--
-- Why a separate table rather than a column on ops_cards
-- ------------------------------------------------------
-- ops_cards is shared with Sydney. Chris is often waiting on *her*, and if
-- quieting greyed the card in her view too she would reasonably read it as
-- "deprioritised" — so it would sink for both of them, which is the opposite of
-- the point. Quiet is one person's attention, not a property of the work.
--
-- RLS makes that real rather than cosmetic: each row is visible only to the user
-- who created it. Verified after applying — with Chris's user id the probe row
-- was visible (1), with another user's it was not (0).
--
-- Note this uses `user_id = auth.uid()`, NOT private.is_staff(). Staff can see
-- each other's cards; they must not see each other's quiet state.
--
-- Run manually in the Supabase SQL editor. Idempotent — safe to re-run.

create table if not exists public.ops_card_quiet (
  card_id    uuid not null references public.ops_cards(id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  quieted_at timestamptz not null default now(),
  primary key (card_id, user_id)
);

create index if not exists ops_card_quiet_user_idx on public.ops_card_quiet (user_id);

alter table public.ops_card_quiet enable row level security;

drop policy if exists ops_card_quiet_own on public.ops_card_quiet;
create policy ops_card_quiet_own on public.ops_card_quiet
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

comment on table public.ops_card_quiet is
  'Per-person quiet state for ops_cards. Deliberately not a column on ops_cards: that table is shared, and one person quieting a card must not de-emphasise it for the other.';
comment on column public.ops_card_quiet.quieted_at is
  'When it was quieted. Surfaced on the card as "quiet 6d" so a long block becomes visible without a notification.';

-- What the app does with it:
--   quiet   -> insert a row; compareCards sinks it below every live card
--   raise   -> delete the row, and set ops_cards.sort to (min sort in that
--              project+column) - 1 so it returns to the top
--
-- Check your own quiet pile at any time:
--   select c.title, q.quieted_at,
--          date_trunc('day', now() - q.quieted_at) as waiting
--   from public.ops_card_quiet q
--   join public.ops_cards c on c.id = q.card_id
--   where c.done_at is null
--   order by q.quieted_at;
