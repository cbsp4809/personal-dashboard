# Handoff to Grok — Commodores field book (2026-08-27)

Hi Grok. Claude did a focused security + hosting overhaul on `commodores.html` while you were offline. This note explains **what changed, why, where things moved, and what to build next**, so you can pick it back up cleanly without undoing anything important. `CLAUDE.md` has the canonical project brief — read it too; this note is the narrative + roadmap.

The short version: the Commodores field book was leaking minors' data on a public URL. That's now fixed by (1) real auth, (2) moving it to its own database, and (3) putting the whole page behind Cloudflare Access. Please don't unwind any of that.

---

## Why the change (the problem we found)

- The old "six-digit staff PIN" gate was **cosmetic**. The entire page — roster, ratings, notes, plans — shipped in the HTML and was only hidden with JS. A plain `curl` returned the whole field book, and the PIN's SHA-256 hash was sitting in the file (trivially brute-forced).
- That meant **12 kids (ages 8–10), their first names, and per-kid 1–5 coach ratings were world-readable** on `cbsp4809.github.io`. That's the real reason for all the work below — it's a child-privacy/liability issue, not just tidiness.
- Supabase RLS on the Commodores tables was nominal (`using(true)` for `anon`), so anyone with the public key could read/overwrite everything.

## What changed (and where things moved)

**1. Commodores has its own Supabase project now.**
- Old: everything shared `daddiljpnhfuxcdqsulg` ("studio-pod sales manufacturing dashboard") — the same DB as Ops and the sales/photography data.
- New: `commodores.html` → **`adjnmtpjoyxvmlogjjpz`** ("commodores"), `https://adjnmtpjoyxvmlogjjpz.supabase.co`, publishable key `sb_publishable_iNNI1IuOPsOmkDPLZ-k9mw_t4Gxt4TW`.
- Why: so the public page's key can't touch any other business data. **Do not point `commodores.html` back at `daddiljpnhfuxcdqsulg`.**
- `index.html` and `ops.html` still use `daddiljpnhfuxcdqsulg` — unchanged.
- Tables on the new project: `commodores_coaches` (email allowlist), `commodores_roster`, `commodores_comments`, `commodores_plans`. Helper `commodores_is_coach()` reads the caller's JWT email. **RLS gates every table to allowlisted coaches only** (verified: anon = denied, non-coach = 0 rows, coach = full). The old `commodores_*` tables still exist on the shared project, anon-locked, as a backup — leave them for now.

**2. Real login replaced the PIN.**
- Supabase Auth email + password. Allowlisted coaches: `cbailey104@gmail.com` (Chris), `pselber@sbcglobal.net` (Peter), `bengoetz@gmail.com` (Ben).
- The Commodores Supabase client uses its own `storageKey: "commodores-auth"` so its session never collides with the Ops/morning-dashboard session on the shared origin. Keep that.

**3. The roster is no longer in the HTML.**
- `const ROSTER=[...]` (the 12 names) was removed. Names now load from `commodores_roster` after sign-in and cache in localStorage. **Do not hardcode kid names back into the file.** Default play diagrams were also blanked of names.

