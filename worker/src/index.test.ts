import { afterEach, describe, expect, it, vi } from "vitest";
import worker, { type Env } from "./index";

const env: Env = { GITHUB_CLIENT_ID: "client-id", GITHUB_CLIENT_SECRET: "client-secret" };

function mockGitHub(body: object) {
  const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify(body)));
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

function appURLIn(response: Response, html: string): string {
  const match = html.match(/<a href="([^"]*)">Open MyPRs<\/a>/);
  expect(match).not.toBeNull();
  return match![1].replaceAll("&amp;", "&");
}

async function callback(path: string) {
  const response = await get(path);
  const html = await response.text();
  return { response, html, appURL: appURLIn(response, html) };
}

function get(path: string) {
  return worker.fetch(new Request(`https://auth.example.com${path}`), env);
}

afterEach(() => vi.unstubAllGlobals());

describe("GET /callback", () => {
  it("returns a page that opens the app with the token and state", async () => {
    const fetchMock = mockGitHub({ access_token: "gho_abc" });

    const { response, html, appURL } = await callback("/callback?code=the-code&state=the-state");

    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toBe("text/html; charset=utf-8");
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.get("referrer-policy")).toBe("no-referrer");
    expect(appURL).toBe("myprs://auth?token=gho_abc&state=the-state");
    expect(html).toContain('<meta http-equiv="refresh" content="0;url=myprs://auth?token=gho_abc&amp;state=the-state">');
    expect(html).toContain('location.replace("myprs://auth?token=gho_abc&state=the-state")');
    expect(html).toContain("Signed in — returning to MyPRs. You can close this tab.");
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://github.com/login/oauth/access_token");
    expect(JSON.parse(init.body)).toEqual({
      client_id: "client-id",
      client_secret: "client-secret",
      code: "the-code",
    });
    expect(init.headers.Accept).toBe("application/json");
  });

  it("shows the GitHub error and links the app with it", async () => {
    mockGitHub({ error: "bad_verification_code" });

    const { html, appURL } = await callback("/callback?code=old&state=s1");

    expect(appURL).toBe("myprs://auth?error=bad_verification_code&state=s1");
    expect(html).toContain("Sign-in failed: bad_verification_code. Return to MyPRs and try again.");
  });

  it("escapes a malicious error value", async () => {
    mockGitHub({ error: '<script>alert(1)</script>"&' });

    const { html } = await callback("/callback?code=c&state=s1");

    expect(html).not.toContain("<script>alert(1)");
    expect(html).toContain("&lt;script&gt;alert(1)&lt;/script&gt;&quot;&amp;");
    expect(html.match(/<script>/g)).toHaveLength(1);
  });

  it("uses exchange_failed when GitHub is unreachable", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("network")));

    const { appURL } = await callback("/callback?code=c&state=s1");

    expect(appURL).toBe("myprs://auth?error=exchange_failed&state=s1");
  });

  it("uses exchange_failed when GitHub sends an unexpected body", async () => {
    mockGitHub({ error: { nested: true } });

    const { appURL } = await callback("/callback?code=c&state=s1");

    expect(appURL).toBe("myprs://auth?error=exchange_failed&state=s1");
  });

  it("uses invalid_request when code is missing", async () => {
    const fetchMock = mockGitHub({});

    const { appURL } = await callback("/callback?state=s1");

    expect(appURL).toBe("myprs://auth?error=invalid_request&state=s1");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("uses invalid_request when state is missing", async () => {
    mockGitHub({});

    const { response, appURL } = await callback("/callback?code=c");

    expect(response.status).toBe(200);
    expect(appURL).toMatch(/^myprs:\/\/auth\?error=invalid_request/);
  });

  it("URL-encodes token and state in the app URL", async () => {
    mockGitHub({ access_token: "a+b&c=d" });

    const { appURL } = await callback("/callback?code=c&state=x%26y%3Dz");

    expect(appURL).toBe("myprs://auth?token=a%2Bb%26c%3Dd&state=x%26y%3Dz");
  });
});

describe("other paths", () => {
  it("returns 404", async () => {
    expect((await get("/")).status).toBe(404);
    expect((await get("/other")).status).toBe(404);
  });

  it("returns 404 for non-GET requests to /callback", async () => {
    const fetchMock = mockGitHub({ access_token: "gho_abc" });

    const response = await worker.fetch(
      new Request("https://auth.example.com/callback?code=c&state=s", { method: "POST" }),
      env,
    );

    expect(response.status).toBe(404);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
