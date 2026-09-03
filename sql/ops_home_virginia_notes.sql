-- Queue for notes Chris writes to Virginia from Ops Home. Run manually on
-- Studio Pod (daddiljpnhfuxcdqsulg). This repository does not apply
-- production SQL.
--
-- Ops only saves the queue row. A separate trusted Sydney/Hub routine must
-- merge-add the note into Virginia's Netlify Database payload, preserving all
-- existing notes, folders, and homework. After a successful push it sets
-- sent_at and hub_note_id; on failure it sets send_error.

create table if not exists public.ops_home_virginia_notes (
  id uuid primary key default gen_random_uuid(),
  body text not null,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  send_error text,
  hub_note_id text
);

create index if not exists ops_home_virginia_notes_created_idx
  on public.ops_home_virginia_notes (created_at desc);

create index if not exists ops_home_virginia_notes_waiting_idx
  on public.ops_home_virginia_notes (created_at)
  where sent_at is null and send_error is null;

comment on table public.ops_home_virginia_notes is
  'Notes Chris queues for merge-add delivery to Virginia''s Hub. Ops never writes the Hub payload directly.';

comment on column public.ops_home_virginia_notes.sent_at is
  'Set only after a trusted routine has merge-added the note to Virginia''s Hub payload.';

comment on column public.ops_home_virginia_notes.send_error is
  'Last Hub push error. Keep sent_at null until delivery succeeds.';

comment on column public.ops_home_virginia_notes.hub_note_id is
  'Identifier returned or assigned by the Hub delivery routine for deduplication.';

alter table public.ops_home_virginia_notes enable row level security;

drop policy if exists ops_home_virginia_notes_select on public.ops_home_virginia_notes;
drop policy if exists ops_home_virginia_notes_insert on public.ops_home_virginia_notes;
drop policy if exists ops_home_virginia_notes_update on public.ops_home_virginia_notes;

create policy ops_home_virginia_notes_select
  on public.ops_home_virginia_notes
  for select
  to authenticated
  using (true);

create policy ops_home_virginia_notes_insert
  on public.ops_home_virginia_notes
  for insert
  to authenticated
  with check (true);

create policy ops_home_virginia_notes_update
  on public.ops_home_virginia_notes
  for update
  to authenticated
  using (true)
  with check (true);

revoke all on public.ops_home_virginia_notes from public;
revoke all on public.ops_home_virginia_notes from anon;
revoke all on public.ops_home_virginia_notes from authenticated;
grant select, insert, update on public.ops_home_virginia_notes to authenticated;
grant all on public.ops_home_virginia_notes to service_role;
