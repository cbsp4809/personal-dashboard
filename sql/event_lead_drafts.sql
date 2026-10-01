-- Event follow-up drafts, for the Event Leads mode in Ops.
--
-- APPLIED 2026-10-01 to daddiljpnhfuxcdqsulg. Recorded here for the repo.
--
-- Why this is separate from cold_lead_drafts
-- ------------------------------------------
-- Event follow-up is a different source, a different cadence (40/day vs the
-- cold 25), different inclusion rules, and it carries A/B variant tags that
-- cold outreach does not.
--
-- Why it is NOT separate from event_leads
-- ---------------------------------------
-- The original spec called for creating event_leads as a new table. It already
-- exists: 2,520 people across 8 events, already served by the sales API at
-- /api/v1/event_leads and surfaced in the Studio Pod dashboard. HR Houston's
-- 180 emailable leads are already in it — 166 booth-demo with email, 14
-- met-only with email, 34 met-only without — which matches the spec exactly.
--
-- So no lead_type column is added either. booth_demo is `booth_user = true`;
-- met_only is `met and not booth_user`. That distinction is already recorded,
-- and a second source of truth for the same fact is how records drift apart.
--
-- Run manually in the Supabase SQL editor. Idempotent — safe to re-run.

create table if not exists public.event_lead_drafts (
  id             uuid primary key default gen_random_uuid(),
  event_lead_id  uuid not null references public.event_leads(id) on delete cascade,

  subject        text not null default '',
  body           text not null default '',

  -- A/B tagging. Kept through every edit so reply-rate reporting stays honest:
  -- if Chris rewrites a draft, the variant it came from is still recorded.
  variant_id     text,
  subject_family text,
  opener_family  text,
  cta_family     text,
  highlight_id   text,
  highlight      text,
  angle          text,

  status         text not null default 'proposed'
                 check (status in ('proposed','approved','sent','skipped')),
  channel        text not null default 'email' check (channel in ('email')),
  from_email     text not null default 'chris@thestudiopod.com',

  -- Two ways a draft becomes sendable, both valid:
  --   ops_edit — Chris edited or pressed Approve in Ops
  --   verbal   — he said yes on a call and Sydney marked it
  -- Nothing sends without one of them.
  approval_path  text check (approval_path in ('ops_edit','verbal')),
  approved_at    timestamptz,
  approved_by    text,
  sent_at        timestamptz,

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists event_lead_drafts_lead_idx    on public.event_lead_drafts (event_lead_id);
create index if not exists event_lead_drafts_unsent_idx  on public.event_lead_drafts (sent_at) where sent_at is null;
create index if not exists event_lead_drafts_sent_idx    on public.event_lead_drafts (sent_at desc) where sent_at is not null;
create index if not exists event_lead_drafts_variant_idx on public.event_lead_drafts (variant_id);

-- One email draft per lead. Re-importing updates rather than duplicating.
create unique index if not exists event_lead_drafts_one_email_per_lead
  on public.event_lead_drafts (event_lead_id) where channel = 'email';

alter table public.event_lead_drafts enable row level security;

drop policy if exists event_lead_drafts_staff_write on public.event_lead_drafts;
create policy event_lead_drafts_staff_write on public.event_lead_drafts
  for all to authenticated
  using (private.is_staff()) with check (private.is_staff());

-- ---- cadence columns on the existing event_leads --------------------------
-- Additive only. The sales API selects *, so these simply appear; nothing it
-- does depends on column order or count.
alter table public.event_leads
  add column if not exists assigned_day     date,
  add column if not exists cross_event_note text;

create index if not exists event_leads_assigned_day_idx
  on public.event_leads (assigned_day) where assigned_day is not null;

comment on column public.event_leads.assigned_day is
  'Chicago date this lead belongs to in the 40/day event follow-up pace. Null = not yet scheduled.';
comment on column public.event_leads.cross_event_note is
  'Multi-touch hint when someone appears at more than one event. Surfaced in Ops so the copy can say "good to see you again" — these leads are kept, never deduped away.';

comment on table public.event_lead_drafts is
  'Event follow-up email drafts with A/B variant tags. One email draft per lead. Separate from cold_lead_drafts by design; shares event_leads with Sales.';

-- Sanity checks:
--   select count(*) from public.event_lead_drafts;
--   select name, count(l.id) from public.events e
--     left join public.event_leads l on l.event_id = e.id group by name;
