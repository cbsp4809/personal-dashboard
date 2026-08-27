# Put the Commodores field book behind Cloudflare Access

Goal: the **entire** field book page loads only for your three coaches. They get
a one-time code by email (no new password). Free on Cloudflare's Zero Trust tier
for three people.

Prepared 2026-08-26. Branch: `claude/commodores-content-lockdown`.

## What I already did (on the branch)

- Genericized the QB names → **QB1 / QB2 / QB3** everywhere (no kid names in the page).
- Fixed `commodores.webmanifest` to root-relative paths for a `pages.dev` root.
- Set the GitHub Pages deploy to **stop publishing** `commodores.html` and
  `commodores.webmanifest` (so the public github.io URL no longer serves the
  field book once you merge).

## The order that matters

Set up Cloudflare **first**, confirm a coach can get in, and only **then** merge
the branch (which pulls the page off the public github.io URL). That way there's
never a moment where coaches can't reach it. The sensitive data is already
locked regardless, so there's no rush.

---

## Step 1 — Create a Cloudflare Pages site from the repo

1. Cloudflare dashboard → **Workers & Pages** → **Create** → **Pages** →
   **Connect to Git**.
2. Authorize GitHub if asked, pick the **`personal-dashboard`** repo.
3. Build settings:
   - Framework preset: **None**
   - Build command: **(leave blank)**
   - Build output directory: **/** (just a slash)
4. **Save and Deploy.** After a minute you'll get a URL like
   `personal-dashboard-xyz.pages.dev`.
5. Test it: open `https://<your-project>.pages.dev/commodores.html`. It should
   load the field book (still ungated at this point).

## Step 2 — Turn on Cloudflare Access for the three coaches

1. Cloudflare dashboard → **Zero Trust** (left sidebar). If it's your first time,
   it'll ask you to pick a team name and the **Free** plan — accept it.
2. **Access → Applications → Add an application → Self-hosted.**
3. Application settings:
   - Application name: **Commodores**
   - Session duration: **1 month** (so coaches rarely re-auth)
   - Add a **Public hostname**: subdomain `<your-project>`, domain `pages.dev`,
     path `commodores.html` (protect just the field book).
     - If it won't let you use a `pages.dev` domain here, instead go to your
       **Pages project → Settings → enable Access policy** — Pages has a built-in
       Access integration that protects the project directly. Either route works.
4. **Add a policy:**
   - Policy name: **Coaches**
   - Action: **Allow**
   - Rule: **Emails** → add `cbailey104@gmail.com`, `pselber@sbcglobal.net`,
     `bengoetz@gmail.com`.
5. **Login method:** make sure **One-time PIN** is enabled (Zero Trust →
   Settings → Authentication). This emails a 6-digit code — no password, no IdP.
6. Save.

## Step 3 — Test the gate

1. Open `https://<your-project>.pages.dev/commodores.html` in a private window.
2. You should see a Cloudflare screen asking for your email → it emails a code →
   enter it → the field book loads.
3. Try an email **not** on the list — it should be refused. Good.

## Step 4 — Merge the branch (ends public exposure)

Once a coach has confirmed they can get in on the pages.dev URL, merge
`claude/commodores-content-lockdown` into `main` (GitHub Desktop, same as
before). On the next deploy:
- github.io stops serving `commodores.html` (public playbook exposure ends).
- Cloudflare Pages rebuilds and serves the QB-genericized version, gated.

## Step 5 — Hand coaches the new link

The field book now lives at:
`https://<your-project>.pages.dev/commodores.html`

Tell Peter and Ben to open that, enter their email, type the code, then
**Add to Home Screen** again (the old github.io icon won't work anymore).

---

## Heads-up: two quick logins the first time

Cloudflare Access gates the **page**; your existing Supabase email/password
login still guards the **data** (roster, ratings) underneath. So the very first
time, a coach does the Access email-code once, then the Supabase password once.
Both sessions persist, so after that it's normally straight in. If that double
step ever feels clunky, I can later collapse it to a single login with a small
Cloudflare Worker — a nice-to-have, not needed now.

## Note for future edits

`commodores.html` stays a normal file you edit and push like always — Cloudflare
Pages auto-deploys it on every push to `main`, just like GitHub Pages did. Access
protection stays on automatically.
