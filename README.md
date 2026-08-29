# Personal Dashboard — Chris Bailey Photography

A single-pane-of-glass dashboard to start the day: schedule, to-dos, priority
email, goals, an AI assistant, and automated report briefs. Styled to match the
Chris Bailey Photography brand (fine-art editorial — serif wordmark, slate/navy
palette on a light-beige canvas).

A separate **Ops board** (`ops.html`) sits beside it — Chris and Sydney’s
shared work, persisted in Supabase — without replacing this morning page.

## Live site

Pushing to `main` deploys **two** places:

- **GitHub Pages** (`cbsp4809.github.io/personal-dashboard/`) — public morning
  dashboard + Ops. `deploy.yml` strips `commodores.html`, `plays.html`,
  `watch.html`, `reset.html`, and the coach manifests so the Commodores
  workflow stays off the public site.
- **Cloudflare Worker** `personal-dashboard` —
  **https://personal-dashboard.chrisbailey.workers.dev/** — serves the whole
  repo, including Commodores, Plays, and the living coach manual at
  `/coach-manual.html`. Cloudflare Git runs
  `npx wrangler versions upload` from the repo root. The root `wrangler.toml`
  (static `[assets]`, no Worker `main`) is what stops the
  **Missing entry-point** build failure. Do not add Cloudflare Access back.

## Structure

