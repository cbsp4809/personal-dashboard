-- Inbound email context and reply-send queue for Ops cards.
-- Run manually on the Studio Pod Supabase project; this repository does not
-- apply production SQL.

alter table public.ops_cards
  add column if not exists inbound_from text,
  add column if not exists inbound_subject text,
  add column if not exists inbound_body text,
  add column if not exists inbound_message_id text,
  add column if not exists send_requested_at timestamptz,
  add column if not exists send_requested_by text;

comment on column public.ops_cards.inbound_from is
  'Plain-text From value for the source email shown in the Ops Emails view.';

comment on column public.ops_cards.inbound_subject is
  'Subject of the source email shown in the Ops Emails view.';

comment on column public.ops_cards.inbound_body is
  'Plain-text body of the received source email; never an HTML rendering.';

comment on column public.ops_cards.inbound_message_id is
  'Provider message identifier Sydney can use with source_ref to reply in the correct thread.';

comment on column public.ops_cards.send_requested_at is
  'When a dashboard user queued the current snippet for Sydney to send; null until requested.';

comment on column public.ops_cards.send_requested_by is
  'Dashboard actor that queued the reply, currently chris.';
