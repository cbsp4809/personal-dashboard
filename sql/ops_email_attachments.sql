-- Inbound and outbound email attachments for Ops cards.
-- Run manually on the Studio Pod Supabase project (daddiljpnhfuxcdqsulg).
-- This repository does not apply production SQL. Do not put a service-role
-- key in ops.html.
--
-- Files live in the private Storage bucket ops-email-attachments.
-- Metadata lives on the existing public.ops_cards row as jsonb arrays.
-- Do not create a second database.
--
-- Each array item:
--   {
--     "id": "uuid",
--     "name": "Estimate.pdf",
--     "mime": "application/pdf",
--     "size": 184320,
--     "path": "<card_id>/inbound/<id>/Estimate.pdf"
--   }
-- Optional inbound-only key: "gmail_id" (Gmail attachment id, for Sydney).
-- Prefer "path" over a temporary signed URL. The dashboard signs paths with
-- the signed-in Studio Pod session.
--
-- Paths:
--   inbound: <card_id>/inbound/<id>/<safe-filename>
--   reply:   <card_id>/reply/<id>/<safe-filename>
--
-- Sydney — inbound (when creating or updating a source=email card):
--   1. Download each Gmail attachment.
--   2. Upload bytes to ops-email-attachments at the inbound path above.
--   3. Set ops_cards.inbound_attachments to the metadata array.
--   Chris should not have to leave Ops or re-paste the file.
--
-- Sydney — outbound (when send_requested_at is set, or after ops_send_now):
--   1. Read ops_cards.reply_attachments.
--   2. Download each path from ops-email-attachments.
--   3. Attach those bytes to the Gmail reply.
--   4. Then send and complete the card as today.
--
-- Example metadata write (service_role or a signed-in Studio Pod user):
--   update public.ops_cards
--     set inbound_attachments = '[
--       {
--         "id": "11111111-1111-1111-1111-111111111111",
--         "name": "Estimate.pdf",
--         "mime": "application/pdf",
--         "size": 184320,
--         "path": "00000000-0000-0000-0000-000000000000/inbound/11111111-1111-1111-1111-111111111111/Estimate.pdf",
--         "gmail_id": "ANGjdJ8example"
--       }
--     ]'::jsonb,
--         updated_at = now()
--   where id = '00000000-0000-0000-0000-000000000000';

alter table public.ops_cards
  add column if not exists inbound_attachments jsonb,
  add column if not exists reply_attachments jsonb;

comment on column public.ops_cards.inbound_attachments is
  'jsonb array of sender files stored in the ops-email-attachments bucket. Each item has id, name, mime, size, path, and optional gmail_id.';

comment on column public.ops_cards.reply_attachments is
  'jsonb array of files Chris attached for Sydney to send with the Gmail reply. Same item shape as inbound_attachments.';

insert into storage.buckets (id, name, public, file_size_limit)
values ('ops-email-attachments', 'ops-email-attachments', false, 26214400)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      updated_at = now();

drop policy if exists ops_email_attachments_select on storage.objects;
drop policy if exists ops_email_attachments_insert on storage.objects;
drop policy if exists ops_email_attachments_update on storage.objects;
drop policy if exists ops_email_attachments_delete on storage.objects;

-- Same shared-table model as ops_cards: any signed-in Studio Pod user can
-- read and write. Anon stays out. service_role bypasses RLS for Sydney.
create policy ops_email_attachments_select
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'ops-email-attachments');

create policy ops_email_attachments_insert
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'ops-email-attachments');

create policy ops_email_attachments_update
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'ops-email-attachments')
  with check (bucket_id = 'ops-email-attachments');

create policy ops_email_attachments_delete
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'ops-email-attachments');
