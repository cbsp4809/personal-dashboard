-- Separate Chris and Sydney notes for Ops card details. Run manually on
-- Studio Pod (daddiljpnhfuxcdqsulg); this repository does not apply
-- production SQL.

alter table public.ops_cards
  add column if not exists notes text,
  add column if not exists sydney_notes text;

comment on column public.ops_cards.notes is
  'Chris-editable card notes. The UI falls back to snippet when this is null.';

comment on column public.ops_cards.sydney_notes is
  'Sydney-written research, recommendations, and links shown read-only to Chris.';
