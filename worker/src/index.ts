import { PAGE_SCRIPT_HASH, renderPage } from "./page";

export interface Env {
  GITHUB_CLIENT_ID: string;
  GITHUB_CLIENT_SECRET: string;
}

const APP_REDIRECT = "myprs://auth";
const GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token";
const GITHUB_API_URL = "https://api.github.com";

const CODE_PATTERN = /^[0-9a-f]{1,64}$/i;
const CODE_VERIFIER_PATTERN = /^[A-Za-z0-9\-._~]{43,128}$/;
const ACCESS_TOKEN_PATTERN = /^[A-Za-z0-9_]{1,255}$/;
const ERROR_PATTERN = /^[a-z_]{1,64}$/;
const MAX_STATE_LENGTH = 256;

const SECURITY_HEADERS = {
  "cache-control": "no-store",
  "strict-transport-security": "max-age=31536000",
  "x-content-type-options": "nosniff",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/callback") return handleCallback(url);
    if (request.method === "POST" && url.pathname === "/token") return handleToken(request, env);
    if (request.method === "POST" && url.pathname === "/revoke") return handleRevoke(request, env);
    return new Response("Not found", { status: 404, headers: SECURITY_HEADERS });
  },
};

// GitHub redirects here. The code is only handed to the app, which exchanges it
// with its PKCE verifier, so the token never travels through a URL or a page.
function handleCallback(url: URL): Response {
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const gitHubError = url.searchParams.get("error");
  if (!state || state.length > MAX_STATE_LENGTH) return redirectToApp({ error: "invalid_request", state: "" });
  if (gitHubError) {
    const error = ERROR_PATTERN.test(gitHubError) ? gitHubError : "invalid_request";
    return redirectToApp({ error, state });
  }
  if (!code || !CODE_PATTERN.test(code)) return redirectToApp({ error: "invalid_request", state });
  return redirectToApp({ code, state });
}

async function handleToken(request: Request, env: Env): Promise<Response> {
  const body = await readJSON(request);
  if (body instanceof Response) return body;

  const { code, code_verifier: codeVerifier } = body;
  if (typeof code !== "string" || !CODE_PATTERN.test(code)) return json({ error: "invalid_request" }, 400);
  if (typeof codeVerifier !== "string" || !CODE_VERIFIER_PATTERN.test(codeVerifier)) {
    return json({ error: "invalid_request" }, 400);
  }

  const result = await exchangeCodeForToken(code, codeVerifier, env);
  if ("accessToken" in result) return json({ access_token: result.accessToken }, 200);
  return json({ error: result.error }, result.error === "exchange_failed" ? 502 : 400);
}

async function handleRevoke(request: Request, env: Env): Promise<Response> {
  const body = await readJSON(request);
  if (body instanceof Response) return body;

  const { access_token: accessToken } = body;
  if (typeof accessToken !== "string" || !ACCESS_TOKEN_PATTERN.test(accessToken)) {
    return json({ error: "invalid_request" }, 400);
  }

  try {
    const response = await fetch(`${GITHUB_API_URL}/applications/${env.GITHUB_CLIENT_ID}/token`, {
      method: "DELETE",
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Basic ${btoa(`${env.GITHUB_CLIENT_ID}:${env.GITHUB_CLIENT_SECRET}`)}`,
        "Content-Type": "application/json",
        "User-Agent": "myprs-auth",
      },
      body: JSON.stringify({ access_token: accessToken }),
    });
    // 404 means the token is already invalid, which is what the caller wants.
    if (response.ok || response.status === 404) return new Response(null, { status: 204, headers: SECURITY_HEADERS });
  } catch {
    // Reported as revoke_failed below.
  }
  return json({ error: "revoke_failed" }, 502);
}

async function readJSON(request: Request): Promise<Record<string, unknown> | Response> {
  const mediaType = (request.headers.get("content-type") ?? "").split(";")[0].trim().toLowerCase();
  if (mediaType !== "application/json") return json({ error: "unsupported_media_type" }, 415);
  try {
    const body: unknown = await request.json();
    if (typeof body === "object" && body !== null && !Array.isArray(body)) return body as Record<string, unknown>;
  } catch {
    // Reported as invalid_request below.
  }
  return json({ error: "invalid_request" }, 400);
}

type TokenResult = { accessToken: string } | { error: string };

async function exchangeCodeForToken(code: string, codeVerifier: string, env: Env): Promise<TokenResult> {
  try {
    const response = await fetch(GITHUB_TOKEN_URL, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: env.GITHUB_CLIENT_ID,
        client_secret: env.GITHUB_CLIENT_SECRET,
        code,
        code_verifier: codeVerifier,
      }),
    });
    const body = (await response.json()) as { access_token?: unknown; error?: unknown };
    if (typeof body.access_token === "string" && body.access_token) return { accessToken: body.access_token };
    if (typeof body.error === "string" && ERROR_PATTERN.test(body.error)) return { error: body.error };
    return { error: "exchange_failed" };
  } catch {
    return { error: "exchange_failed" };
  }
}

function json(body: object, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...SECURITY_HEADERS, "content-type": "application/json" },
  });
}

function redirectToApp(params: Record<string, string>): Response {
  const appURL = `${APP_REDIRECT}?${new URLSearchParams(params)}`;
  const variant = params.error ? "error" : "success";
  return new Response(renderPage({ variant, appURL, error: params.error }), {
    headers: {
      ...SECURITY_HEADERS,
      "content-type": "text/html; charset=utf-8",
      "referrer-policy": "no-referrer",
      "content-security-policy": `default-src 'none'; style-src 'unsafe-inline'; script-src '${PAGE_SCRIPT_HASH}'; frame-ancestors 'none'`,
    },
  });
}
