-- Flush signal for Sydney's inbox watch. The dashboard inserts a request but
-- never sends Gmail itself. Run manually on the Studio Pod Supabase project;
-- this repository does not apply production SQL.

create table if not exists public.ops_send_now (
  id uuid primary key default gen_random_uuid(),
  requested_at timestamptz not null default now(),
  requested_by text not null,
  queued_count integer not null check (queued_count >= 0),
  processed_at timestamptz
);

create unique index if not exists ops_send_now_one_pending_idx
  on public.ops_send_now ((true))
  where processed_at is null;

alter table public.ops_send_now enable row level security;

drop policy if exists ops_send_now_auth_select on public.ops_send_now;
drop policy if exists ops_send_now_auth_insert on public.ops_send_now;

create policy ops_send_now_auth_select
  on public.ops_send_now
  for select
  to authenticated
  using (true);

create policy ops_send_now_auth_insert
  on public.ops_send_now
  for insert
  to authenticated
  with check (requested_by = 'chris' and processed_at is null);

revoke all on public.ops_send_now from anon;
revoke all on public.ops_send_now from authenticated;
grant select, insert (requested_by, queued_count) on public.ops_send_now to authenticated;
grant all on public.ops_send_now to service_role;

comment on table public.ops_send_now is
  'Pending rows tell Sydney to promptly flush all queued Ops email replies.';

comment on column public.ops_send_now.processed_at is
  'Set by Sydney after it has handled this flush request.';
