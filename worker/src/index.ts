export interface Env {
  GITHUB_CLIENT_ID: string;
  GITHUB_CLIENT_SECRET: string;
}

const APP_REDIRECT = "myprs://auth";
const GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/callback") {
      return handleCallback(url, env);
    }
    return new Response("Not found", { status: 404 });
  },
};

async function handleCallback(url: URL, env: Env): Promise<Response> {
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  if (!code || !state) {
    return redirectToApp({ error: "invalid_request", state: state ?? "" });
  }

  const result = await exchangeCodeForToken(code, env);
  if ("token" in result) {
    return redirectToApp({ token: result.token, state });
  }
  return redirectToApp({ error: result.error, state });
}

type TokenResult = { token: string } | { error: string };

async function exchangeCodeForToken(code: string, env: Env): Promise<TokenResult> {
  try {
    const response = await fetch(GITHUB_TOKEN_URL, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: env.GITHUB_CLIENT_ID,
        client_secret: env.GITHUB_CLIENT_SECRET,
        code,
      }),
    });
    const body = (await response.json()) as { access_token?: unknown; error?: unknown };
    if (typeof body.access_token === "string" && body.access_token) return { token: body.access_token };
    return { error: typeof body.error === "string" ? body.error : "exchange_failed" };
  } catch {
    return { error: "exchange_failed" };
  }
}

function redirectToApp(params: Record<string, string>): Response {
  const appURL = `${APP_REDIRECT}?${new URLSearchParams(params)}`;
  return new Response(returnPage(appURL, params.error), {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "referrer-policy": "no-referrer",
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'",
    },
  });
}

function returnPage(appURL: string, error?: string): string {
  const message = error
    ? `Sign-in failed: ${escapeHTML(error)}. Return to MyPRs and try again.`
    : "Signed in — returning to MyPRs. You can close this tab.";
  const href = escapeHTML(appURL);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="0;url=${href}">
<title>MyPRs</title>
<style>
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; font: 16px system-ui, sans-serif; text-align: center; color-scheme: light dark; }
  main { max-width: 28rem; padding: 1.5rem; }
  a { display: inline-block; margin-top: 1rem; }
</style>
</head>
<body>
<main>
<p>${message}</p>
<a href="${href}">Open MyPRs</a>
</main>
<script>location.replace(${JSON.stringify(appURL).replace(/</g, "\\u003c")});</script>
</body>
</html>`;
}

function escapeHTML(text: string): string {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
