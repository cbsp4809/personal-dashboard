-- Traffic-light monitors for Ops Personal Home. Run manually on Studio Pod
-- (daddiljpnhfuxcdqsulg). This repository does not apply production SQL.
-- Sydney routines own status calculation and upsert rows; ops.html only reads.
--
-- Shared-table access matches sql/ops_home.sql: signed-in Studio Pod users
-- can read and write, anon stays revoked, and service_role retains full access
-- for Sydney's routines.

create table if not exists public.ops_home_monitors (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  label text not null,
  status text not null check (status in ('green', 'orange', 'red')),
  summary text,
  note text,
  detail jsonb,
  checked_at timestamptz,
  updated_at timestamptz default now()
);

comment on table public.ops_home_monitors is
  'Traffic-light health checks shown on Ops Personal Home. External routines calculate and upsert status.';

comment on column public.ops_home_monitors.key is
  'Stable machine key used by Sydney routines when upserting a monitor.';

comment on column public.ops_home_monitors.status is
  'Display status supplied by the writer: green, orange, or red. The browser does not calculate it.';

comment on column public.ops_home_monitors.detail is
  'Optional machine-readable monitor metadata, thresholds, and source details.';

comment on column public.ops_home_monitors.checked_at is
  'When the source was last checked. Displayed in America/Chicago by Ops Home.';

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
  'Backup is more than 14 days stale.',
  'Last Box update May 12 — check Cloud Sync on the NAS. Mirror folders: CULL_RAW, PhotoLibrary05/Lightroom.',
  jsonb_build_object(
    'last_box_update', '2026-05-12',
    'mirror_folders', jsonb_build_array('CULL_RAW', 'PhotoLibrary05/Lightroom'),
    'freshness_rules', jsonb_build_object(
      'green', 'Newest Box update within 7 days',
      'orange', '8–14 days old or recent folders are incomplete',
      'red', 'More than 14 days stale or stalled'
    )
  ),
  '2026-09-02 13:23:00-05',
  now()
)
on conflict (key) do update set
  label = excluded.label,
  status = excluded.status,
  summary = excluded.summary,
  note = excluded.note,
  detail = excluded.detail,
  checked_at = excluded.checked_at,
  updated_at = now();
