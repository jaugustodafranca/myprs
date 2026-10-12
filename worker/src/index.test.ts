import { afterEach, describe, expect, it, vi } from "vitest";
import worker, { type Env } from "./index";
import { PAGE_SCRIPT, PAGE_SCRIPT_HASH } from "./page";

const env: Env = { GITHUB_CLIENT_ID: "client-id", GITHUB_CLIENT_SECRET: "client-secret" };
const VERIFIER = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk";

function mockGitHub(body: object | null, status = 200) {
  const fetchMock = vi.fn().mockResolvedValue(new Response(body ? JSON.stringify(body) : null, { status }));
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

function appURLIn(html: string): string {
  const match = html.match(/<a id="open-app" class="button" href="([^"]*)">Open MyPRs<\/a>/);
  expect(match).not.toBeNull();
  return match![1].replaceAll("&amp;", "&");
}

async function callback(path: string) {
  const response = await worker.fetch(new Request(`https://auth.example.com${path}`), env);
  const html = await response.text();
  return { response, html, appURL: appURLIn(html) };
}

function post(path: string, body: unknown, contentType = "application/json") {
  return worker.fetch(
    new Request(`https://auth.example.com${path}`, {
      method: "POST",
      headers: { "content-type": contentType },
      body: typeof body === "string" ? body : JSON.stringify(body),
    }),
    env,
  );
}

function expectSecurityHeaders(response: Response) {
  expect(response.headers.get("cache-control")).toBe("no-store");
  expect(response.headers.get("strict-transport-security")).toBe("max-age=31536000");
  expect(response.headers.get("x-content-type-options")).toBe("nosniff");
  expect(response.headers.get("access-control-allow-origin")).toBeNull();
}

afterEach(() => vi.unstubAllGlobals());

