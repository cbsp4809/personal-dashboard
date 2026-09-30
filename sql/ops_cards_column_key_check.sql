-- Refuse a board column the app cannot render.
--
-- On 2026-09-07 five CBP cards were written with column_key = 'needs_you'
-- (underscore) instead of 'needs-you'. The board only renders the hyphenated
-- key, so those cards sat in the database, not done, visible to nobody, for
-- three weeks. They were real work — an unpaid permit, a commissions sign-off,
-- a $1k invoice, a sponsor quote.
--
-- The underscore spelling is not a typo in the usual sense: needs_you IS the
-- correct name in ops_morning_digests.needs_you and in ops_content.status.
-- Only this column uses the hyphen, so anyone moving between them will
-- eventually get it wrong. Better for the database to say no than for a card to
-- disappear.
--
-- APPLIED 2026-09-30 to daddiljpnhfuxcdqsulg. Recorded here for the repo.
-- Before applying: 1,325 rows, 0 invalid, 0 null. Sydney confirmed nothing she
-- runs writes outside this list. Verified after: an insert of 'needs_you' is
-- rejected with a check violation.
--
-- Run manually in the Supabase SQL editor; this repository does not apply SQL.
-- Idempotent — safe to re-run.

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'ops_cards_column_key_valid'
  ) then
    alter table public.ops_cards
      add constraint ops_cards_column_key_valid
      check (column_key in ('needs-you','today','this-week','later','sydney'));
  end if;
end $$;

comment on constraint ops_cards_column_key_valid on public.ops_cards is
  'Board columns Ops can render. Keep in sync with COLUMNS in ops.html — the labels there are priorities (High/Medium/Low/Backlog) but these stored keys must not change.';

-- If a column is ever added or renamed, the constraint has to be replaced, not
-- edited:
--
--   alter table public.ops_cards drop constraint ops_cards_column_key_valid;
--   -- then re-run the block above with the new list
--
-- Check for strays at any time with:
--
--   select column_key, count(*) from public.ops_cards
--   where column_key not in ('needs-you','today','this-week','later','sydney')
--   group by column_key;
