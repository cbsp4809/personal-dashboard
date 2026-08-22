-- Email receipt time for Ops cards. Run manually on Studio Pod
-- (daddiljpnhfuxcdqsulg); this repository does not apply production SQL.
--
-- Inbox watch writes this value for new source=email cards. It remains nullable
-- so existing cards can fall back to created_at in the UI.

alter table public.ops_cards
  add column if not exists received_at timestamptz;

comment on column public.ops_cards.received_at is
  'When the source email was received; distinct from the Ops card insertion time.';
