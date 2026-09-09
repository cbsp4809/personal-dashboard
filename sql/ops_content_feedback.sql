-- Chris's revision feedback on a Content card, kept separate from change_note.
--
-- change_note is Sydney's staging field — she writes what she did when putting a
-- draft up. Overwriting it with Chris's "too long, cut 30%" lost her notes and
-- made it impossible to tell whose text you were reading. These columns give
-- Chris's ask its own home, so both survive and the revision brief is
-- unambiguous.
--
-- Run manually in the Supabase SQL editor; this repository does not apply SQL.
-- After running, check the Supabase security and performance advisors.
-- Idempotent — safe to re-run.

alter table public.ops_content
  add column if not exists feedback_note text,
  add column if not exists feedback_at   timestamptz,
  add column if not exists feedback_by   text;

comment on column public.ops_content.feedback_note is
  'Chris''s revision ask, captured when he sets status to needs_changes. Never written by Sydney''s staging flow — that is change_note.';

comment on column public.ops_content.feedback_at is
  'When the feedback above was given. Survives a restage so the last ask stays visible as context.';

comment on column public.ops_content.feedback_by is
  'Who gave the feedback, so a future second reviewer is attributable.';

-- No RLS change: ops_content already carries its own staff-only policies and
-- these columns inherit them. Adding columns does not widen access.
