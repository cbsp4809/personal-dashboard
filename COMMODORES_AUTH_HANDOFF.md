# Commodores access-control fix — handoff checklist

Prepared 2026-08-25. Branch: `claude/commodores-auth`.

## Big picture

Commodores now lives in its **own dedicated Supabase project**, fully separated
from your sales/manufacturing and photography databases. The public field-book
page carries a key scoped to a database that holds **nothing but** practice
data.

- **New project:** `commodores` — ref `adjnmtpjoyxvmlogjjpz`, region us-east-1.
- **Old location:** the shared "studio-pod sales manufacturing dashboard"
  (`daddiljpnhfuxcdqsulg`). Its Commodores tables are already anon-locked and
  are left in place as a backup until you confirm the new one works. I never
  touched any sales/manufacturing table.

## What's already done (live on the new project)

- Tables recreated: `commodores_coaches` (allowlist), `commodores_roster`,
  `commodores_comments`, `commodores_plans`.
- All data migrated and verified: 3 notes, 2 plans (including every coach's
  ratings), 12 roster names, 3 coaches.
- Row-level security gates every table to allowlisted coaches only. Verified:
  anon = permission denied; signed-in non-coach = 0 rows; coach = full access.
- Allowlist seeded: Chris `cbailey104@gmail.com`, Peter `pselber@sbcglobal.net`,
  Ben `bengoetz@gmail.com`.
- `commodores.html` now points at the new project's URL + publishable key.

## Step 1 — commit the code (one line in your Mac terminal)

A stale lock is blocking commits. In the repo folder:

```
cd "/Users/cblaptop/Documents/Claude/Projects/CBP Dashboard/studio-app/personal-dashboard"
rm -f .git/index.lock
git add commodores.html CLAUDE.md COMMODORES_AUTH_HANDOFF.md
git commit -m "Move Commodores to dedicated Supabase project with email login and RLS"
```

Confirm with `git branch --show-current` → should say `claude/commodores-auth`.
Nothing deploys until you merge to `main`.

## Step 2 — set up the three coach logins (on the NEW `commodores` project)

Supabase dashboard → open the **`commodores`** project (NOT the sales one) →
**Authentication**:

1. **URL Configuration** → set **Site URL** and add to **Redirect URLs**:
   `https://cbsp4809.github.io/personal-dashboard/commodores.html`
2. **Users** → **Add user** → **Send invitation** for each of:
   `cbailey104@gmail.com`, `pselber@sbcglobal.net`, `bengoetz@gmail.com`.
   Each coach clicks the email link and sets their own password. Emails must
   match the allowlist exactly (already seeded).
3. (Recommended) **Providers → Email** → turn **OFF** "Allow new users to sign
   up." RLS already protects the data; this just stops strangers making accounts.
4. (Optional) enable **Leaked password protection**.

## Step 3 — time the merge

Merging `claude/commodores-auth` → `main` deploys to GitHub Pages and the PIN
stops working; email login becomes the only way in. So make sure Peter and Ben
have set passwords **first**. Practice is **Thursday** — if that's tight, run
Thursday on the current version and merge Friday.

## Step 4 — after you confirm it works (optional cleanup)

Once coaches can sign in and see the field book on the new project, I can drop
the old `commodores_*` tables from the sales project so nothing is duplicated.
Say the word and I'll do it.

## One decision still open

Three first names remain in **coaching prose** (not as a roster list): the
locked QB order "Mike QB1 · Teddy QB2 · Webb QB3" and drill text like
"Mike / Teddy / Webb throw." I left these so I don't mangle your QB copy. Say
so if you want them genericized too.

## Separate note (not Commodores)

On the sales project, Supabase flagged several `SECURITY DEFINER` functions
callable by anon and three tables with RLS on but no policies
(`calendar_invites`, `invite_tokens`, `qbo_tokens`). Those are from the
Ops/photography side. Flagging for later; happy to look when you want.
