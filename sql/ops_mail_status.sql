-- Last inbox-check / send-flush timestamps for the Ops Emails tab.
-- Run manually on the Studio Pod Supabase project (daddiljpnhfuxcdqsulg)
-- only if public.ops_mail_status is not there yet. This repository does
-- not apply production SQL.
--
-- One row, id = 'default'. Sydney writes:
--   inbox_checked_at  after each inbox pass
--   send_flushed_at   after it finishes a queued-send flush
-- The dashboard only reads. It never sends Gmail.

create table if not exists public.ops_mail_status (
  id text primary key default 'default',
  inbox_checked_at timestamptz,
  send_flushed_at timestamptz,
  updated_at timestamptz default now()
);

insert into public.ops_mail_status (id)
values ('default')
on conflict (id) do nothing;

comment on table public.ops_mail_status is
  'Single-row mailbox heartbeat for the Ops Emails tab. Sydney writes; the dashboard reads.';

comment on column public.ops_mail_status.id is
  'Always default. One heartbeat row.';

comment on column public.ops_mail_status.inbox_checked_at is
  'Set by Sydney after it finishes an inbox pass.';

comment on column public.ops_mail_status.send_flushed_at is
  'Set by Sydney after it finishes flushing queued replies.';

alter table public.ops_mail_status enable row level security;

drop policy if exists ops_mail_status_auth_all on public.ops_mail_status;

create policy ops_mail_status_auth_all
  on public.ops_mail_status
  for all
  to authenticated
  using (is_staff())
  with check (is_staff());

revoke all on public.ops_mail_status from anon;
revoke all on public.ops_mail_status from authenticated;
grant select, insert, update on public.ops_mail_status to authenticated;
grant all on public.ops_mail_status to service_role;
