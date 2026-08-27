# Personal Dashboard — Chris Bailey Photography

A single-pane-of-glass dashboard to start the day: schedule, to-dos, priority
email, goals, an AI assistant, and automated report briefs. Styled to match the
Chris Bailey Photography brand (fine-art editorial — serif wordmark, slate/navy
palette on a light-beige canvas).

A separate **Ops board** (`ops.html`) sits beside it — Chris and Sydney’s
shared work, persisted in Supabase — without replacing this morning page.

## Live site

Deploys automatically to **GitHub Pages** on every push to `main`
(see `.github/workflows/deploy.yml`). URL appears in the Action's summary once
Pages is enabled.

## Structure

```
index.html                 # morning dashboard — self-contained (HTML + CSS + JS inline)
ops.html                   # Ops board (Chris & Sydney) — separate page, same GitHub Pages site
manifest.json              # web app manifest so Ops can be added to an iPhone home screen
commodores.html            # staff-only Commodores field book (Cloudflare Access + Supabase login; not on GitHub Pages)
commodores.webmanifest     # separate home-screen app named Commodores / Dores
plays.html                 # Now-5 play animator (letters only; no roster/notes; not on GitHub Pages)
plays.webmanifest          # home-screen app named Dores Plays
icons/                     # original Ops mark plus Commodores gold-star icons (not Vanderbilt marks)
README.md
.gitignore
.github/workflows/deploy.yml   # GitHub Pages auto-deploy
sql/ops_events.sql             # Ops notify table (Sydney owns pings)
sql/ops_card_received_at.sql   # Optional source-email receipt timestamp
sql/ops_email_attachments.sql  # Email file metadata + ops-email-attachments bucket
sql/ops_mail_status.sql        # Emails-tab inbox/send heartbeat (Sydney writes)
sql/commodores_staff.sql       # Commodores comments + plans (Sydney applies)
virginias-hub/                 # Virginia's Hub planner PWA — own Cloudflare Worker, not GitHub Pages
wrangler.toml                  # personal-dashboard Worker (ignores virginias-hub/)
```

The morning dashboard stays the daily command center. Ops is a second page, not
a rewrite of `index.html`. After deploy it lives at `/ops.html` (or
`/personal-dashboard/ops.html` on the GitHub Pages project URL).

Kept as one file on purpose while it's a single page. When it grows past that,
split into `/css`, `/js`, and per-module partials.

## Ops board (`ops.html`)

A five-column board for work Chris and Sydney share:

- **Needs you** — waiting on Chris
- **Today** — the day's focus (the morning dashboard's "My Day" idea)
- **This week** — parked for the next few days
- **Later** — the long list outside this week
- **Sydney owns** — cards Sydney writes and can complete

Cards persist in Supabase table `public.ops_cards` on the same Studio Pod
project Chris already signs into (`daddiljpnhfuxcdqsulg`). Sign in with that
account (password or magic link). Do not invent extra columns; Sydney (and
anyone writing from chat/email) should insert/update rows on `ops_cards`.

Each card has a title, optional snippet, project tag (`studio-pod` / `cbp` /
`personal`), owner (`chris` / `sydney`), optional due date, and a source
(`chat` / `email` / `todo` / `calendar`). Email cards may also set
`received_at` to the source email's receipt time; the Emails view falls back to
the card's `created_at` when it is absent. Completing a card sets `done_at` /
`done_by` and moves it into the Done drawer.