describe("GET /callback", () => {
  it("hands the code and state to the app without calling GitHub", async () => {
    const fetchMock = mockGitHub({});

    const { response, html, appURL } = await callback("/callback?code=0123abcdef&state=the-state");

    expect(response.status).toBe(200);
    expect(appURL).toBe("myprs://auth?code=0123abcdef&state=the-state");
    expect(html).toContain('<meta http-equiv="refresh" content="0;url=myprs://auth?code=0123abcdef&amp;state=the-state">');
    expect(html).toContain("Authorized on GitHub");
    expect(html).toContain("Returning to MyPRs…");
    expect(html).not.toContain("Sign-in didn't complete");
    expect(html).toContain("Nothing is stored on our servers.");
    expect(html).toContain('<a href="https://github.com/jaugustodafranca/myprs">Source code</a>');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("sends hardened headers", async () => {
    const { response } = await callback("/callback?code=abc&state=s");

    expectSecurityHeaders(response);
    expect(response.headers.get("content-type")).toBe("text/html; charset=utf-8");
    expect(response.headers.get("referrer-policy")).toBe("no-referrer");
    expect(response.headers.get("content-security-policy")).toBe(
      `default-src 'none'; style-src 'unsafe-inline'; script-src '${PAGE_SCRIPT_HASH}'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`,
    );
  });

  it("renders only the script allowed by the CSP hash", async () => {
    const { html } = await callback("/callback?code=abc&state=s");

    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(PAGE_SCRIPT));
    const expected = `sha256-${btoa(String.fromCharCode(...new Uint8Array(digest)))}`;
    expect(PAGE_SCRIPT_HASH).toBe(expected);
    expect(html).toContain(`<script>${PAGE_SCRIPT}</script>`);
    expect(html.match(/<script\b/g)).toHaveLength(1);
  });

  it("rejects a code that is not hex", async () => {
    const { appURL } = await callback("/callback?code=not-a-code&state=s1");

    expect(appURL).toBe("myprs://auth?error=invalid_request&state=s1");
  });

  it("rejects a code that is too long", async () => {
    const { appURL } = await callback(`/callback?code=${"a".repeat(65)}&state=s1`);

    expect(appURL).toBe("myprs://auth?error=invalid_request&state=s1");
  });

  it("passes GitHub's error through", async () => {
    const { html, appURL } = await callback("/callback?error=access_denied&error_description=x&state=s1");

    expect(appURL).toBe("myprs://auth?error=access_denied&state=s1");
    expect(html).toContain("Sign-in didn't complete");
    expect(html).toContain("access_denied. Return to MyPRs and try again.");
    expect(html).not.toContain("Authorized on GitHub");
  });

  it("replaces an unexpected error value with invalid_request", async () => {
    const { html, appURL } = await callback(`/callback?error=${encodeURIComponent('<script>alert(1)</script>')}&state=s1`);

    expect(appURL).toBe("myprs://auth?error=invalid_request&state=s1");
    expect(html).not.toContain("alert(1)");
  });

  it("uses invalid_request when code is missing", async () => {
    const { appURL } = await callback("/callback?state=s1");

    expect(appURL).toBe("myprs://auth?error=invalid_request&state=s1");
  });

  it("uses invalid_request when state is missing", async () => {
    const { response, appURL } = await callback("/callback?code=abc");

    expect(response.status).toBe(200);
    expect(appURL).toBe("myprs://auth?error=invalid_request&state=");
  });

  it("URL-encodes the state in the app URL", async () => {
    const { appURL } = await callback("/callback?code=abc&state=x%26y%3Dz");

    expect(appURL).toBe("myprs://auth?code=abc&state=x%26y%3Dz");
  });
});

describe("POST /token", () => {
  it("exchanges the code and verifier for a token", async () => {
    const fetchMock = mockGitHub({ access_token: "gho_abc" });

    const response = await post("/token", { code: "abc123", code_verifier: VERIFIER });

    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toBe("application/json");
    expectSecurityHeaders(response);
    expect(await response.json()).toEqual({ access_token: "gho_abc" });
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://github.com/login/oauth/access_token");
    expect(init.method).toBe("POST");
    expect(init.headers.Accept).toBe("application/json");
    expect(JSON.parse(init.body)).toEqual({
      client_id: "client-id",
      client_secret: "client-secret",
      code: "abc123",
      code_verifier: VERIFIER,
    });
  });

  it("accepts a charset in the content type", async () => {
    mockGitHub({ access_token: "gho_abc" });

    const response = await post("/token", { code: "abc", code_verifier: VERIFIER }, "application/json; charset=utf-8");

    expect(response.status).toBe(200);
  });

  it("rejects other content types", async () => {
    const fetchMock = mockGitHub({});

    const response = await post("/token", `code=abc&code_verifier=${VERIFIER}`, "application/x-www-form-urlencoded");

    expect(response.status).toBe(415);
    expect(await response.json()).toEqual({ error: "unsupported_media_type" });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects a malformed body", async () => {
    const response = await post("/token", "{not json");

    expect(response.status).toBe(400);
    expect(await response.json()).toEqual({ error: "invalid_request" });
  });

  it.each([
    ["too short", VERIFIER.slice(0, 42)],
    ["too long", "a".repeat(129)],
    ["with invalid characters", `${VERIFIER.slice(0, 42)}+`],
    ["not a string", 42],
  ])("rejects a verifier %s", async (_, verifier) => {
    const fetchMock = mockGitHub({});

    const response = await post("/token", { code: "abc", code_verifier: verifier });

    expect(response.status).toBe(400);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects an invalid code", async () => {
    const fetchMock = mockGitHub({});

    const response = await post("/token", { code: "zz", code_verifier: VERIFIER });

    expect(response.status).toBe(400);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("returns GitHub's error", async () => {
    mockGitHub({ error: "bad_verification_code" });

    const response = await post("/token", { code: "abc", code_verifier: VERIFIER });

    expect(response.status).toBe(400);
    expect(await response.json()).toEqual({ error: "bad_verification_code" });
  });

  it("returns exchange_failed when GitHub sends an unexpected body", async () => {
    mockGitHub({ error: { nested: true } });

    const response = await post("/token", { code: "abc", code_verifier: VERIFIER });

    expect(response.status).toBe(502);
    expect(await response.json()).toEqual({ error: "exchange_failed" });
  });

  it("returns exchange_failed when GitHub is unreachable", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("network")));

    const response = await post("/token", { code: "abc", code_verifier: VERIFIER });

    expect(response.status).toBe(502);
    expect(await response.json()).toEqual({ error: "exchange_failed" });
  });

  it("rejects an oversized body without calling GitHub", async () => {
    const fetchMock = mockGitHub({ access_token: "gho_abc" });

    const response = await post("/token", { code: "abc", code_verifier: VERIFIER, padding: "x".repeat(5000) });

    expect(response.status).toBe(413);
    expect(await response.json()).toEqual({ error: "payload_too_large" });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe("POST /revoke", () => {
  it("revokes the token with GitHub", async () => {
    const fetchMock = mockGitHub(null, 204);

    const response = await post("/revoke", { access_token: "gho_abc" });

    expect(response.status).toBe(204);
    expectSecurityHeaders(response);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.github.com/applications/client-id/token");
    expect(init.method).toBe("DELETE");
    expect(init.headers.Authorization).toBe(`Basic ${btoa("client-id:client-secret")}`);
    expect(init.headers["User-Agent"]).toBe("myprs-auth");
    expect(JSON.parse(init.body)).toEqual({ access_token: "gho_abc" });
  });

  it("treats an already invalid token as revoked", async () => {
    mockGitHub({ message: "Not Found" }, 404);

    const response = await post("/revoke", { access_token: "gho_abc" });

    expect(response.status).toBe(204);
  });

  it("reports a GitHub failure", async () => {
    mockGitHub({}, 500);

    const response = await post("/revoke", { access_token: "gho_abc" });

    expect(response.status).toBe(502);
  });

  it("rejects a malformed token", async () => {
    const fetchMock = mockGitHub(null, 204);

    const response = await post("/revoke", { access_token: "../other" });

    expect(response.status).toBe(400);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects other content types", async () => {
    const response = await post("/revoke", "access_token=gho_abc", "text/plain");

    expect(response.status).toBe(415);
  });
});

describe("other paths", () => {
  it("returns 404", async () => {
    expect((await worker.fetch(new Request("https://auth.example.com/"), env)).status).toBe(404);
    expect((await worker.fetch(new Request("https://auth.example.com/other"), env)).status).toBe(404);
  });

  it("returns 405 with Allow for the wrong method", async () => {
    const fetchMock = mockGitHub({ access_token: "gho_abc" });

    const postCallback = await post("/callback?code=abc&state=s", {});
    const getToken = await worker.fetch(new Request("https://auth.example.com/token"), env);
    const getRevoke = await worker.fetch(new Request("https://auth.example.com/revoke"), env);

    expect(postCallback.status).toBe(405);
    expect(postCallback.headers.get("allow")).toBe("GET");
    expect(getToken.status).toBe(405);
    expect(getToken.headers.get("allow")).toBe("POST");
    expect(getRevoke.status).toBe(405);
    expectSecurityHeaders(getToken);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
