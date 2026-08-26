# CLAUDE.md — personal-dashboard

Project brief for AI agents working in this repo. Read this before touching anything.

Owner: Chris Bailey (chrisbailey@cbaileyphotography.com)
Repo: https://github.com/cbsp4809/personal-dashboard

---

## What this is

Three unrelated single-file web apps that happen to share a repo and a Supabase project.

| File | What it is | Audience |
|---|---|---|
| `index.html` | Morning dashboard — schedule, to-dos, priority email, goals, AI assistant | Chris |
| `ops.html` | Ops board — shared card/kanban + email reply queue | Chris + Sydney |
| `commodores.html` | Commodores staff field book — playbook, lineups, practice plans, player ratings | Chris + 2 other coaches (Peter, Ben) |

They are independent. **Do not merge them, and do not let a change to one leak into another.**

## Stack

- **Zero build step.** Plain HTML + CSS + JS, all inline in one file per app. No `package.json`, no bundler, no tests, no framework.
- **Supabase** via CDN `@supabase/supabase-js@2`. Publishable/anon key only — never `service_role` in a page.
  - `index.html` + `ops.html` → project `daddiljpnhfuxcdqsulg` ("studio-pod sales manufacturing dashboard").
  - `commodores.html` → its **own dedicated project** `adjnmtpjoyxvmlogjjpz` ("commodores"), created 2026-08-25 so the public page's key can't reach any other business data. Uses Supabase Auth (email+password) with an allowlist table `commodores_coaches`; roster/ratings/notes/plans are RLS-gated to allowlisted coaches. It uses its own `storageKey` so its session never collides with Ops on the shared origin.
- **GitHub Pages**, auto-deploy on push to `main` via `.github/workflows/deploy.yml`. There is no staging. **Pushing to `main` is publishing.**
- **PWA**: `manifest.json` (Ops), `commodores.webmanifest` (Commodores), `sw.js`, `icons/`.
- `proxy/worker.js` — Cloudflare Worker.
- `sql/*.sql` — idempotent migrations, applied **manually** in the Supabase SQL editor. They are not run by any pipeline.

## Deploy reality

```
push to main  →  GitHub Action  →  https://cbsp4809.github.io/personal-dashboard/
```

Everything in this repo is served publicly at that origin. There is no private hosting layer. Treat every file as world-readable.

---

## Commodores access control — status (2026-08-25)

RESOLVED on branch `claude/commodores-auth` (pending Chris's merge + coach invites):

1. ~~PIN gate is cosmetic~~ → replaced with Supabase Auth email+password login.
2. ~~PIN hash in file~~ → removed.
3. ~~Minors' data on a public URL~~ → roster moved to the DB behind auth; no kid names ship in the HTML except three QB nicknames in coaching prose (Mike/Teddy/Webb). Attendance was always device-local, never public.
4. ~~Nominal RLS (`using(true)`)~~ → RLS gates every Commodores table to allowlisted coaches via `commodores_is_coach()`. Verified anon=denied, non-coach=0 rows, coach=full.
   Plus: Commodores moved to its own project (see Stack) so its public key can't touch other data.

Still open on the SHARED sales project (not Commodores, lower priority):

5. `public.calendar_invites`, `public.invite_tokens`, `public.qbo_tokens` have RLS on with **zero policies**. Confirm genuinely unreachable.
6. `SECURITY DEFINER` functions (`is_admin`, `is_staff`, `sp_role`, `reserve_invoice_number`, `bump_invoice_number`) executable by `anon` over REST.

## Recommended fix path for access control

Client-side gating cannot be made to work on GitHub Pages. Real options:

- **Cloudflare Pages/Workers** with Access in front of it (a `proxy/worker.js` already exists — the muscle is partly there). Keeps the static-file simplicity.
- **Supabase Auth** for the three coaches, with content loaded from the DB after sign-in rather than baked into the HTML, plus RLS keyed to `auth.uid()`.
- **Netlify** password protection — least work, weakest guarantee, but strictly better than today.

---

## Domain rules — Commodores

This is FWE JV Vanderbilt Commodores, Fall 2026. 12 kids, ages 8–10. Coaches: Peter, Chris, Ben. Practices Thu 5:00pm / Sun 1:00pm at Frostwood through Dec 6.

The codebase encodes deliberate coaching constraints. **These are decisions, not defaults. Do not "improve" them.**

- Taught offense through the Aug 30 scrimmage: **Smash** and **Overload 50/51** only. No third play.
- Game defense: **six kids cover six areas + one helper. No rush** (league rule).
- "Hip-stay" / "pick-a-guy" / "Man-Free" is a **drill only**, never the game plan.
- Do not add "zone" as a new package — the six-area look already is that.
- QB order is locked: Mike QB1, Teddy QB2, Webb QB3. "Michael" on the roster is Mike.
- "Chris's 16" is a parked binder list. Not this week's plays.
- Two defense groups, set before the quarter, no mid-quarter swapping.

## Conventions

- Files are single-file on purpose. When one outgrows that, split into `/css`, `/js`, and partials — deliberately, not incidentally.
- SQL files must stay idempotent (`create ... if not exists`, `drop policy if exists`).
- Keep the README current; it is unusually good and is the other source of truth.
- Ops and Commodores must not read or write each other's tables.
- `commodores.html` is intentionally not linked from `index.html` or `ops.html`.

---

## Working agreement (multiple agents)

Cursor/Grok background agents have been pushing branches named `cursor/*` and merging to `main`, which auto-deploys. Claude works on branches named `claude/*` only.

Rules:

1. **`git pull` before any edit.** Non-negotiable — two agents on one 3,000-line file will clobber each other.
2. Claude does not push to `main` and does not merge. Chris merges.
3. One agent per file per session. If Cursor is mid-flight on `commodores.html`, Claude stays out of it.
4. Commit messages describe the coaching or product outcome, matching existing style ("Freeze Team scoring order and fix iPhone lineup assignment").

## Current backlog source

Chris's 2026-08-25 voice note ("Consolidating the Team Today app"). Headline direction: consolidate `commodores.html` navigation down to **Team/Today, Playbook, Lineup, Practice**; cut instruction bloat to bullets; fix broken lineup drag-and-drop; build a modular practice builder; add a play generator. Attendance and "plan handoff" get removed.
