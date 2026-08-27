// Serves the Virginia's Hub PWA as its own Worker.
// Public workers.dev site — no Cloudflare Access, no Commodores gate.

const EXTRA = {
  "X-Robots-Tag": "noindex, nofollow, noarchive",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
};

export default {
  async fetch(request, env) {
    const res = await env.ASSETS.fetch(request);
    const headers = new Headers(res.headers);
    for (const [k, v] of Object.entries(EXTRA)) headers.set(k, v);
    const type = res.headers.get("content-type") || "";
    if (type.includes("text/html")) headers.set("Cache-Control", "no-store");
    return new Response(res.body, {
      status: res.status,
      statusText: res.statusText,
      headers,
    });
  },
};
