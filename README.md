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
index.html          # morning dashboard — self-contained (HTML + CSS + JS inline)
ops.html            # Ops board (Chris & Sydney) — separate page, same GitHub Pages site
manifest.json       # web app manifest so Ops can be added to an iPhone home screen
icons/              # original Ops mark (Apple 180, manifest 192/512)
README.md
.gitignore
.github/workflows/deploy.yml   # GitHub Pages auto-deploy
sql/ops_events.sql             # Ops notify table (Sydney owns pings)
```

The morning dashboard stays the daily command center. Ops is a second page, not
a rewrite of `index.html`. After deploy it lives at `/ops.html` (or
`/personal-dashboard/ops.html` on the GitHub Pages project URL).

Kept as one file on purpose while it's a single page. When it grows past that,
split into `/css`, `/js`, and per-module partials.

## Ops board (`ops.html`)

A four-column board for work Chris and Sydney share:

- **Needs you** — waiting on Chris
- **Today** — the day's focus (the morning dashboard's "My Day" idea)
- **This week** — parked for the next few days
- **Sydney owns** — cards Sydney writes and can complete

Cards persist in Supabase table `public.ops_cards` on the same Studio Pod
project Chris already signs into (`daddiljpnhfuxcdqsulg`). Sign in with that
account (password or magic link). Do not invent extra columns; Sydney (and
anyone writing from chat/email) should insert/update rows on `ops_cards`.

Each card has a title, optional snippet, project tag (`studio-pod` / `cbp` /
`personal`), owner (`chris` / `sydney`), optional due date, and a source
(`chat` / `email` / `todo` / `calendar`). Completing a card sets `done_at` /
`done_by` and moves it into the Done drawer.

A star on the add bar (and on each card) sends work to **Today** in one tap.
Unstarring a Today card parks it in This week. The column dropdown stays.

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