For email reply cards, `snippet` is the editable reply draft. Apply the
idempotent `sql/ops_email_replies.sql`, `sql/ops_email_recipients.sql`,
`sql/ops_send_now.sql`, and `sql/ops_email_attachments.sql` manually before
using the queue and file flow.
The inbox watch should populate `inbound_from`, `inbound_subject`,
`inbound_to`, `inbound_cc`, `inbound_body` (plain text),
`inbound_message_id`, and `inbound_account` (the Chris-owned receiving
address). Replies default to reply-all while excluding `inbound_account`; Chris
can switch to sender-only and edit To / Cc / Bcc. The dashboard autosaves
`reply_all`, `reply_to`, `reply_cc`, and `reply_bcc`. Clicking **Send** saves
those exact recipients with the draft, asks for confirmation, and sets
`send_requested_at` / `send_requested_by`; it does not send Gmail or mark the
card done. Sydney's inbox watch owns the actual send and completion. Queued
cards collapse to a compact row; **Cancel** clears only the two queue fields,
leaving the draft and recipient choices ready to edit. Apply
`sql/ops_email_attachments.sql` for file support. Incoming files belong in
`inbound_attachments` and the private `ops-email-attachments` bucket when
Sydney creates or updates the card — the Incoming panel lists them so Chris
can open or download them without leaving Ops. On Reply, Chris can attach
PDF, images, and typical office docs; the page uploads them immediately and
saves `reply_attachments` with a ~1 hour `signed_url` so Sydney can GET the
private file without a dashboard login. Send and Send now remint those URLs
and still only queue the card. The bucket stays private. Do not add Google
Drive. Sydney GETs `signed_url` and attaches those bytes to the Gmail reply. The
current dashboard treats `project` as the inbox label. `source_ref` is
available to the watch alongside `inbound_message_id`, but this repository
does not establish which Gmail identifier existing producers store there.

The Emails top bar counts all open cards with `send_requested_at` and offers
**Send now**. A short status line shows the last inbox pass from
`public.ops_mail_status` (`id='default'`, `inbox_checked_at`) and, when
anything is queued, how long those live `ops_cards` have been waiting
(`send_requested_at` set, `done_at` null). Apply `sql/ops_mail_status.sql`
only if that table is not there yet. One tap inserts a pending `ops_send_now`
row — there is no second confirm. The big control shows **Send N** when cards
are already queued, **Sending N…** while the flush is out, then **Sent N**
after Sydney sets `processed_at` and those cards have `done_at`, and returns
to **Send now** after a few seconds. If nothing was queued it flashes
**Nothing queued**. The Emails tab polls `ops_send_now`, `ops_mail_status`,
and queued cards about every 20 seconds, the same cadence as the live alert
badge, so the status clears without a reload. The dashboard does not send
Gmail. A unique partial index keeps only one flush request pending at a time.

If those email columns have not been applied yet, Ops retries its legacy
`ops_cards` select so the page still loads. Sending remains disabled until the
queue columns exist. Attach and inbound-file open stay disabled until the
attachment columns and storage bucket exist.

The top Chris / Sydney toggle changes whose work is prioritized. Chris sees
Needs you, Today, This week, and Later before a quiet Sydney owns column.
Sydney sees Sydney owns first, then cards assigned to her in other columns.

Intake is a sticky chat-style composer at the bottom. It loosely recognizes
owner, project, and timeline words in a dictated or typed sentence, then shows
what it parsed. Unsaid values default to the current person, Unfiled, and Today
(Chris) or Sydney owns (Sydney). The standard iOS keyboard dictation works in
the text field; browsers with Web Speech also get direct microphone input.

Each card has a one-tap star for **Needs you**. Starring a card moves it to the
top of Needs you; unstarring it moves it to Today. The card column dropdown
stays.

Cards can be dragged to an exact position within or between columns on desktop.
On iPhone and other touch devices, press and hold the card body, then drag it
into place; short taps and normal scrolling do not activate the drag. Stack
positions persist in the existing `ops_cards.sort` field. The live table already
has that field and its `(column_key, sort)` index; `sql/ops_card_order.sql` is an
idempotent setup/backfill script for another environment.

Landing a card on **Sydney owns** (create, drag, or dropdown — not owner-only
changes) writes `ops_events` (`event = moved_to_sydney`) so Sydney can poll
without a webhook secret in the page. Apply `sql/ops_events.sql` on the Studio
Pod project if that table is not there yet.

**Import To Do** reuses the Microsoft MSAL client already on `index.html`. On
the live GitHub Pages origin it imports open tasks as cards. Off that origin
it shows a clear "connect To Do" state instead of faking a sync.

If a magic-link email does not return to this page, add
`https://cbsp4809.github.io/personal-dashboard/ops.html` to the Supabase Auth
redirect allow-list (password sign-in works without that).

## Add Ops to an iPhone home screen

Ops is a Safari web app, not an App Store download. Live URL:

**https://cbsp4809.github.io/personal-dashboard/ops.html**

On Chris’s iPhone:

1. Open that link in **Safari** (Chrome and other browsers cannot add it the same way).
2. Tap the **Share** button (the square with the arrow).
3. Tap **Add to Home Screen**, name it Ops if asked, then **Add**.

