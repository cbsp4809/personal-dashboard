-- Original email participants and the exact recipients queued for a reply.
-- Run manually on the Studio Pod Supabase project; this repository does not
-- apply production SQL.

alter table public.ops_cards
  add column if not exists inbound_to text,
  add column if not exists inbound_cc text,
  add column if not exists inbound_account text,
  add column if not exists reply_all boolean,
  add column if not exists reply_to text[],
  add column if not exists reply_cc text[],
  add column if not exists reply_bcc text[];

comment on column public.ops_cards.inbound_to is
  'Plain-text To header from the source email, including display names when available.';

comment on column public.ops_cards.inbound_cc is
  'Plain-text Cc header from the source email, including display names when available.';

comment on column public.ops_cards.inbound_account is
  'Email address of the Chris-owned inbox that received the source email; excluded from reply-all recipients.';

comment on column public.ops_cards.reply_all is
  'True when Chris selected Reply all; false when he selected Sender only.';

comment on column public.ops_cards.reply_to is
  'Exact normalized email addresses Sydney should place in To when sending the queued reply.';

comment on column public.ops_cards.reply_cc is
  'Exact normalized email addresses Sydney should place in Cc when sending the queued reply.';

comment on column public.ops_cards.reply_bcc is
  'Exact normalized email addresses Sydney should place in Bcc when sending the queued reply.';
