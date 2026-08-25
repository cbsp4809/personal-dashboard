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
- **Supabase** (`daddiljpnhfuxcdqsulg`, "Studio Pod") via CDN `@supabase/supabase-js@2`. Publishable/anon key only — never `service_role` in a page.
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

## ⚠️ Known critical issues (as of 2026-08-25, unfixed)

1. **The Commodores PIN gate does not protect anything.** It is client-side only: the full page body — roster, practice plans, coaching notes — ships to every visitor and is merely hidden with CSS/JS. A plain `curl` of the URL returns the entire field book without the PIN. Verified.
2. **The PIN hash is in the file.** `PIN_HASH` at ~line 762 is an unsalted SHA-256 of a 6-digit PIN. That is a 1,000,000-entry keyspace, brute-forceable offline in seconds.
3. **Minors' data is on a public URL.** Twelve first names (kids ages 8–10), per-kid 1–5 coach ratings from three named adults, and attendance. This is the highest-severity item in the repo, and it is a judgment/liability problem, not just a technical one.
4. **Supabase RLS is nominal.** `commodores_comments` and `commodores_plans` have RLS enabled but every policy is `using (true)` for `anon`. Anyone holding the publishable key (which is in the public HTML) can read and overwrite all staff notes and practice plans.
5. `public.calendar_invites`, `public.invite_tokens`, and `public.qbo_tokens` have RLS on with **zero policies**. Confirm those are genuinely unreachable.
6. Several `SECURITY DEFINER` functions (`is_admin`, `is_staff`, `sp_role`, `reserve_invoice_number`, `bump_invoice_number`) are executable by `anon` over the REST API.

**Do not add more player data to `commodores.html` until 1–4 are resolved.**

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