The home-screen icon opens the board full-screen, like an app. Sign-in uses the
same Studio Pod account and stays on the phone (the session is already saved in
the browser). After you add it, tapping the icon should land on Ops — not the
morning dashboard.

## Add Commodores to an iPhone home screen

The staff field book is its own Safari web app, separate from Ops. It is **not**
on the public GitHub Pages site (`deploy.yml` strips `commodores.html` and
`commodores.webmanifest`). Live URL:

**https://personal-dashboard.chrisbailey.workers.dev/commodores.html**

Play animator (letters only, no staff roster or notes):

**https://personal-dashboard.chrisbailey.workers.dev/plays.html**

Cloudflare Access (coach email one-time PIN) sits in front; the page then uses
Supabase Auth email+password on the dedicated Commodores project
(`adjnmtpjoyxvmlogjjpz`), with `storageKey: "commodores-auth"`. Roster loads
from `commodores_roster` after sign-in. First names only.

Primary pages: **Today**, **Playbook**, **Lineup**, **Practice**. Season board
is a reference link (schedule, milestones, goals). Playbook has Offense /
Defense sub-tabs.

On Chris’s iPhone:

1. Open that link in **Safari** (Chrome and other browsers cannot add it the same way).
2. Tap the **Share** button (the square with the arrow).
3. Tap **Add to Home Screen**. The name should be **Commodores** (short name **Dores**).
4. Tap **Add**.

The gold-star icon is an original mark (not a Vanderbilt or Commodores logo). It
opens the sign-in gate full-screen and does not share the Ops home-screen name
or icon. This page is intentionally not linked from the morning dashboard or Ops.

The page never uses a service-role key and it does not read or write `ops_cards`
or `ops_alerts`.

## Ops alerts

Run `sql/ops_alerts.sql` manually on Studio Pod before using the alert bell. It
creates the RLS-protected alert table and enables Supabase Realtime for it. The
web page never uses a service-role key.

Signed-in browser code can insert an alert without `user_id`; it defaults to the
current user. Server-side inbox/Sydney writers must set `user_id` to Chris's
Supabase Auth user ID. One `ops_alerts` insert is the complete integration:
`title`, `body`, `kind`, and optional `href` or `card_id`.

Opening the bell is the one-time user gesture that requests notification
permission. While Ops is open, new rows update the in-app count, Home Screen or
Dock badge where `setAppBadge` is supported, and show a system notification
where allowed. The included service worker supports foreground notifications
and notification clicks; it does not implement remote Web Push. Consequently,
alerts do not reliably arrive on an iPhone lock screen after the GitHub Pages
PWA has been closed. That requires a push subscription store, VAPID keys, and a
trusted server-side sender.

## Local preview

Just open `index.html` in a browser, or serve it:

```bash
python3 -m http.server 8000   # then visit http://localhost:8000
```

## What works today

- **Daily Command Center** — live clock/greeting, today's agenda, Business /
  Personal to-dos (add, check, delete), priority inbox with draft-reply
  shortcuts, Goal Focus + a gratitude note.
- **Assistant** — talk-or-type box; understands `add to-do:` /
  `add personal to-do:` commands directly, and answers/drafts via Claude when
  run inside Cowork.
- **Automated Reports** — on-demand briefs (e.g. photo-booth market pulse).
- To-dos, goals, and gratitude **persist in the browser** (localStorage).
- **Ops board** (`ops.html`) — shared Chris/Sydney columns stored in
  `ops_cards` on the Studio Pod Supabase project. Linked from the masthead.

## Roadmap — making it live

The agenda, inbox, and any financial figures currently show sample data with
"connect" prompts. To go live, wire each to a data source:

- **Calendar** — Google / Apple Calendar → real agenda
- **Email** — Gmail / Outlook → real priority inbox + AI-drafted replies
- **Finance** — brokerage / cards / Digits → stocks, balances, due dates
- **Family Hub** — kids' section, school-email parser, family photo stream
- **Assistant execution** — tie to Claude on the studio Mac mini for real task
  actions (scheduling, calendar edits)

## Notes

This dashboard is the canonical source going forward — edits land here and ship
via Pages, rather than being regenerated from scratch.
