// Demo UI for log_api. Plain JS, no build step, served from /ui/ (same
// origin as the API, so no CORS is involved).
//
// Token storage: the access token lives only in memory; the refresh token is
// kept in sessionStorage so a reload keeps you signed in until the tab is
// closed. A real app should weigh this against its own XSS exposure.
(() => {
  "use strict";

  const UI_URL = `${location.origin}/ui/`;
  const REFRESH_KEY = "log_api.refresh_token";
  const PKCE_KEY = "log_api.pkce_verifier";

  const $ = (sel) => document.querySelector(sel);
  const views = ["auth", "reset", "account", "loading"];

  let accessToken = null;
  let refreshing = null;
  let me = null;

  // ---------- messages -------------------------------------------------------

  const MESSAGES = {
    invalid_credentials: "Email o contraseña incorrectos.",
    unconfirmed: "Tenés que confirmar tu email antes de ingresar. Revisá tu casilla.",
    rate_limited: "Demasiados intentos. Esperá un minuto y probá de nuevo.",
    invalid_token: "El link es inválido o ya venció. Pedí uno nuevo.",
    already_confirmed: "Tu email ya estaba confirmado. Ya podés ingresar.",
    invalid_grant: "No se pudo completar el ingreso social (el código venció o ya se usó). Probá de nuevo.",
    access_denied: "Se canceló o falló el ingreso con el proveedor.",
    account_conflict: "Ese email ya tiene una cuenta. Ingresá con tu método original.",
    profile_exists: "Ya tenés un perfil.",
    unauthorized: "Tu sesión venció. Ingresá de nuevo.",
    network: "No se pudo conectar con el servidor.",
  };

  function notify(text, kind = "ok") {
    const el = $("#notice");
    el.textContent = text;
    el.className = `notice ${kind}`;
    el.hidden = !text;
  }

  function errorText(res) {
    const err = res.data && res.data.error;
    if (!err) return `Error inesperado (HTTP ${res.status}).`;
    if (err.code === "validation_failed" && err.details) {
      return Object.values(err.details).flat().join("\n");
    }
    return MESSAGES[err.code] || err.message || `Error (${err.code}).`;
  }

  // ---------- API ------------------------------------------------------------

  async function api(path, { method = "GET", body, auth = false } = {}) {
    const headers = { Accept: "application/json" };
    if (body !== undefined) headers["Content-Type"] = "application/json";
    if (auth && accessToken) headers.Authorization = `Bearer ${accessToken}`;

    let response;
    try {
      response = await fetch(path, {
        method, headers, body: body === undefined ? undefined : JSON.stringify(body),
        credentials: "omit",
      });
    } catch {
      return { ok: false, status: 0, data: { error: { code: "network" } } };
    }
    const text = await response.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch { /* non-JSON body */ }
    return { ok: response.ok, status: response.status, data };
  }

  // Authenticated call; on 401 refreshes the token pair once and retries.
  async function authed(path, opts = {}) {
    if (!accessToken && !(await refresh())) return { ok: false, status: 401, data: { error: { code: "unauthorized" } } };
    let res = await api(path, { ...opts, auth: true });
    if (res.status === 401 && (await refresh())) res = await api(path, { ...opts, auth: true });
    return res;
  }

  function storeTokens(data) {
    accessToken = data.access_token;
    sessionStorage.setItem(REFRESH_KEY, data.refresh_token);
  }

  function clearTokens() {
    accessToken = null;
    sessionStorage.removeItem(REFRESH_KEY);
  }

  // Refresh tokens are single use, so concurrent callers share one request.
  function refresh() {
    const token = sessionStorage.getItem(REFRESH_KEY);
    if (!token) return Promise.resolve(false);
    refreshing ||= api("/auth/refresh", { method: "POST", body: { refresh_token: token } })
      .then((res) => {
        if (res.ok) { storeTokens(res.data); return true; }
        clearTokens();
        return false;
      })
      .finally(() => { refreshing = null; });
    return refreshing;
  }

  // ---------- views ----------------------------------------------------------

  function show(view) {
    for (const v of views) $(`#view-${v}`).hidden = v !== view;
  }

  function showTab(tab) {
    document.querySelectorAll("[role=tab]").forEach((b) => b.setAttribute("aria-selected", String(b.dataset.tab === tab)));
    document.querySelectorAll("[data-panel]").forEach((p) => { p.hidden = p.dataset.panel !== tab; });
    $("#social").hidden = tab === "forgot" || !$("#social-buttons").children.length;
    const first = $(`[data-panel="${tab}"] input`);
    if (first) first.focus();
  }

  function formData(form) {
    return Object.fromEntries(new FormData(form).entries());
  }

  // Disables the form's buttons while the request runs.
  function busy(form, fn) {
    return async (event) => {
      event.preventDefault();
      const buttons = form.querySelectorAll("button");
      buttons.forEach((b) => { b.disabled = true; });
      try { await fn(formData(form)); } finally { buttons.forEach((b) => { b.disabled = false; }); }
    };
  }

  function passwordsMismatch(data) {
    if (data.password !== data.password_confirmation) {
      notify("Las contraseñas no coinciden.", "error");
      return true;
    }
    return false;
  }

  // ---------- account --------------------------------------------------------

  async function loadAccount() {
    const res = await authed("/me");
    if (!res.ok) {
      clearTokens();
      show("auth");
      showTab("login");
      if (res.status !== 401) notify(errorText(res), "error");
      return;
    }
    renderAccount(res.data.user);
    show("account");
  }

  function renderAccount(user) {
    me = user;
    const label = user.name && user.name !== "None" ? user.name : user.email;
    $("#avatar").textContent = label.trim().charAt(0).toUpperCase();
    $("#account-name").textContent = label;
    $("#account-email").textContent = user.email;
    const via = user.provider ? `Vinculada con ${providerLabel(user.provider)}` : "Email y contraseña";
    const since = new Date(user.created_at).toLocaleDateString("es");
    $("#account-meta").textContent = `${via} · desde ${since}`;

    const nameForm = $("#form-name");
    nameForm.elements.name.value = user.name && user.name !== "None" ? user.name : "";

    const profile = user.profile || {};
    const pf = $("#form-profile");
    pf.elements.display_name.value = profile.display_name || "";
    pf.elements.location.value = profile.location || "";
    pf.elements.bio.value = profile.bio || "";
    $("#profile-submit").textContent = user.profile ? "Guardar perfil" : "Crear perfil";
  }

  // ---------- social login (OAuth + PKCE) ------------------------------------

  const PROVIDER_LABELS = { google_oauth2: "Google", facebook: "Facebook", github: "GitHub", twitter: "X / Twitter" };
  const providerLabel = (name) => PROVIDER_LABELS[name] || name;

  function base64url(bytes) {
    return btoa(String.fromCharCode(...new Uint8Array(bytes)))
      .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }

  async function startSocialLogin(provider) {
    const verifier = base64url(crypto.getRandomValues(new Uint8Array(32)));
    const challenge = base64url(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier)));
    sessionStorage.setItem(PKCE_KEY, verifier);
    const params = new URLSearchParams({ return_to: UI_URL, code_challenge: challenge, code_challenge_method: "S256" });
    location.assign(`/auth/${encodeURIComponent(provider)}?${params}`);
  }

  async function loadProviders() {
    const res = await api("/auth/providers");
    const box = $("#social-buttons");
    box.replaceChildren();
    if (!res.ok) return;
    for (const p of res.data.providers) {
      const b = document.createElement("button");
      b.type = "button";
      b.textContent = providerLabel(p.name);
      b.addEventListener("click", () => {
        if (!window.crypto || !crypto.subtle) {
          notify("El ingreso social necesita HTTPS o localhost.", "error");
          return;
        }
        startSocialLogin(p.name);
      });
      box.appendChild(b);
    }
  }

  // ---------- links that land on this page -----------------------------------

  // Handles ?confirmation_token, ?reset_password_token, ?code and ?error, then
  // removes them from the address bar. Returns true if a view was chosen.
  async function handleLanding() {
    const q = new URLSearchParams(location.search);
    if ([...q.keys()].length) history.replaceState(null, "", UI_URL);

    if (q.has("confirmation_token")) {
      const res = await api("/auth/confirmation", { method: "POST", body: { confirmation_token: q.get("confirmation_token") } });
      if (res.ok) notify("¡Email confirmado! Ya podés ingresar.");
      else notify(errorText(res), res.data?.error?.code === "already_confirmed" ? "ok" : "error");
      return false;
    }

    if (q.has("reset_password_token")) {
      $("#form-reset").dataset.token = q.get("reset_password_token");
      show("reset");
      return true;
    }

    if (q.has("error")) {
      notify(MESSAGES[q.get("error")] || "No se pudo ingresar con el proveedor.", "error");
      return false;
    }

    if (q.has("code")) {
      const verifier = sessionStorage.getItem(PKCE_KEY);
      sessionStorage.removeItem(PKCE_KEY);
      if (!verifier) {
        notify("El ingreso social se inició en otra pestaña o navegador. Probá de nuevo.", "error");
        return false;
      }
      const res = await api("/auth/oauth/token", {
        method: "POST", body: { code: q.get("code"), code_verifier: verifier, return_to: UI_URL },
      });
      if (!res.ok) { notify(errorText(res), "error"); return false; }
      storeTokens(res.data);
      notify(`¡Hola${res.data.user.name && res.data.user.name !== "None" ? `, ${res.data.user.name}` : ""}!`);
      await loadAccount();
      return true;
    }
    return false;
  }

  // ---------- wiring ---------------------------------------------------------

  document.querySelectorAll("[data-tab]").forEach((b) => b.addEventListener("click", () => {
    notify("");
    $("#resend-confirmation").hidden = true;
    showTab(b.dataset.tab);
  }));

  const login = $("#form-login");
  login.addEventListener("submit", busy(login, async (data) => {
    const res = await api("/auth/sign_in", { method: "POST", body: { email: data.email, password: data.password } });
    if (!res.ok) {
      notify(errorText(res), "error");
      $("#resend-confirmation").hidden = res.data?.error?.code !== "unconfirmed";
      return;
    }
    storeTokens(res.data);
    login.reset();
    notify("");
    await loadAccount();
  }));

  $("#resend-confirmation").addEventListener("click", async () => {
    const email = login.elements.email.value;
    const res = await api("/auth/confirmation/resend", { method: "POST", body: { email } });
    notify(res.ok ? "Si la cuenta existe y no está confirmada, te enviamos un link nuevo." : errorText(res), res.ok ? "ok" : "error");
  });

  const register = $("#form-register");
  register.addEventListener("submit", busy(register, async (data) => {
    if (passwordsMismatch(data)) return;
    const body = { email: data.email, password: data.password, password_confirmation: data.password_confirmation };
    if (data.name) body.name = data.name;
    const res = await api("/auth/sign_up", { method: "POST", body });
    if (!res.ok) { notify(errorText(res), "error"); return; }
    register.reset();
    showTab("login");
    login.elements.email.value = body.email;
    notify("Listo. Te enviamos un email para confirmar la cuenta: abrí el link y después ingresá.\n(En desarrollo el email queda en tmp/mails/.)");
  }));

  const forgot = $("#form-forgot");
  forgot.addEventListener("submit", busy(forgot, async (data) => {
    const res = await api("/auth/password", { method: "POST", body: { email: data.email } });
    if (!res.ok) { notify(errorText(res), "error"); return; }
    forgot.reset();
    showTab("login");
    notify("Si la cuenta existe, te enviamos un link para elegir una contraseña nueva.");
  }));

  const reset = $("#form-reset");
  reset.addEventListener("submit", busy(reset, async (data) => {
    if (passwordsMismatch(data)) return;
    const res = await api("/auth/password", {
      method: "PUT",
      body: { reset_password_token: reset.dataset.token, password: data.password, password_confirmation: data.password_confirmation },
    });
    if (!res.ok) { notify(errorText(res), "error"); return; }
    reset.reset();
    clearTokens();
    show("auth");
    showTab("login");
    notify("Contraseña actualizada. Ingresá con la nueva.");
  }));

  const profileForm = $("#form-profile");
  profileForm.addEventListener("submit", busy(profileForm, async (data) => {
    const res = me.profile
      ? await authed(`/profiles/${me.profile.id}`, { method: "PATCH", body: data })
      : await authed("/profiles", { method: "POST", body: data });
    if (!res.ok) { notify(errorText(res), "error"); return; }
    notify("Perfil guardado.");
    await loadAccount();
  }));

  const nameForm = $("#form-name");
  nameForm.addEventListener("submit", busy(nameForm, async (data) => {
    const res = await authed("/me", { method: "PATCH", body: { name: data.name } });
    if (!res.ok) { notify(errorText(res), "error"); return; }
    renderAccount(res.data.user);
    notify("Nombre actualizado.");
  }));

  const passwordForm = $("#form-password");
  passwordForm.addEventListener("submit", busy(passwordForm, async (data) => {
    if (passwordsMismatch(data)) return;
    const res = await authed("/me", { method: "PATCH", body: data });
    if (!res.ok) { notify(errorText(res), "error"); return; }
    passwordForm.reset();
    // Every refresh token was revoked; sign in again to get a fresh pair.
    clearTokens();
    show("auth");
    showTab("login");
    login.elements.email.value = res.data.user.email;
    notify("Contraseña cambiada. Ingresá de nuevo con la nueva.");
  }));

  async function logout(all) {
    const body = all ? { all: true } : { refresh_token: sessionStorage.getItem(REFRESH_KEY) };
    await authed("/auth/sign_out", { method: "DELETE", body });
    clearTokens();
    me = null;
    show("auth");
    showTab("login");
    notify(all ? "Cerraste la sesión en todos los dispositivos." : "Sesión cerrada.");
  }
  $("#logout").addEventListener("click", () => logout(false));
  $("#logout-all").addEventListener("click", () => logout(true));

  // ---------- boot -----------------------------------------------------------

  (async () => {
    await loadProviders();
    if (await handleLanding()) return;
    if (sessionStorage.getItem(REFRESH_KEY) && (await refresh())) { await loadAccount(); return; }
    show("auth");
    showTab("login");
  })();
})();