**4. QB names genericized to QB1 / QB2 / QB3.**
- The old "Mike QB1 · Teddy QB2 · Webb QB3" prose was notetaker noise (positions aren't actually assigned). Chris asked to make it QB1/QB2/QB3. **This is intentional — don't "restore" the names.**

**5. The whole page is behind Cloudflare Access now (this is the big one).**
- `commodores.html` is **no longer served on the public github.io site.** `deploy.yml` has a step that strips `commodores.html` + `commodores.webmanifest` from the GitHub Pages artifact. **Do not remove that step** — it's what keeps the playbook off the public web.
- Commodores is served instead by a **Cloudflare Worker** named `personal-dashboard` at **`https://personal-dashboard.chrisbailey.workers.dev/commodores.html`**, connected to this repo and **auto-deploying on push to `main`**.
- That worker sits behind a **Cloudflare Access** self-hosted app (hostname `personal-dashboard.chrisbailey.workers.dev`, policy "Coaches" = the 3 emails, login via One-time PIN email code). Team domain: `long-sunset-0be0.cloudflareaccess.com`.

### Deploy reality (important — this changed)
Pushing to `main` now deploys **two** places:
- **GitHub Pages** (`cbsp4809.github.io/personal-dashboard/`) — public — serves `index.html` + `ops.html`. `commodores.html` is excluded here.
- **Cloudflare Worker** (`personal-dashboard.chrisbailey.workers.dev`) — Access-gated — serves the whole repo, including `commodores.html`. This is the coaches' real URL.

So a coach loads the field book at the **workers.dev** URL, does a Cloudflare email code (page gate) **and** a Supabase password (data). Both sessions persist.

---

## Guardrails — please don't undo these

1. Don't remove the `deploy.yml` step that excludes `commodores.html` / `commodores.webmanifest` from GitHub Pages. Removing it re-exposes minors' data publicly.
2. Don't repoint `commodores.html` back to the shared Supabase project (`daddiljpnhfuxcdqsulg`). It uses `adjnmtpjoyxvmlogjjpz`.
3. Don't hardcode kid names/roster back into the HTML — roster comes from the DB after auth.
4. Keep the RLS/allowlist model; don't loosen policies to `anon` or `using(true)`.
5. Keep the coaching-domain constraints in `CLAUDE.md` (Smash + Overload only through Aug 30, six-area defense + one helper, no rush, hip-stay is a drill, etc.) — those are Chris's decisions, not defaults to "improve."
6. `commodores.webmanifest` uses **root-relative** paths (`/commodores.html`, `/icons/...`) for the workers.dev root, not the `/personal-dashboard/` GitHub sub-path.

## Working agreement (multi-agent)
- You push `cursor/*` branches and merge to `main`, which auto-deploys (now both targets above). Claude works on `claude/*` branches; Chris merges.
- `git pull` before any edit — two agents on one ~3,000-line file will clobber each other.
- One agent per file per session.

---

## What to build next — full product direction

This is Chris's own vision for the app, from his 2026-08-25 voice note ("Consolidating the Team Today app"). The through-line: **cut instruction bloat, collapse the too-many tabs into a few high-utility pages, and make the interactions actually work** (drag-and-drop lineup, visually-rendered plays, a modular practice builder). Prioritize working interactions over documentation volume; ship minimal, expandable scaffolds.

### Target information architecture — 4 pages
Collapse today's ten tabs (Today, Team, Playbook, Offense, Defense, Play builder, Milestones, Season board, Attendance, Plan handoff) down to **Team/Today, Playbook, Lineup, Practice**, plus a reference **Season Board**.

**1. Team/Today (Home) — the authoritative snapshot.**
- Sections: team philosophy summary; offense summary; defense summary; full roster with positions; **Next Practice** (pulled from the Practice tab); **Upcoming Games** (from the calendar/season schedule); collapsible **per-player rankings** (collapsed under each player once submitted).
- Interaction: a rankings submit pipeline that ingests, stores, and collapses ratings per player; links out to Lineup / Playbook / Practice.
- Cleanup: **remove the redundant top-level Offense/Defense tabs** — that content lives in Playbook now.

**2. Playbook (with Offense / Defense tabs) — clear, coachable, iPad-ready.**
- Content: the final five offensive plays (Chris/offense coordinator will supply source files) plus the defensive strategy. Render plays as **clean visual diagrams with bullet-point summaries**, not paragraphs.
- Build a **play-rendering component** (diagram + bullets). Design it so a future **Play Generator** can plug in.

**3. Lineup — drag-and-drop assignments (currently BROKEN, high priority to fix).**
- Two boards (offense, defense) + a roster pool + positional labels aligned to roster roles.
- Fix drag-and-drop so players can be placed/moved on both boards; **persist** assignments (to `commodores_plans` row `staff-lineup`, which already holds offense/defense arrays); surface a **lineup summary back on Team/Today**.

**4. Practice — date-indexed pages + a modular Practice Builder.**
- A calendar/list of practice dates; each date renders its own practice outline page (not mixed into Today); feed a concise "next practice" preview to Team/Today.
- **Practice Builder:** reusable, Quill-like **drill blocks** (stretching, warm-ups, routes, defense/offense breakouts) from a reusable drill library; **editable time allotments**; **drag drills into segments**; ability to **split a segment into two groups** (offense/defense) running concurrently. Practices persist to `commodores_plans` (each plan is a row; shape is documented in `commodores.html` and the handoff page: `{ id, date, time, location, duration, goal, stations:[{ minutes, name, detail, coach, concurrent? }] }`).

**Season Board (reference).** Centralize the season schedule + milestones + goals here, in tabs, so Team/Today stays clean and there's no infinite scroll. Reference-only; feeds Upcoming Games on Team/Today.

### Keep / Remove (Chris's decisions)
- **Keep:** Team/Today as the summary nexus; Playbook with Offense/Defense tabs; Lineup as its own page; Practice tab with the modular builder; Season Board hosting schedule + milestones.
- **Remove/relocate:** the duplicated top-level Offense/Defense tabs; the verbose instruction blocks (compress to bullets/microcopy/tooltips); **Attendance** (redundant with the team clock); **Plan handoff** (undefined — omit until Chris specifies requirements).

### Priority order for you
1. **Consolidate the navigation** (Chris's #1) — collapse to the 4 pages above, build the Team/Today home, route strategy into Playbook, remove the redundant Offense/Defense top tabs, and cut instruction bloat to bullets.
2. **Fix the Lineup drag-and-drop** + persistence + Team/Today summary.
3. **Playbook rendering** — visual diagrams + bullet summaries for the five plays and the defense.
4. **Practice tab + Practice Builder** — date-indexed pages, reusable drill blocks, time controls, offense/defense group splits, "next practice" preview to Team/Today.
5. **Play Generator** (biggest lift — spec before building): animated dots/X's showing motions, routes, and defensive reactions; iPad-friendly; tied to Playbook entries. Define the spec first — animation behaviors, route-motion scripting, defensive-reaction presets, and how each generator entry links to a Playbook play.

### Content + build style
- **Bullets-first everywhere.** Long-form coaching prose → concise bullets and on-page microcopy/tooltips.
- Data lives in the dedicated Supabase project (`adjnmtpjoyxvmlogjjpz`): roster in `commodores_roster`, ratings + lineup in `commodores_plans` row `staff-lineup` (`skillsByCoach` + `offense`/`defense` arrays), practice plans as `commodores_plans` rows, shared notes in `commodores_comments`. Load after auth; keep it RLS-gated.
- Respect the domain constraints in `CLAUDE.md` (Smash + Overload only through the scrimmage, six-area defense + one helper, no rush, hip-stay is a drill, QB1/QB2/QB3, etc.) — these are deliberate, not defaults to "improve."

### How to deploy
Push to `main`. That auto-deploys **both**: GitHub Pages (public — `index.html` + `ops.html`; `commodores.html` is excluded) and the Cloudflare Worker `personal-dashboard` (Access-gated — serves `commodores.html`). No separate build step. Verify changes at the gated worker URL (`personal-dashboard.chrisbailey.workers.dev/commodores.html`) after signing in. Keep `README.md` and `CLAUDE.md` current as you go.

Questions for Chris before big changes are always welcome — he prefers being asked.

---

## Open item — coach login delivery (not yet fully resolved)

- Cloudflare Access is confirmed working end-to-end: an allowlisted email passes the gate and the field book loads. Verified via the "Sign in with Cloudflare" button.
- The **coach allowlist** (Cloudflare Access policy "Coaches") currently has FOUR emails: the three coaches plus `chrisbailey@cbaileyphotography.com` (Chris's Cloudflare-account email) added as a **backup login** so Chris can sign in via the "Sign in with Cloudflare" button without an email code.
- **Unresolved:** the Access **One-time PIN email** did not arrive for `cbailey104@gmail.com` on repeated tries (checked spam). Peter (`pselber@sbcglobal.net`) and Ben (`bengoetz@gmail.com`) have **no Cloudflare accounts**, so they can only use the email-code method. If those codes also fail to deliver, the fallback is: each coach creates a free Cloudflare account with their coach email and uses "Sign in with Cloudflare." Please don't remove the One-time PIN identity provider or the allowlist emails while sorting this out.
- Two identity layers exist by design: **Cloudflare Access** gates the page; **Supabase Auth** (email+password) gates the data (roster/ratings) via RLS. First visit is two logins; both persist. A future nicety (not required) is collapsing them to one via a Worker that validates the Access JWT for Supabase — leave it unless Chris asks.
