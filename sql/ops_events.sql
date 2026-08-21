-- Ops notify log. Run on the Studio Pod project (daddiljpnhfuxcdqsulg).
-- Signed-in Studio Pod users can insert and select. No secrets in ops.html.

create table if not exists public.ops_events (
  id uuid primary key default gen_random_uuid(),
  card_id uuid references public.ops_cards(id) on delete set null,
  event text not null,
  created_at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb
);

create index if not exists ops_events_created_at_idx on public.ops_events (created_at desc);
create index if not exists ops_events_event_idx on public.ops_events (event);

alter table public.ops_events enable row level security;

drop policy if exists ops_events_auth_select on public.ops_events;
drop policy if exists ops_events_auth_insert on public.ops_events;

create policy ops_events_auth_select
  on public.ops_events
  for select
  to authenticated
  using (true);

create policy ops_events_auth_insert
  on public.ops_events
  for insert
  to authenticated
  with check (true);

grant select, insert on public.ops_events to authenticated;
revoke all on public.ops_events from anon;
