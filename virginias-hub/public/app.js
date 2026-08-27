(() => {
  const HUB_URL = "https://adjnmtpjoyxvmlogjjpz.supabase.co";
  const PUBLISHABLE = "sb_publishable_iNNI1IuOPsOmkDPLZ-k9mw_t4Gxt4TW";
  const GATE = "PinkPlanner26";
  const KEYS = {
    gate: "virginias-hub-gate",
    token: "virginias-hub-token",
    email: "virginias-hub-email",
    data: "virginias-hub-data",
  };

  const EMPTY = {
    todos: [],
    homework: [],
    schedule: { mon: [], tue: [], wed: [], thu: [], fri: [] },
    notes: [],
    folders: [{ id: "general", name: "General" }],
    reminders: [],
    calendar: [],
    settings: { notify: false, defaultReminder: "night-before" },
  };

  const DAYS = [
    ["mon", "Monday"],
    ["tue", "Tuesday"],
    ["wed", "Wednesday"],
    ["thu", "Thursday"],
    ["fri", "Friday"],
  ];
  const DOW = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  let token = localStorage.getItem(KEYS.token) || "";
  let email = localStorage.getItem(KEYS.email) || "";
  let data = normalize(readCache());
  let tab = "today";
  let folderId = "general";
  let noteId = "";
  let calCursor = new Date();
  let selectedDate = isoDate(new Date());
  let saveTimer = 0;
  let draggingId = "";

  const $ = (id) => document.getElementById(id);
  const gateScreen = $("gate-screen");
  const authScreen = $("auth-screen");
  const hubScreen = $("hub-screen");

  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function isoDate(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
  }

  function todayKey() {
    return ["sun", "mon", "tue", "wed", "thu", "fri", "sat"][new Date().getDay()];
  }

  function greeting() {
    const h = new Date().getHours();
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  function escapeHtml(s) {
    return String(s ?? "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[c]));
  }

  function normalize(raw) {
    const src = raw && typeof raw === "object" ? raw : {};
    const schedule = { ...EMPTY.schedule, ...(src.schedule || {}) };
    for (const [k] of DAYS) schedule[k] = Array.isArray(schedule[k]) ? schedule[k] : [];
    return {
      todos: Array.isArray(src.todos) ? src.todos : [],
      homework: Array.isArray(src.homework) ? src.homework : [],
      schedule,
      notes: Array.isArray(src.notes) ? src.notes : [],
      folders: Array.isArray(src.folders) && src.folders.length ? src.folders : EMPTY.folders.slice(),
      reminders: Array.isArray(src.reminders) ? src.reminders : [],
      calendar: Array.isArray(src.calendar) ? src.calendar : [],
      settings: { ...EMPTY.settings, ...(src.settings || {}) },
    };
  }

  function readCache() {
    try { return JSON.parse(localStorage.getItem(KEYS.data) || "null"); }
    catch { return null; }
  }

  function cacheLocal() {
    localStorage.setItem(KEYS.data, JSON.stringify(data));
  }

  function setSync(label, kind) {
    const pill = $("sync-pill");
    if (!pill) return;
    pill.textContent = label;
    pill.className = "pill" + (kind ? " " + kind : "");
  }

  async function hubCall(path, { method = "GET", body, userToken } = {}) {
    const headers = {
      "Content-Type": "application/json",
      apikey: PUBLISHABLE,
      Authorization: "Bearer " + (userToken || PUBLISHABLE),
    };
    const res = await fetch(HUB_URL + "/functions/v1/" + path, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    let json = {};
    try { json = await res.json(); } catch { json = {}; }
    if (!res.ok) throw new Error(json.error || "Something went wrong.");
    return json;
  }

  function persistSession(nextToken, nextEmail, nextData) {
    token = nextToken;
    email = nextEmail;
    data = normalize(nextData);
    localStorage.setItem(KEYS.token, token);
    localStorage.setItem(KEYS.email, email);
    cacheLocal();
  }

  function changed() {
    cacheLocal();
    setSync("Saving…", "busy");
    clearTimeout(saveTimer);
    saveTimer = setTimeout(pushSync, 500);
    render();
  }

  async function pushSync() {
    if (!token) return;
    try {
      await hubCall("hub-sync", { method: "PUT", body: { data }, userToken: token });
      setSync("Saved");
    } catch (err) {
      setSync(err.message || "Could not save", "err");
    }
  }

  async function pullSync() {
    if (!token) return;
    setSync("Syncing…", "busy");
    const row = await hubCall("hub-sync", { userToken: token });
    data = normalize(row.data);
    cacheLocal();
    setSync("Saved");
    render();
  }

  function show(which) {
    gateScreen.hidden = which !== "gate";
    authScreen.hidden = which !== "auth";
    hubScreen.hidden = which !== "hub";
  }

  function boot() {
    if (localStorage.getItem(KEYS.gate) !== "ok") {
      show("gate");
      return;
    }
    if (!token) {
      show("auth");
      return;
    }
    show("hub");
    render();
    pullSync().catch((err) => setSync(err.message || "Offline", "err"));
  }

  $("gate-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const err = $("gate-error");
    if ($("gate-password").value !== GATE) {
      err.hidden = false;
      err.textContent = "That password is not right.";
      return;
    }
    localStorage.setItem(KEYS.gate, "ok");
    err.hidden = true;
    boot();
  });

  async function auth(mode) {
    const err = $("auth-error");
    err.hidden = true;
    const em = $("auth-email").value.trim();
    const pw = $("auth-password").value;
    try {
      const row = await hubCall(mode === "signup" ? "hub-signup" : "hub-login", {
        method: "POST",
        body: { email: em, password: pw },
      });
      persistSession(row.token, row.email, row.data);
      show("hub");
      render();
    } catch (e) {
      err.hidden = false;
      err.textContent = e.message;
    }
  }

  $("auth-form").addEventListener("submit", (e) => {
    e.preventDefault();
    auth("signin");
  });
  $("auth-create").addEventListener("click", () => auth("signup"));

  $("settings-btn").addEventListener("click", () => {
    $("settings-email").textContent = email;
    $("setting-notify").checked = !!data.settings.notify;
    $("setting-default-reminder").value = data.settings.defaultReminder || "night-before";
    $("settings-dialog").showModal();
  });

  $("setting-notify").addEventListener("change", async () => {
    data.settings.notify = $("setting-notify").checked;
    if (data.settings.notify && "Notification" in window && Notification.permission === "default") {
      await Notification.requestPermission();
    }
    changed();
  });
  $("setting-default-reminder").addEventListener("change", () => {
    data.settings.defaultReminder = $("setting-default-reminder").value;
    changed();
  });
  $("sign-out").addEventListener("click", () => {
    token = "";
    email = "";
    localStorage.removeItem(KEYS.token);
    localStorage.removeItem(KEYS.email);
    $("settings-dialog").close();
    show("auth");
  });

  document.querySelectorAll(".tab").forEach((btn) => {
    btn.addEventListener("click", () => {
      tab = btn.dataset.tab;
      render();
    });
  });

  function setTab() {
    document.querySelectorAll(".tab").forEach((btn) => btn.classList.toggle("on", btn.dataset.tab === tab));
    document.querySelectorAll(".page").forEach((page) => page.classList.toggle("on", page.id === "page-" + tab));
  }

  function dueLabel(date) {
    if (!date) return "No due date";
    const d = new Date(date + "T12:00:00");
    const today = isoDate(new Date());
    if (date === today) return "Due today";
    const tmr = new Date(); tmr.setDate(tmr.getDate() + 1);
    if (date === isoDate(tmr)) return "Due tomorrow";
    return "Due " + d.toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });
  }

  function addHomeworkReminder(hw) {
    const kind = data.settings.defaultReminder;
    if (!hw.due || kind === "none") return;
    const due = new Date(hw.due + "T12:00:00");
    const when = new Date(due);
    if (kind === "night-before") {
      when.setDate(when.getDate() - 1);
      when.setHours(19, 0, 0, 0);
    } else {
      when.setHours(7, 0, 0, 0);
    }
    data.reminders.push({
      id: uid(),
      title: "Homework: " + hw.title,
      at: when.toISOString(),
      done: false,
      source: hw.id,
    });
  }

  function renderToday() {
    const now = new Date();
    $("greeting").textContent = greeting();
    const starred = data.todos.filter((t) => t.starred && !t.done);
    const dueHw = data.homework.filter((h) => !h.done).sort((a, b) => String(a.due || "9999").localeCompare(String(b.due || "9999"))).slice(0, 4);
    const day = todayKey();
    const blocks = (DAYS.some(([k]) => k === day) ? data.schedule[day] : []).slice().sort((a, b) => String(a.start).localeCompare(String(b.start)));
    const soon = data.reminders.filter((r) => !r.done).sort((a, b) => String(a.at).localeCompare(String(b.at))).slice(0, 4);
    $("page-today").innerHTML = `
      <div class="grid-2">
        <article class="card">
          <h2>Starred to-dos</h2>
          ${starred.length ? `<div class="list">${starred.map(todoRow).join("")}</div>` : `<p class="empty">Star a to-do and it will land here.</p>`}
        </article>
        <article class="card">
          <h2>Homework coming up</h2>
          ${dueHw.length ? `<div class="list">${dueHw.map((h) => `<div class="row"><div class="grow"><strong>${escapeHtml(h.title)}</strong><span class="sub">${escapeHtml(h.subject || "Class")} · ${dueLabel(h.due)}</span></div></div>`).join("")}</div>` : `<p class="empty">No open homework cards.</p>`}
        </article>
        <article class="card">
          <h2>${day === "sat" || day === "sun" ? "Weekend" : "Today's classes"}</h2>
          ${blocks.length ? blocks.map((b) => `<div class="block"><time>${escapeHtml(b.start || "")}${b.end ? "–" + escapeHtml(b.end) : ""}</time><strong>${escapeHtml(b.title)}</strong>${b.place ? `<span class="sub">${escapeHtml(b.place)}</span>` : ""}</div>`).join("") : `<p class="empty">${day === "sat" || day === "sun" ? "School week is Monday–Friday." : "Nothing on today's schedule yet."}</p>`}
        </article>
        <article class="card">
          <h2>Reminders</h2>
          ${soon.length ? `<div class="list">${soon.map((r) => `<div class="row"><div class="grow"><strong>${escapeHtml(r.title)}</strong><span class="sub">${fmtWhen(r.at)}</span></div></div>`).join("")}</div>` : `<p class="empty">No upcoming reminders.</p>`}
        </article>
      </div>
      <p class="muted">Today is ${now.toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" })}.</p>
    `;
    bindTodos($("page-today"));
  }

  function todoRow(t) {
    return `<div class="row ${t.done ? "done" : ""}" data-id="${t.id}" draggable="true">
      <button type="button" class="grip" data-act="grip" aria-label="Reorder">⋮⋮</button>
      <button type="button" class="check" data-act="done" aria-label="Done">${t.done ? "✓" : ""}</button>
      <div class="grow">${escapeHtml(t.text)}</div>
      <button type="button" class="star ${t.starred ? "on" : ""}" data-act="star" aria-label="Star">${t.starred ? "★" : "☆"}</button>
      <button type="button" class="x" data-act="del" aria-label="Delete">✕</button>
    </div>`;
  }

  function renderTodos() {
    $("page-todos").innerHTML = `
      <article class="card">
        <h2>To-Do</h2>
        <form id="todo-form" class="composer-row" style="grid-template-columns:1fr auto">
          <input id="todo-text" placeholder="Add a to-do" required>
          <button class="btn primary" type="submit">Add</button>
        </form>
        <div class="list" id="todo-list" style="margin-top:12px">${data.todos.length ? data.todos.map(todoRow).join("") : `<p class="empty">Nothing here yet. Add one above.</p>`}</div>
      </article>
    `;
    $("todo-form").addEventListener("submit", (e) => {
      e.preventDefault();
      const text = $("todo-text").value.trim();
      if (!text) return;
      data.todos.push({ id: uid(), text, done: false, starred: false, createdAt: new Date().toISOString() });
      changed();
    });
    bindTodos($("page-todos"));
  }

  function bindTodos(root) {
    root.querySelectorAll(".row[data-id]").forEach((row) => {
      const id = row.dataset.id;
      row.addEventListener("click", (e) => {
        const act = e.target.closest("[data-act]")?.dataset.act;
        const item = data.todos.find((t) => t.id === id);
        if (!item || !act) return;
        if (act === "done") item.done = !item.done;
        if (act === "star") item.starred = !item.starred;
        if (act === "del") data.todos = data.todos.filter((t) => t.id !== id);
        if (act !== "grip") changed();
      });
      row.addEventListener("dragstart", () => { draggingId = id; row.classList.add("dragging"); });
      row.addEventListener("dragend", () => {
        row.classList.remove("dragging");
        if (!draggingId) return;
        draggingId = "";
        cacheLocal();
        setSync("Saving…", "busy");
        clearTimeout(saveTimer);
        saveTimer = setTimeout(pushSync, 400);
      });
      row.addEventListener("dragover", (e) => {
        e.preventDefault();
        const over = data.todos.findIndex((t) => t.id === id);
        const from = data.todos.findIndex((t) => t.id === draggingId);
        if (over < 0 || from < 0 || over === from) return;
        const [moved] = data.todos.splice(from, 1);
        data.todos.splice(over, 0, moved);
        const list = row.parentElement;
        const rows = [...list.querySelectorAll(".row[data-id]")];
        const fromEl = rows.find((el) => el.dataset.id === draggingId);
        if (!fromEl || fromEl === row) return;
        if (from < over) list.insertBefore(fromEl, row.nextSibling);
        else list.insertBefore(fromEl, row);
      });
    });
  }

  function renderHomework() {
    $("page-homework").innerHTML = `
      <article class="card">
        <h2>New homework card</h2>
        <form id="hw-form" class="composer">
          <div class="composer-row">
            <input id="hw-subject" placeholder="Class / subject" required>
            <input id="hw-title" placeholder="Assignment" required>
          </div>
          <div class="composer-row">
            <input id="hw-due" type="date">
            <input id="hw-notes" placeholder="Notes (optional)">
          </div>
          <button class="btn primary" type="submit">Add card</button>
        </form>
      </article>
      <div class="hw-grid" id="hw-list">
        ${data.homework.length ? data.homework.map((h) => `
          <article class="hw-card ${h.done ? "done" : ""}" data-id="${h.id}">
            <span class="chip ${soonChip(h.due)}">${escapeHtml(h.subject || "Class")}</span>
            <strong>${escapeHtml(h.title)}</strong>
            <span class="sub">${dueLabel(h.due)}</span>
            ${h.notes ? `<p class="empty">${escapeHtml(h.notes)}</p>` : ""}
            <div class="btn-row">
              <button type="button" class="btn tiny ghost" data-act="done">${h.done ? "Open" : "Done"}</button>
              <button type="button" class="btn tiny ghost" data-act="del">Delete</button>
            </div>
          </article>`).join("") : `<p class="empty">Homework cards you add will show up here.</p>`}
      </div>
    `;
    $("hw-form").addEventListener("submit", (e) => {
      e.preventDefault();
      const hw = {
        id: uid(),
        subject: $("hw-subject").value.trim(),
        title: $("hw-title").value.trim(),
        due: $("hw-due").value || "",
        notes: $("hw-notes").value.trim(),
        done: false,
      };
      data.homework.unshift(hw);
      addHomeworkReminder(hw);
      changed();
    });
    $("hw-list").addEventListener("click", (e) => {
      const card = e.target.closest(".hw-card");
      const act = e.target.closest("[data-act]")?.dataset.act;
      if (!card || !act) return;
      const hw = data.homework.find((h) => h.id === card.dataset.id);
      if (!hw) return;
      if (act === "done") hw.done = !hw.done;
      if (act === "del") {
        data.homework = data.homework.filter((h) => h.id !== hw.id);
        data.reminders = data.reminders.filter((r) => r.source !== hw.id);
      }
      changed();
    });
  }

  function soonChip(due) {
    if (!due) return "";
    const t = new Date(due + "T12:00:00");
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    const diff = (t - now) / 86400000;
    return diff <= 1 ? "due-soon" : "";
  }

  function renderSchedule() {
    const today = todayKey();
    $("page-schedule").innerHTML = `
      <article class="card">
        <h2>Add to the week</h2>
        <form id="sked-form" class="composer">
          <div class="composer-row">
            <select id="sked-day">${DAYS.map(([k, n]) => `<option value="${k}">${n}</option>`).join("")}</select>
            <input id="sked-title" placeholder="Class or activity" required>
          </div>
          <div class="composer-row">
            <input id="sked-start" type="time" value="08:00" required>
            <input id="sked-end" type="time" value="08:20">
          </div>
          <input id="sked-place" placeholder="Room or place (optional)">
          <button class="btn primary" type="submit">Add to schedule</button>
        </form>
      </article>
      <div class="week">
        ${DAYS.map(([k, name]) => {
          const items = data.schedule[k].slice().sort((a, b) => String(a.start).localeCompare(String(b.start)));
          return `<section class="day-col ${k === today ? "today" : ""}">
            <h3>${name}</h3>
            ${items.length ? items.map((b) => `<div class="block" data-day="${k}" data-id="${b.id}">
              <time>${escapeHtml(b.start || "")}${b.end ? "–" + escapeHtml(b.end) : ""}</time>
              <strong>${escapeHtml(b.title)}</strong>
              ${b.place ? `<span class="sub">${escapeHtml(b.place)}</span>` : ""}
              <button type="button" class="btn tiny ghost" data-act="del">Remove</button>
            </div>`).join("") : `<p class="empty">Free</p>`}
          </section>`;
        }).join("")}
      </div>
    `;
    if (DAYS.some(([k]) => k === today)) $("sked-day").value = today;
    $("sked-form").addEventListener("submit", (e) => {
      e.preventDefault();
      const day = $("sked-day").value;
      data.schedule[day].push({
        id: uid(),
        title: $("sked-title").value.trim(),
        start: $("sked-start").value,
        end: $("sked-end").value,
        place: $("sked-place").value.trim(),
      });
      changed();
    });
    $("page-schedule").addEventListener("click", (e) => {
      const block = e.target.closest(".block[data-id]");
      if (!block || e.target.dataset.act !== "del") return;
      const day = block.dataset.day;
      data.schedule[day] = data.schedule[day].filter((b) => b.id !== block.dataset.id);
      changed();
    });
  }

  function renderNotes() {
    if (!data.folders.some((f) => f.id === folderId)) folderId = data.folders[0]?.id || "general";
    const notes = data.notes.filter((n) => n.folderId === folderId).sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
    const current = data.notes.find((n) => n.id === noteId) || notes[0] || null;
    if (current) noteId = current.id;
    $("page-notes").innerHTML = `
      <article class="card">
        <h2>Folders</h2>
        <div class="folder-row">
          ${data.folders.map((f) => `<button type="button" class="folder ${f.id === folderId ? "on" : ""}" data-folder="${f.id}">${escapeHtml(f.name)}</button>`).join("")}
          <form id="folder-form" style="display:flex;gap:8px;flex:1;min-width:180px">
            <input id="folder-name" placeholder="New folder" required>
            <button class="btn tiny primary" type="submit">Add</button>
          </form>
        </div>
      </article>
      <div class="grid-2">
        <article class="card">
          <div class="btn-row" style="margin-bottom:10px">
            <button type="button" id="new-note" class="btn primary">New note</button>
          </div>
          <div class="list">
            ${notes.length ? notes.map((n) => `<button type="button" class="row note-item ${n.id === noteId ? "on" : ""}" data-note="${n.id}">
              <div class="grow"><strong>${escapeHtml(n.title || "Untitled")}</strong><span class="sub">${escapeHtml((n.body || "").slice(0, 80))}</span></div>
            </button>`).join("") : `<p class="empty">No notes in this folder.</p>`}
          </div>
        </article>
        <article class="card note-editor">
          ${current ? `
            <input id="note-title" value="${escapeHtml(current.title || "")}" placeholder="Title">
            <textarea id="note-body" placeholder="Write anything…">${escapeHtml(current.body || "")}</textarea>
            <button type="button" id="del-note" class="btn ghost">Delete note</button>
          ` : `<p class="empty">Pick a note or start a new one.</p>`}
        </article>
      </div>
    `;
    $("folder-form").addEventListener("submit", (e) => {
      e.preventDefault();
      const name = $("folder-name").value.trim();
      const id = uid();
      data.folders.push({ id, name });
      folderId = id;
      changed();
    });
    $("page-notes").querySelectorAll("[data-folder]").forEach((btn) => {
      btn.addEventListener("click", () => { folderId = btn.dataset.folder; noteId = ""; render(); });
    });
    $("new-note").addEventListener("click", () => {
      const n = { id: uid(), folderId, title: "Untitled", body: "", updatedAt: new Date().toISOString() };
      data.notes.unshift(n);
      noteId = n.id;
      changed();
    });
    $("page-notes").querySelectorAll("[data-note]").forEach((btn) => {
      btn.addEventListener("click", () => { noteId = btn.dataset.note; render(); });
    });
    if (current) {
      const saveNote = () => {
        current.title = $("note-title").value;
        current.body = $("note-body").value;
        current.updatedAt = new Date().toISOString();
        changed();
      };
      $("note-title").addEventListener("change", saveNote);
      $("note-body").addEventListener("change", saveNote);
      $("del-note").addEventListener("click", () => {
        data.notes = data.notes.filter((n) => n.id !== current.id);
        noteId = "";
        changed();
      });
    }
  }

  function renderCalendar() {
    const year = calCursor.getFullYear();
    const month = calCursor.getMonth();
    const first = new Date(year, month, 1);
    const startPad = first.getDay();
    const daysIn = new Date(year, month + 1, 0).getDate();
    const cells = [];
    for (let i = 0; i < startPad; i++) cells.push({ out: true, d: new Date(year, month, i - startPad + 1) });
    for (let d = 1; d <= daysIn; d++) cells.push({ out: false, d: new Date(year, month, d) });
    while (cells.length % 7) cells.push({ out: true, d: new Date(year, month + 1, cells.length - (startPad + daysIn) + 1) });
    const dayEvents = data.calendar.filter((e) => e.date === selectedDate).sort((a, b) => String(a.time || "").localeCompare(String(b.time || "")));
    $("page-calendar").innerHTML = `
      <article class="card">
        <div class="cal-head">
          <button type="button" class="icon-btn" id="cal-prev" aria-label="Previous month">‹</button>
          <h2>${MONTHS[month]} ${year}</h2>
          <button type="button" class="icon-btn" id="cal-next" aria-label="Next month">›</button>
        </div>
        <div class="cal-grid" style="margin-top:10px">
          ${DOW.map((d) => `<div class="cal-dow">${d}</div>`).join("")}
          ${cells.map((c) => {
            const iso = isoDate(c.d);
            const has = data.calendar.some((e) => e.date === iso);
            return `<button type="button" class="cal-cell ${c.out ? "out" : ""} ${iso === selectedDate ? "on" : ""} ${has ? "has" : ""}" data-date="${iso}">${c.d.getDate()}</button>`;
          }).join("")}
        </div>
      </article>
      <article class="card">
        <h2>${new Date(selectedDate + "T12:00:00").toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" })}</h2>
        <form id="cal-form" class="composer">
          <div class="composer-row">
            <input id="cal-title" placeholder="Event name" required>
            <input id="cal-time" type="time">
          </div>
          <input id="cal-notes" placeholder="Notes (optional)">
          <button class="btn primary" type="submit">Add event</button>
        </form>
        <div class="list" style="margin-top:12px">
          ${dayEvents.length ? dayEvents.map((e) => `<div class="row" data-id="${e.id}">
            <div class="grow"><strong>${escapeHtml(e.title)}</strong><span class="sub">${e.time ? escapeHtml(e.time) : "All day"}${e.notes ? " · " + escapeHtml(e.notes) : ""}</span></div>
            <button type="button" class="x" data-act="del">✕</button>
          </div>`).join("") : `<p class="empty">Nothing on this day.</p>`}
        </div>
      </article>
    `;
    $("cal-prev").addEventListener("click", () => { calCursor = new Date(year, month - 1, 1); render(); });
    $("cal-next").addEventListener("click", () => { calCursor = new Date(year, month + 1, 1); render(); });
    $("page-calendar").querySelectorAll("[data-date]").forEach((btn) => {
      btn.addEventListener("click", () => { selectedDate = btn.dataset.date; render(); });
    });
    $("cal-form").addEventListener("submit", (e) => {
      e.preventDefault();
      data.calendar.push({
        id: uid(),
        title: $("cal-title").value.trim(),
        date: selectedDate,
        time: $("cal-time").value,
        notes: $("cal-notes").value.trim(),
      });
      changed();
    });
    $("page-calendar").querySelectorAll(".row[data-id]").forEach((row) => {
      row.addEventListener("click", (e) => {
        if (e.target.dataset.act !== "del") return;
        data.calendar = data.calendar.filter((ev) => ev.id !== row.dataset.id);
        changed();
      });
    });
  }

  function fmtWhen(iso) {
    if (!iso) return "";
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return iso;
    return d.toLocaleString(undefined, { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
  }

  function renderReminders() {
    const open = data.reminders.slice().sort((a, b) => String(a.at).localeCompare(String(b.at)));
    $("page-reminders").innerHTML = `
      <article class="card">
        <h2>Add a reminder</h2>
        <form id="rem-form" class="composer">
          <input id="rem-title" placeholder="Remember to…" required>
          <div class="composer-row">
            <input id="rem-date" type="date" required>
            <input id="rem-time" type="time" required>
          </div>
          <button class="btn primary" type="submit">Add reminder</button>
        </form>
      </article>
      <article class="card">
        <h2>Reminders</h2>
        <div class="list">
          ${open.length ? open.map((r) => `<div class="row ${r.done ? "done" : ""}" data-id="${r.id}">
            <button type="button" class="check" data-act="done">${r.done ? "✓" : ""}</button>
            <div class="grow"><strong>${escapeHtml(r.title)}</strong><span class="sub">${fmtWhen(r.at)}</span></div>
            <button type="button" class="x" data-act="del">✕</button>
          </div>`).join("") : `<p class="empty">No reminders yet.</p>`}
        </div>
      </article>
    `;
    $("rem-date").value = selectedDate;
    $("rem-form").addEventListener("submit", (e) => {
      e.preventDefault();
      data.reminders.push({
        id: uid(),
        title: $("rem-title").value.trim(),
        at: new Date($("rem-date").value + "T" + $("rem-time").value + ":00").toISOString(),
        done: false,
        source: "custom",
      });
      changed();
    });
    $("page-reminders").querySelectorAll(".row[data-id]").forEach((row) => {
      row.addEventListener("click", (e) => {
        const act = e.target.closest("[data-act]")?.dataset.act;
        const rem = data.reminders.find((r) => r.id === row.dataset.id);
        if (!rem || !act) return;
        if (act === "done") rem.done = !rem.done;
        if (act === "del") data.reminders = data.reminders.filter((r) => r.id !== rem.id);
        changed();
      });
    });
  }

  function maybeNotify() {
    if (!data.settings.notify || !("Notification" in window) || Notification.permission !== "granted") return;
    const now = Date.now();
    data.reminders.forEach((r) => {
      if (r.done || r.pinged) return;
      const t = new Date(r.at).getTime();
      if (!t || t > now) return;
      r.pinged = true;
      try { new Notification("Virginia's Hub", { body: r.title, icon: "/icons/icon-192.png" }); }
      catch { /* ignore */ }
    });
  }

  function render() {
    setTab();
    if (hubScreen.hidden) return;
    $("greeting").textContent = greeting();
    if (tab === "today") renderToday();
    if (tab === "todos") renderTodos();
    if (tab === "homework") renderHomework();
    if (tab === "schedule") renderSchedule();
    if (tab === "notes") renderNotes();
    if (tab === "calendar") renderCalendar();
    if (tab === "reminders") renderReminders();
    maybeNotify();
  }

  const standalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone;
  if (!standalone) $("install-hint").hidden = false;

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "hidden") pushSync();
  });
  window.addEventListener("pagehide", () => { if (token) cacheLocal(); });

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }

  boot();
})();
