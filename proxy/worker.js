// Personal Dashboard — AI assistant proxy (Cloudflare Worker)
// Holds your API keys as Worker SECRETS (never in the public repo) and relays
// the dashboard's request to Claude or GPT. Set secrets in the Worker:
//   ANTHROPIC_API_KEY  and/or  OPENAI_API_KEY
// Lock requests to your site by keeping ALLOWED_ORIGIN as-is.

const ALLOWED_ORIGIN = "https://cbsp4809.github.io";

export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    if (request.method !== "POST") return json({ error: "POST only" }, 405, cors);

    let body;
    try { body = await request.json(); } catch { return json({ error: "bad JSON" }, 400, cors); }

    const provider = body.provider === "gpt" ? "gpt" : "claude";
    const prompt = String(body.prompt || "").slice(0, 8000);
    const context = body.context ? JSON.stringify(body.context).slice(0, 6000) : "";
    const system =
      "You are the assistant inside Chris Bailey's personal dashboard. Chris runs a Houston " +
      "fine-art wedding/portrait photography business and a photo-booth brand (Studio Pod). " +
      "Be concise, warm, and practical. Help draft replies, plan, prioritize tasks, and think things through. " +
      "Here is current dashboard context (tasks, goals, agenda): " + context;

    try {
      if (provider === "gpt") {
        if (!env.OPENAI_API_KEY) return json({ error: "OpenAI key not set on the proxy" }, 400, cors);
        const r = await fetch("https://api.openai.com/v1/chat/completions", {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: "Bearer " + env.OPENAI_API_KEY },
          body: JSON.stringify({
            model: "gpt-4o-mini",
            max_tokens: 700,
            messages: [{ role: "system", content: system }, { role: "user", content: prompt }],
          }),
        });
        const d = await r.json();
        return json({ text: d.choices?.[0]?.message?.content || ("(no response) " + JSON.stringify(d)) }, 200, cors);
      } else {
        if (!env.ANTHROPIC_API_KEY) return json({ error: "Anthropic key not set on the proxy" }, 400, cors);
        const r = await fetch("https://api.anthropic.com/v1/messages", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-api-key": env.ANTHROPIC_API_KEY,
            "anthropic-version": "2023-06-01",
          },
          body: JSON.stringify({
            model: "claude-haiku-4-5-20251001",
            max_tokens: 700,
            system,
            messages: [{ role: "user", content: prompt }],
          }),
        });
        const d = await r.json();
        return json({ text: d.content?.[0]?.text || ("(no response) " + JSON.stringify(d)) }, 200, cors);
      }
    } catch (e) {
      return json({ error: String(e.message || e) }, 500, cors);
    }
  },
};

function json(obj, status, cors) {
  return new Response(JSON.stringify(obj), { status, headers: { ...cors, "Content-Type": "application/json" } });
}
