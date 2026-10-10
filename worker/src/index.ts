import { renderPage } from "./page";

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
  const variant = params.error ? "error" : "success";
  return new Response(renderPage({ variant, appURL, error: params.error }), {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "referrer-policy": "no-referrer",
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'",
    },
  });
}
