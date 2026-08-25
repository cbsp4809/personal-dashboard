# Commodores access-control fix — handoff checklist

Prepared 2026-08-25. Branch: `claude/commodores-auth`.

## What's already live on the database (took effect immediately, no deploy needed)

- The public anon key can **no longer read** `commodores_comments`, `commodores_plans`, or `commodores_roster`. The kids' names, coach ratings, and notes are no longer pullable from the database. Verified: anon = permission denied; a signed-in non-coach = 0 rows; an allowlisted coach = full access.
- New table `commodores_coaches` (the allowlist) seeded with: Chris `cbailey104@gmail.com`, Peter `pselber@sbcglobal.net`, Ben `bengoetz@gmail.com`.
- New table `commodores_roster` holds the 12 first names (moved out of the HTML).
- All Commodores tables now require an allowlisted coach via `commodores_is_coach()`.

> Side effect until the code below deploys: the **current live** `commodores.html` still uses the old anon path, so its cloud sync now fails quietly and each device shows its local copy. This resolves the moment the new build is deployed.

## What's in the branch (not live until you merge + it deploys)

`commodores.html` rewritten:
- PIN gate replaced with **email + password** sign-in (Supabase Auth).
- Roster loads from the database after sign-in — **no kid names baked into the file** anymore.
- The Commodores login uses its own session key, so it won't collide with your Ops / morning-dashboard login on the same site.
- Default play diagrams no longer carry player names.
- "Lock" now signs out.

## Step 1 — free the git commit (one line in your Mac terminal)

A stale lock is blocking commits. In the repo folder:

```
rm -f .git/index.lock
git add commodores.html CLAUDE.md COMMODORES_AUTH_HANDOFF.md
git commit -m "Replace Commodores PIN gate with Supabase email login; move roster to RLS-gated DB"
```

(The file changes are already written to disk on branch `claude/commodores-auth` — this just records them.)

## Step 2 — set up the three coach logins in Supabase (do before deploy)

In the Supabase dashboard → project **Studio Pod** → **Authentication**:

1. **URL Configuration** → add to **Redirect URLs**:
   `https://cbsp4809.github.io/personal-dashboard/commodores.html`
   (and set Site URL to the same if it isn't already). This makes the invite / set-password links land back on the field book.
2. **Users** → **Add user** → **Send invitation** for each of the three emails above. Each coach clicks the email link and sets their own password.
   - The emails must match the allowlist **exactly** (already seeded). If a coach wants a different email, tell me and I'll update the allowlist.
3. (Recommended) **Providers → Email** → turn **OFF** "Allow new users to sign up." Access is already allowlist-protected, but this stops strangers creating accounts at all.
4. (Optional, defense-in-depth) enable **Leaked password protection** (Auth → Policies) — Supabase flagged it as off.

## Step 3 — time the merge

Once you merge `claude/commodores-auth` into `main`, GitHub Pages deploys and the **PIN stops working** — email login is the only way in. So:

- Make sure Peter and Ben have accepted their invites and set passwords **first**.
- Practice is **Thursday**. If invites + logins can't be confirmed by then, run Thursday on the current version and merge Friday.

## One decision left for you

Three first names still appear in **coaching prose** (not as a roster list): the locked QB order "Mike QB1 · Teddy QB2 · Webb QB3" and drill text like "Mike / Teddy / Webb throw." I left these because scrubbing them would mangle your QB copy, and CLAUDE.md says those coaching constraints are deliberate. The severe exposure (full roster + ratings) is gone. If you also want those three names genericized in the instructional text, say so and I'll reword carefully.

## Also worth doing later (separate from this)

Supabase flagged, on the shared project, a few `SECURITY DEFINER` functions (`is_admin`, `is_staff`, `sp_role`, `reserve_invoice_number`, `bump_invoice_number`) callable by anon, and three tables with RLS on but zero policies (`calendar_invites`, `invite_tokens`, `qbo_tokens`). These are from the Ops/photography side, not Commodores. Flagging so it's on the list; happy to look when you want.
