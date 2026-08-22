self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("notificationclick", event => {
  event.notification.close();
  const target = event.notification.data && event.notification.data.url
    ? event.notification.data.url
    : new URL("ops.html", self.registration.scope).href;

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type:"window", includeUncontrolled:true });
    const sameOrigin = new URL(target).origin===self.location.origin
      ? target
      : new URL("ops.html", self.registration.scope).href;
    for(const client of windows){
      if("focus" in client){
        if("navigate" in client) await client.navigate(sameOrigin);
        return client.focus();
      }
    }
    return self.clients.openWindow ? self.clients.openWindow(sameOrigin) : undefined;
  })());
});