```
index.html                 # morning dashboard — self-contained (HTML + CSS + JS inline)
ops.html                   # Ops board (Chris & Sydney) — separate page, same GitHub Pages site
manifest.json              # web app manifest so Ops can be added to an iPhone home screen
commodores.html            # staff-only Commodores field book (Supabase login; not on GitHub Pages)
commodores.webmanifest     # separate home-screen app named Commodores / Dores
plays.html                 # Play animator + coach draw/save editor (letters only; not on GitHub Pages)
plays.webmanifest          # home-screen app named Dores Plays
reset.html                 # coach password reset / set-new-password (Worker only)
watch.html                 # token-only kids/parents published-play viewer (Worker only)
coach-manual.html          # living staff user manual (Worker: /coach-manual.html)
wrangler.toml              # Cloudflare Worker `personal-dashboard` static-asset entry (fixes Missing entry-point)
.assetsignore              # keep Worker deploy to site files (no .git / sql / markdown)
icons/                     # CB Ops wordmark plus Commodores gold-star icons (not Vanderbilt marks)
README.md
.gitignore
.github/workflows/deploy.yml   # GitHub Pages auto-deploy
sql/ops_events.sql             # Ops notify table (Sydney owns pings)
sql/ops_card_received_at.sql   # Optional source-email receipt timestamp
sql/ops_email_attachments.sql  # Email file metadata + ops-email-attachments bucket
sql/ops_mail_status.sql        # Emails-tab inbox/send heartbeat (Sydney writes)
sql/ops_email_kind.sql         # Emails-tab sales/lead flag (Sydney applies)
sql/ops_content.sql            # LinkedIn Content tab queue + ops-content-photos bucket
sql/commodores_staff.sql       # Commodores comments + plans (Sydney applies)
sql/commodores_league_schedule.sql  # SBMSA JV Maxwell slate on commodores_plans (Commodores project only)
sql/commodores_plays.sql       # Drawn play routes (Commodores project only; coaches via RLS)
sql/commodores_play_sharing.sql # Published snapshots + token-only watch RPC (Commodores project only)
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
account (password or magic link). Sydney (and anyone writing from chat/email)
should insert/update rows on `ops_cards` using the columns documented here.

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
current dashboard treats `project` as the inbox label. `email_kind` is
`sales`, `lead`, or `other` so the Emails list can badge and filter pipeline
mail. Apply `sql/ops_email_kind.sql` so the flag persists; until then the
page still badges from title / subject / inbound body. Inbox watch should
set `email_kind` on create when it already knows the kind. `source_ref` is
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

**Content** is a fifth top-bar view for the Studio Pod LinkedIn pipeline.
ChatGPT writes the caption; a Drive folder (connector separate) is where
drafts land; this tab is where Chris reviews, approves, requests changes, and
attaches or points at a photo; Sydney posts after Approve. The page never
auto-rewrites ChatGPT prose.

Rows live in `public.ops_content`, not `ops_cards`. Cards already own the
kanban plus the email reply queue (`column_key`, `send_requested_at`,
attachments). A LinkedIn status machine (Draft → Ready → Needs you →
Needs changes → Approved → Scheduled → Posted) would leak into the board,
Emails, alerts, and Send now if it reused that table. Apply
`sql/ops_content.sql` manually on Studio Pod before using the tab. Photos use
the private `ops-content-photos` bucket with the same signed-in / signed-URL
pattern as email attachments. An optional Drive URL is a pointer only.

A collapsible **Help** cheat sheet sits at the top of this tab (collapsed
by default) so Chris can recall the status path, his review steps, Sydney/PR
handoff, and the Tue 11 / Wed 3 / Thu 1 CT cadence.

Each item shows a hook, the full editable caption, status, optional planned
date, a photo thumbnail or “no photo”, and a source that defaults to
ChatGPT. Actions: Approve, Request changes (note), Save caption, Attach /
replace photo, Mark posted, Ready for Chris. New draft pastes a caption as
written. The tab does not post to LinkedIn.

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
3. Tap **Add to Home Screen**, name it **CB Ops** if asked, then **Add**.

The home-screen icon opens the board full-screen, like an app. Sign-in uses the
same Studio Pod account and stays on the phone (the session is already saved in
the browser). After you add it, tapping the icon should land on Ops — not the
morning dashboard.

## Add Commodores to an iPhone home screen

The staff field book is its own Safari web app, separate from Ops. It is **not**
on the public GitHub Pages site (`deploy.yml` strips `commodores.html` and
`commodores.webmanifest`). Live URL:

**https://personal-dashboard.chrisbailey.workers.dev/commodores.html**

The field book now has a **Plays** tab containing the animator + draw editor:

**https://personal-dashboard.chrisbailey.workers.dev/plays.html**

Staff user manual (same Worker origin):

**https://personal-dashboard.chrisbailey.workers.dev/coach-manual.html**

The field-book login and a post-login Help control open that page. It is staff
only: install, sign-in, the five tabs, play publish, and troubleshooting. No
passwords.

Direct access to `plays.html` uses the same coach allowlist gate; unsigned
visitors cannot open the editor. The offense book starts empty and lists only
coach-saved `commodores_plays` rows; no numbered routes are seeded in the page
or recreated in Supabase. Play mode: tap a saved play, then Play / Pause /
scrub / Flip / Reset or open the immersive full-screen field. Full-screen
Play keeps Done / Play / the speed row / scrubber, and shows the play name
in gold/soft type (the title, or **Play 12** when there is only a number).
A small **0.5× / 1× / 2×** speed row sits under those controls (default
**0.5×** so kids can see the routes); the choice is kept in localStorage.
The kids watch page uses the same speeds.
Full-screen Play is a CSS overlay sized from the visual viewport, not the
browser fullscreen API, so an iPad can rotate between landscape and portrait.
Draw mode: drag the seven letter dots to set starts, tap a letter and finger-
draw its route, Sit for no route, Save with a number and short title. Only the
field captures touch while drawing, so the rest of the phone/iPad page keeps
normal vertical scrolling. Flip is a true left/right mirror of the saved
geometry. New-play dots start slightly behind the line of scrimmage. Route
lines end with a small arrowhead at the tip. The field shows 10-yard stripes
as visual markers only. The optional six-areas overlay (no rush) places the
three short spots about five yards off the LOS, the three deep spots behind
them, and the rover as a deep-middle helper. The canvas is 480×400 (was
360×400) with tighter name pills so a 5-wide can spread without stacking
labels; legacy 360-wide drawings scale on load. The kids watch page uses the
same field, arrow, and width drawing. Same Commodores Supabase project
(`adjnmtpjoyxvmlogjjpz`) and `storageKey: "commodores-auth"` as the field book,
so a coach already signed in there is signed in here. Saved plays live in
`commodores_plays` (RLS: allowlisted coaches only). Apply
`sql/commodores_plays.sql` on the Commodores project if the table is missing,
then `sql/commodores_play_sharing.sql` for publishing.
localStorage keeps an offline draft; the database wins when signed in.

Play labels come from the current offense lineup in this fixed order:
`Q, C, X, A, B, Y, Z` (Q and Center, then the five receiver spots). Coaches
choose Unit A or B. Empty spots fall back to the letter. Each letter has a
fixed color used for the name pill, the route line, and the tip arrow
(`POSITION_COLOR` in `plays.html`, mirrored in `watch.html` and
`commodores.html`): Q white, C gold, X sky, A sand-orange, B mint, Y lilac,
Z salmon. Selected / live-drawing strokes get thicker but keep that hue.
Yard lines, LOS, and the defense overlay stay gold/white as before.

Each saved play has a Publish toggle. Publishing writes one read-only snapshot
containing all marked plays and both units' first-name maps, then shows a
256-bit secret URL:

`https://personal-dashboard.chrisbailey.workers.dev/watch.html?t=<secret>`

