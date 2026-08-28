-- Sales / lead flag for Ops email cards. Run manually on Studio Pod
-- (daddiljpnhfuxcdqsulg); this repository does not apply production SQL.
--
-- Inbox watch should set email_kind when creating source=email cards:
--   sales | lead | other
-- If omitted, Ops classifies from title / subject / inbound body and persists.
-- Chris or Sydney can override the flag from the open email card.

alter table public.ops_cards
  add column if not exists email_kind text;

alter table public.ops_cards
  drop constraint if exists ops_cards_email_kind_check;

alter table public.ops_cards
  add constraint ops_cards_email_kind_check
  check (email_kind is null or email_kind in ('sales', 'lead', 'other'));

comment on column public.ops_cards.email_kind is
  'Ops Emails classification: sales (quote/RFP/booking), lead (new inquiry), or other. Null means not yet classified.';

create index if not exists ops_cards_email_kind_open_idx
  on public.ops_cards (email_kind)
  where source = 'email' and done_at is null;

-- Conservative backfill for open email cards only. Leave unmatched rows null
-- so the Ops page can finish classification from the full heuristic.
update public.ops_cards
set email_kind = 'sales'
where source = 'email'
  and done_at is null
  and email_kind is null
  and (
    coalesce(title, '') || ' ' ||
    coalesce(inbound_subject, '') || ' ' ||
    left(coalesce(inbound_body, ''), 900)
  ) ~* '(quote request|help me quote|request a quote|please quote|\yquotation\y|\yquote\y|\yrfps?\y|headshot lounge|sponsor sales|booking request|rate card|portrait partnership|executive portrait)';

update public.ops_cards
set email_kind = 'lead'
where source = 'email'
  and done_at is null
  and email_kind is null
  and (
    coalesce(title, '') || ' ' ||
    coalesce(inbound_subject, '') || ' ' ||
    left(coalesce(inbound_body, ''), 900)
  ) ~* '(new (studio pod |cbp |photography )?inquir|contact form|interested in|demo request|book a demo)';