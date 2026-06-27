# Assistant Proxy (Cloudflare Worker)

This little Worker lets the dashboard's Assistant give real AI answers on the
live site, while keeping your API key(s) **out of the public repo**. The browser
calls the Worker; the Worker holds the secret key and calls Claude / GPT.

## One-time setup

1. **Get an API key** (one or both):
   - Anthropic (Claude): https://console.anthropic.com → API keys → Create key
   - OpenAI (GPT): https://platform.openai.com/api-keys → Create new secret key
   - Both are pay-per-use; personal chat volume is pennies.

2. **Create the Worker:**
   - Sign up free at https://dash.cloudflare.com → **Workers & Pages** → **Create** → **Create Worker**
   - Give it a name (e.g. `dashboard-assistant`), click Deploy, then **Edit code**
   - Replace everything with the contents of `worker.js` (in this folder), then **Deploy**

3. **Add your key(s) as secrets:**
   - In the Worker → **Settings** → **Variables and Secrets** → **Add**
   - Type: **Secret**. Name: `ANTHROPIC_API_KEY` (and/or `OPENAI_API_KEY`). Value: your key. Save/Deploy.

4. **Copy the Worker URL** (looks like `https://dashboard-assistant.<you>.workers.dev`).

5. In the dashboard, open the Assistant's **⚙** and paste that URL. Done — pick
   Claude or GPT with the dropdown and chat away.

## Notes
- `ALLOWED_ORIGIN` is locked to the dashboard's URL so only your site can use the proxy.
- The Worker URL itself is **not** a secret — safe to paste into the dashboard.
- Change the model in `worker.js` anytime (e.g. a larger Claude or GPT model).
