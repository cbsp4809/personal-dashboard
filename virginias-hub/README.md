# Virginia's Hub

Pink planner PWA for Virginia. Separate app, separate Worker, separate Hub
schema. It does **not** live on GitHub Pages and it does **not** use the
Commodores Access gate.

Live host after you deploy this folder:

```
https://virginias-hub.<your-account>.workers.dev
```

## Deploy (Cloudflare Worker only)

From this folder, once (links the Worker named `virginias-hub`):

```bash
npx wrangler deploy
```

That publishes `public/` as its own `workers.dev` site. Do not add this
folder to the GitHub Pages artifact and do not attach the Commodores
Access application to this Worker.

## How it signs in

1. Visitor password (`PinkPlanner26`) — device gate only.
2. Email + password — create account or sign in. Same email is the same
   Hub on every device.

Talks only to these existing functions on `adjnmtpjoyxvmlogjjpz`:

- `POST /functions/v1/hub-signup`
- `POST /functions/v1/hub-login`
- `GET` / `PUT /functions/v1/hub-sync`

It never queries `commodores_*` tables.

The `hub` schema stays revoked from `anon` / `authenticated`. The functions
use `service_role` through PostgREST, so this project's Data API must list
`hub` among exposed schemas (`public, graphql_public, hub`). That was applied
on the personal Supabase project; anon still gets `permission denied for
schema hub` if it tries the REST API directly.

## Add to an iPad Home Screen

1. Open the Worker URL in **Safari**.
2. Enter the visitor password, then create an account or sign in.
3. Share → **Add to Home Screen** → name it **Virginia's Hub**.
