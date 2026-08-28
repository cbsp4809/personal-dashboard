-- LinkedIn content queue for the Ops Content tab.
-- Run manually on the Studio Pod Supabase project (daddiljpnhfuxcdqsulg).
-- This repository does not apply production SQL. Do not put a service-role
-- key in ops.html.
--
-- Dedicated table on purpose. public.ops_cards is the kanban + email reply
-- queue (column_key, owner, send_requested_at, reply_attachments, …).
-- LinkedIn posts have a different status machine and must not appear on the
-- board, in Emails, in Send now, or in alerts keyed to ops_cards.
--
-- Pipeline (locked):
--   1. ChatGPT writes Studio Pod LinkedIn posts in Chris's voice.
--   2. Drafts land in a shared Google Drive folder (connector separate).
--   3. Ops Content tab: Chris reviews, approves, requests changes, points
--      at / attaches a photo.
--   4. Sydney posts after Approve. Never auto-rewrite the caption.
--
-- Statuses:
--   draft → ready → needs_you → approved → scheduled → posted
--   needs_changes is the explicit "request changes" state.
--
-- Writers (service_role or a signed-in Studio Pod user) should INSERT the
-- ChatGPT caption exactly as written:
--   insert into public.ops_content
--     (title, caption, status, source, drive_url, planned_on)
--   values
--     (
--       'Short hook / title',
--       'The full ChatGPT caption, unchanged.',
--       'ready',
--       'ChatGPT',
--       'https://drive.google.com/file/d/…',
--       null
--     );
--
-- Photo bytes live in the private Storage bucket ops-content-photos.
-- Metadata lives on the row as a single jsonb object:
--   {
--     "id": "uuid",
--     "name": "booth.jpg",
--     "mime": "image/jpeg",
--     "size": 184320,
--     "path": "<content_id>/<id>/booth.jpg"
--   }
-- Optional signed_url + signed_url_expires_at (~1 hour) so Sydney can GET
-- the private file without a dashboard session. Keep the bucket private.

create table if not exists public.ops_content (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  caption text not null default '',
  status text not null default 'draft',
  planned_on date,
  source text not null default 'ChatGPT',
  drive_url text,
  photo jsonb,
  change_note text,
  created_by text,
  approved_at timestamptz,
  approved_by text,
  posted_at timestamptz,
  posted_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ops_content_status_chk'
      and conrelid = 'public.ops_content'::regclass
  ) then
    alter table public.ops_content
      add constraint ops_content_status_chk
      check (status in (
        'draft',
        'ready',
        'needs_you',
        'needs_changes',
        'approved',
        'scheduled',
        'posted'
      ));
  end if;
end
$$;

create index if not exists ops_content_status_created_idx
  on public.ops_content (status, created_at desc);

create index if not exists ops_content_planned_on_idx
  on public.ops_content (planned_on)
  where planned_on is not null;

comment on table public.ops_content is
  'Studio Pod LinkedIn review queue. Caption is ChatGPT prose; do not auto-rewrite.';

comment on column public.ops_content.title is
  'Short hook / title shown in the Content queue.';

comment on column public.ops_content.caption is
  'Full LinkedIn caption as ChatGPT wrote it. Editors may correct; the UI must not rewrite.';

comment on column public.ops_content.status is
  'draft, ready, needs_you, needs_changes, approved, scheduled, or posted.';

comment on column public.ops_content.planned_on is
  'Optional Chicago calendar date to post. Approving a future date sets scheduled.';

comment on column public.ops_content.source is
  'Where the caption came from. Defaults to ChatGPT.';

comment on column public.ops_content.drive_url is
  'Optional Google Drive file/folder link for the source draft or photo.';

comment on column public.ops_content.photo is
  'Single photo object in ops-content-photos: id, name, mime, size, path, optional signed_url.';

comment on column public.ops_content.change_note is
  'Latest note from Request changes. Left in place after the caption is edited.';

alter table public.ops_content enable row level security;

drop policy if exists ops_content_auth_all on public.ops_content;

-- Same shared-table model as ops_cards: any signed-in Studio Pod user can
-- read and write. Anon stays revoked. service_role keeps full access for Sydney.
create policy ops_content_auth_all
  on public.ops_content
  for all
  to authenticated
  using (true)
  with check (true);

revoke all on public.ops_content from anon;
revoke all on public.ops_content from authenticated;
grant select, insert, update on public.ops_content to authenticated;
grant all on public.ops_content to service_role;

insert into storage.buckets (id, name, public, file_size_limit)
values ('ops-content-photos', 'ops-content-photos', false, 26214400)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      updated_at = now();

drop policy if exists ops_content_photos_select on storage.objects;
drop policy if exists ops_content_photos_insert on storage.objects;
drop policy if exists ops_content_photos_update on storage.objects;
drop policy if exists ops_content_photos_delete on storage.objects;

create policy ops_content_photos_select
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'ops-content-photos');

create policy ops_content_photos_insert
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'ops-content-photos');

create policy ops_content_photos_update
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'ops-content-photos')
  with check (bucket_id = 'ops-content-photos');

create policy ops_content_photos_delete
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'ops-content-photos');