The watch page has no login, coach navigation, roster, editor, notes, save, or
publish controls. Kids see a stacked list of published plays, tap one, then
get the play number above the field plus Play / full screen / scrub. Full
screen shows the play display name the same way the coach animator does.
Anonymous clients cannot select play/share tables; a narrow
RPC returns only the published snapshot for the exact token. After lineup or
route changes, tap **Republish names + plays**. Rotating the link invalidates
the old URL.

Do not put Cloudflare Access back in front of this Worker. The field book still
uses Supabase Auth email+password. Roster loads from `commodores_roster` after
sign-in. First names only.

Coaches reset their own password from **Forgot password?** on
`commodores.html` or `plays.html`. That calls `resetPasswordForEmail` with
`redirectTo` set to the Worker reset page:

**https://personal-dashboard.chrisbailey.workers.dev/reset.html**

That URL (and the field-book URL below) must be in the Commodores project
(`adjnmtpjoyxvmlogjjpz`) Auth **Redirect URLs**. Site URL should be the Worker
field book, not GitHub Pages:

- Site URL: `https://personal-dashboard.chrisbailey.workers.dev/commodores.html`
- Redirect URLs: `https://personal-dashboard.chrisbailey.workers.dev/reset.html`
- Also allow: `https://personal-dashboard.chrisbailey.workers.dev/commodores.html`

The email link opens `reset.html`, which listens for `PASSWORD_RECOVERY` /
hash tokens and shows **Set new password**. After `updateUser({ password })`
the coach is signed in on the same `commodores-auth` session. Expired or
already-used links (`otp_expired`, `access_denied`) ask them to request a new
reset. `watch.html` stays token-only — no coach login or reset.

Primary pages: **Today**, **Playbook**, **Plays**, **Lineup**, **Practice**. Season board
is a reference link (schedule, milestones, goals). Playbook has Offense /
Defense sub-tabs. Lineup is two units (A = Q1/Q3, B = Q2/Q4), each with 7
offense and 7 defense, plus a live play-time rule check (2+2 or one-way).
Assignments persist on `commodores_plans` row `staff-lineup` (`skillsByCoach`
plus `units` and `attendance`; older `offense` / `defense` arrays still mirror
Unit A). Mark Present / Out for the session first; the rule check uses only the
kids who showed and short-roster both-way math (11→3, 10→4, … 7→all).

Official games are the SBMSA Fall 2026 JV 7on7 Maxwell book
(https://sbmsa.net/schedule/740099/jv-7-on-7-maxwell, revised Tue Aug 25, 2026
5:17 PM). Today shows the Commodores record, next game, full slate, and a
compact division table; Season board repeats the slate. Data lives on
`commodores_plans` row `sbmsa-jv-maxwell`. Apply
`sql/commodores_league_schedule.sql` on the Commodores project to seed or
revise. Later scores edit that JSON (`standings` w/l/t/gp and `games[].result`)
and bump `updated_at` — no page deploy. The HTML keeps a matching fallback seed
if the row is missing. League coach on the book is Selber. Field labels keep the
SBMSA names (MMS North West, SFMS South, …); addresses come from `venues`:
MMS → Memorial Middle School, 12550 Vindon Dr, Houston, TX 77024; SFMS → Spring
Forest Middle School, 14240 Memorial Dr, Houston, TX 77079 (not St. Francis).

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
