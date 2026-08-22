-- Ops alerts. Run manually on Studio Pod (daddiljpnhfuxcdqsulg).
-- Do not put a service-role key in ops.html. Server-side writers must provide
-- Chris's auth.users.id as user_id; signed-in browser inserts default to auth.uid().

create table if not exists public.ops_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  kind text not null default 'general',
  href text,
  card_id uuid references public.ops_cards(id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists ops_alerts_user_created_at_idx
  on public.ops_alerts (user_id, created_at desc);

create index if not exists ops_alerts_user_unread_idx
  on public.ops_alerts (user_id, created_at desc)
  where read_at is null;

alter table public.ops_alerts enable row level security;

drop policy if exists ops_alerts_own_select on public.ops_alerts;
drop policy if exists ops_alerts_own_insert on public.ops_alerts;
drop policy if exists ops_alerts_own_update on public.ops_alerts;

create policy ops_alerts_own_select
  on public.ops_alerts
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy ops_alerts_own_insert
  on public.ops_alerts
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- UPDATE also needs the SELECT policy above. The column-level grant below means
-- browser clients can acknowledge an alert but cannot rewrite its content/owner.
create policy ops_alerts_own_update
  on public.ops_alerts
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.ops_alerts from anon;
revoke all on public.ops_alerts from authenticated;
grant select, insert on public.ops_alerts to authenticated;
grant update (read_at) on public.ops_alerts to authenticated;
grant all on public.ops_alerts to service_role;

-- Postgres Changes only streams tables in this publication. Keep this rerunnable.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'ops_alerts'
  ) then
    alter publication supabase_realtime add table public.ops_alerts;
  end if;
end
$$;
