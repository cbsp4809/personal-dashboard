-- Ops Home health monitors. Run manually on Studio Pod
-- (daddiljpnhfuxcdqsulg). This repository does not apply production SQL.
--
-- Sydney and routine writers update these rows after checking each system.
-- Status rules for Synology -> Box: green within 7 days, orange at 8-14
-- days or partially incomplete, red after 14 days or clearly stalled.

create table if not exists public.ops_home_monitors (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  status text not null check (status in ('green', 'orange', 'red')),
  summary text not null,
  note text,
  detail jsonb,
  checked_at timestamptz not null,
  updated_at timestamptz not null default now()
);

comment on table public.ops_home_monitors is
  'Current health checks shown in the reusable Monitor block on Ops Home.';

comment on column public.ops_home_monitors.note is
  'Short explanation and next action for orange or red monitors.';

comment on column public.ops_home_monitors.detail is
  'Optional machine-readable evidence used by the routine that refreshed the monitor.';

alter table public.ops_home_monitors enable row level security;

drop policy if exists ops_home_monitors_select on public.ops_home_monitors;
drop policy if exists ops_home_monitors_insert on public.ops_home_monitors;
drop policy if exists ops_home_monitors_update on public.ops_home_monitors;

create policy ops_home_monitors_select
  on public.ops_home_monitors
  for select
  to authenticated
  using (true);

create policy ops_home_monitors_insert
  on public.ops_home_monitors
  for insert
  to authenticated
  with check (true);

create policy ops_home_monitors_update
  on public.ops_home_monitors
  for update
  to authenticated
  using (true)
  with check (true);

revoke all on public.ops_home_monitors from public;
revoke all on public.ops_home_monitors from anon;
revoke all on public.ops_home_monitors from authenticated;
grant select, insert, update on public.ops_home_monitors to authenticated;
grant all on public.ops_home_monitors to service_role;

insert into public.ops_home_monitors (
  key,
  label,
  status,
  summary,
  note,
  detail,
  checked_at,
  updated_at
) values (
  'box_synology_backups',
  'Synology → Box backups',
  'red',
  'No Box updates since May 12, 2026.',
  'Last Box update May 12 — check Cloud Sync on NAS (CULL_RAW + PhotoLibrary05/Lightroom).',
  '{"mirror":"_BackUps","last_box_activity":"2026-05-12","folders":["CULL_RAW","PhotoLibrary05/Lightroom"],"reason":"stale_over_14_days"}'::jsonb,
  '2026-09-02 13:20:00-05'::timestamptz,
  '2026-09-02 13:20:00-05'::timestamptz
)
on conflict (key) do nothing;
