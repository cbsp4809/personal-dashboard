-- Published Commodores play snapshots for the watch-only kids/parents page.
-- Run manually on the Commodores project only (adjnmtpjoyxvmlogjjpz).
-- Do not run on Studio Pod (daddiljpnhfuxcdqsulg) or CBP.
--
-- Idempotent. Coaches keep full play/share access through the existing
-- commodores_is_coach() allowlist. Anonymous visitors cannot select either
-- table; they can only call commodores_watch_plays() with the 256-bit token.

alter table public.commodores_plays
  add column if not exists published boolean not null default false;

comment on column public.commodores_plays.published is
  'Included in the next kids/parents watch snapshot when true.';

create table if not exists public.commodores_play_shares (
  id text primary key default 'current',
  token text not null,
  snapshot jsonb not null default '{"plays":[],"lineups":{}}'::jsonb,
  published_at timestamptz not null default now(),
  updated_by text,
  constraint commodores_play_shares_singleton check (id = 'current'),
  constraint commodores_play_shares_token_length check (length(token) >= 43),
  constraint commodores_play_shares_snapshot_object
    check (jsonb_typeof(snapshot) = 'object')
);

comment on table public.commodores_play_shares is
  'Coach-owned bearer token and read-only published play snapshot. Never grant anon table SELECT.';
comment on column public.commodores_play_shares.snapshot is
  'Published plays plus Q1/Q3 and Q2/Q4 runner labels captured at publish time (internal keys remain A/B).';

alter table public.commodores_play_shares enable row level security;

drop policy if exists commodores_play_shares_read on public.commodores_play_shares;
drop policy if exists commodores_play_shares_insert on public.commodores_play_shares;
drop policy if exists commodores_play_shares_update on public.commodores_play_shares;
drop policy if exists commodores_play_shares_delete on public.commodores_play_shares;

create policy commodores_play_shares_read
  on public.commodores_play_shares
  for select
  to authenticated
  using (public.commodores_is_coach());

create policy commodores_play_shares_insert
  on public.commodores_play_shares
  for insert
  to authenticated
  with check (public.commodores_is_coach());

create policy commodores_play_shares_update
  on public.commodores_play_shares
  for update
  to authenticated
  using (public.commodores_is_coach())
  with check (public.commodores_is_coach());

create policy commodores_play_shares_delete
  on public.commodores_play_shares
  for delete
  to authenticated
  using (public.commodores_is_coach());

revoke all on public.commodores_play_shares from anon;
revoke all on public.commodores_play_shares from authenticated;
grant select, insert, update, delete on public.commodores_play_shares to authenticated;
grant all on public.commodores_play_shares to service_role;

-- This is the sole anonymous read surface. It returns one pre-built snapshot
-- only when the caller knows the full token. Explicit schema qualification and
-- an empty search_path keep the SECURITY DEFINER body from resolving attacker-
-- controlled objects. The token is compared as a SHA-256 digest.
create or replace function public.commodores_watch_plays(p_token text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select share.snapshot
  from public.commodores_play_shares as share
  where length(coalesce(p_token, '')) >= 43
    and extensions.digest(share.token, 'sha256')
      = extensions.digest(p_token, 'sha256')
  limit 1
$$;

revoke all on function public.commodores_watch_plays(text) from public;
revoke all on function public.commodores_watch_plays(text) from authenticated;
grant execute on function public.commodores_watch_plays(text) to anon;

comment on function public.commodores_watch_plays(text) is
  'Returns only the current published watch snapshot for an exact unguessable token.';
