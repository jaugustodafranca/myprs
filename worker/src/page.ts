export type PageVariant = "success" | "error";

export interface PageOptions {
  variant: PageVariant;
  appURL: string;
  error?: string;
}

const SOURCE_CODE_URL = "https://github.com/jaugustodafranca/myprs";

// Static so the Content-Security-Policy can allow it by hash instead of 'unsafe-inline'.
// The app URL is read from the button, which is the only place it is rendered.
export const PAGE_SCRIPT = `var link = document.getElementById("open-app");
location.replace(link.href);
if (document.body.dataset.variant === "success") {
  setTimeout(function () { document.getElementById("message").textContent = "You can close this tab."; }, 1500);
}`;

// sha256 of PAGE_SCRIPT; a test fails if they drift apart.
export const PAGE_SCRIPT_HASH = "sha256-XvSeg7Zko3WRO/FhfAwyBPVof9kweuhEUHe+2/WUAyw=";

export function renderPage({ variant, appURL, error }: PageOptions): string {
  const href = escapeHTML(appURL);
  const content = variant === "success" ? successContent() : errorContent(error ?? "");
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<meta http-equiv="refresh" content="0;url=${href}">
<title>MyPRs</title>
<style>${styles}</style>
</head>
<body data-variant="${variant}">
<main class="card">
${logoSVG}
${content.badge}
<h1>${content.title}</h1>
<p id="message" class="message">${content.message}</p>
<a id="open-app" class="button" href="${href}">Open MyPRs</a>
<p class="hint">Didn't open? Click the button above.</p>
<p class="trust">${lockIcon}<span>Your GitHub token is sent only to the MyPRs app on your Mac, never to this page. Nothing is stored on our servers. <a href="${SOURCE_CODE_URL}">Source code</a></span></p>
</main>
<script>${PAGE_SCRIPT}</script>
</body>
</html>`;
}

function successContent() {
  return {
    badge: `<svg class="badge success" viewBox="0 0 52 52" aria-hidden="true"><circle class="badge-circle" cx="26" cy="26" r="24"/><path class="badge-mark" d="M15 27 l8 8 l14 -16"/></svg>`,
    title: "Authorized on GitHub",
    message: "Returning to MyPRs…",
  };
}

function errorContent(error: string) {
  return {
    badge: `<svg class="badge failure" viewBox="0 0 52 52" aria-hidden="true"><circle class="badge-circle" cx="26" cy="26" r="24"/><path class="badge-mark" d="M26 14 v15"/><circle class="badge-dot" cx="26" cy="37" r="2.4"/></svg>`,
    title: "Sign-in didn't complete",
    message: `${escapeHTML(error)}. Return to MyPRs and try again.`,
  };
}

function escapeHTML(text: string): string {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

const lockIcon = `<svg class="lock" viewBox="0 0 16 16" aria-hidden="true"><rect x="3" y="7" width="10" height="7" rx="1.8"/><path d="M5.2 7 V5.2 a2.8 2.8 0 0 1 5.6 0 V7"/></svg>`;

// Ids are prefixed so they cannot clash with anything else on the page.
const logoSVG = `<svg class="logo" viewBox="100 100 824 824" role="img" aria-label="MyPRs">
<defs>
<linearGradient id="mp-bg" x1="0.2" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#5B8CFF"/><stop offset="0.55" stop-color="#3A4FE0"/><stop offset="1" stop-color="#241A8C"/></linearGradient>
<linearGradient id="mp-gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.28"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="mp-rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.55"/><stop offset="0.4" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.25"/></linearGradient>
<linearGradient id="mp-glyph" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#DCE5FF"/></linearGradient>
<radialGradient id="mp-green" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#6BF08F"/><stop offset="1" stop-color="#1FB854"/></radialGradient>
<radialGradient id="mp-orange" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#FFC15A"/><stop offset="1" stop-color="#F08A12"/></radialGradient>
<radialGradient id="mp-red" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#FF7A70"/><stop offset="1" stop-color="#E0352B"/></radialGradient>
</defs>
<rect x="100" y="100" width="824" height="824" rx="185" fill="url(#mp-bg)"/>
<rect x="100" y="100" width="824" height="824" rx="185" fill="url(#mp-gloss)"/>
<rect x="102" y="102" width="820" height="820" rx="183" fill="none" stroke="url(#mp-rim)" stroke-width="4"/>
<g transform="translate(0 -20)" fill="none" stroke="url(#mp-glyph)" stroke-width="46" stroke-linecap="round" stroke-linejoin="round">
<path d="M364 394 V574"/><path d="M660 574 V470 Q660 360 550 360 H470"/><path d="M514 308 L462 360 L514 412"/>
<circle cx="364" cy="318" r="52" fill="#3F55E6"/><circle cx="364" cy="650" r="52" fill="#3F55E6"/><circle cx="660" cy="650" r="52" fill="#3F55E6"/>
</g>
<circle cx="420" cy="806" r="30" fill="url(#mp-green)"/><circle cx="512" cy="806" r="30" fill="url(#mp-orange)"/><circle cx="604" cy="806" r="30" fill="url(#mp-red)"/>
</svg>`;

const styles = `
:root {
  --blue: #3A4FE0;
  --blue-hover: #2F43CC;
  --text: #14172B;
  --muted: #5F6580;
  --card: rgba(255, 255, 255, 0.82);
  --border: rgba(36, 26, 140, 0.12);
  --shadow: 0 1px 2px rgba(20, 23, 43, 0.06), 0 12px 40px rgba(58, 79, 224, 0.16);
  --green: #1FB854;
  --red: #E0352B;
  --page: radial-gradient(900px 600px at 15% -10%, rgba(91, 140, 255, 0.28), transparent 60%),
          radial-gradient(800px 600px at 100% 110%, rgba(58, 79, 224, 0.22), transparent 60%),
          #F4F6FE;
}
@media (prefers-color-scheme: dark) {
  :root {
    --blue: #5B7CFF;
    --blue-hover: #7390FF;
    --text: #EEF0FB;
    --muted: #9AA0C0;
    --card: rgba(26, 28, 58, 0.72);
    --border: rgba(255, 255, 255, 0.1);
    --shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 16px 48px rgba(0, 0, 0, 0.5);
    --page: radial-gradient(900px 600px at 15% -10%, rgba(58, 79, 224, 0.4), transparent 60%),
            radial-gradient(800px 600px at 100% 110%, rgba(36, 26, 140, 0.55), transparent 60%),
            #0C0D1F;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px 16px;
  background: var(--page);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
}
.card {
  width: 100%;
  max-width: 420px;
  padding: 36px 32px 28px;
  text-align: center;
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 20px;
  box-shadow: var(--shadow);
  -webkit-backdrop-filter: blur(20px);
  backdrop-filter: blur(20px);
  animation: rise 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) both;
}
.logo {
  display: block;
  margin: 0 auto;
  width: 72px;
  height: 72px;
  filter: drop-shadow(0 8px 14px rgba(36, 26, 140, 0.35));
}
.badge { display: block; width: 44px; height: 44px; margin: 20px auto 0; overflow: visible; }
.badge-circle { fill: none; stroke-width: 3; stroke-dasharray: 151; stroke-dashoffset: 151; animation: draw 0.6s 0.3s ease-out forwards; }
.badge-mark { fill: none; stroke-width: 4; stroke-linecap: round; stroke-linejoin: round; stroke-dasharray: 40; stroke-dashoffset: 40; animation: draw 0.4s 0.8s ease-out forwards; }
.badge-dot { stroke: none; opacity: 0; animation: appear 0.2s 1s forwards; }
.success .badge-circle, .success .badge-mark { stroke: var(--green); }
.failure .badge-circle, .failure .badge-mark { stroke: var(--red); }
.failure .badge-dot { fill: var(--red); }
h1 { margin: 14px 0 6px; font-size: 24px; line-height: 1.2; font-weight: 650; letter-spacing: -0.02em; }
.message { margin: 0 0 24px; font-size: 15px; line-height: 1.5; color: var(--muted); overflow-wrap: anywhere; }
.button {
  display: block;
  padding: 12px 20px;
  border-radius: 12px;
  background: var(--blue);
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  text-decoration: none;
  box-shadow: 0 6px 16px rgba(58, 79, 224, 0.35);
  transition: background 0.15s, transform 0.15s;
}
.button:hover { background: var(--blue-hover); }
.button:active { transform: scale(0.98); }
.button:focus-visible { outline: 3px solid rgba(91, 140, 255, 0.55); outline-offset: 2px; }
.hint { margin: 10px 0 0; font-size: 13px; color: var(--muted); }
.trust {
  display: flex;
  gap: 8px;
  align-items: flex-start;
  margin: 26px 0 0;
  padding-top: 18px;
  border-top: 1px solid var(--border);
  font-size: 12px;
  line-height: 1.5;
  text-align: left;
  color: var(--muted);
}
.trust a { color: inherit; text-decoration: underline; text-underline-offset: 2px; white-space: nowrap; }
.trust a:hover { color: var(--text); }
.lock { flex: none; width: 14px; height: 14px; margin-top: 2px; fill: none; stroke: currentColor; stroke-width: 1.4; stroke-linecap: round; }
@keyframes rise { from { opacity: 0; transform: translateY(14px); } to { opacity: 1; transform: none; } }
@keyframes draw { to { stroke-dashoffset: 0; } }
@keyframes appear { to { opacity: 1; } }
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; }
  .badge-circle, .badge-mark { stroke-dashoffset: 0; }
  .badge-dot { opacity: 1; }
}
`;
