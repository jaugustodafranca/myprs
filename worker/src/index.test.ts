import { afterEach, describe, expect, it, vi } from "vitest";
import worker, { type Env } from "./index";

const env: Env = { GITHUB_CLIENT_ID: "client-id", GITHUB_CLIENT_SECRET: "client-secret" };

function mockGitHub(body: object) {
  const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify(body)));
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

function get(path: string) {
  return worker.fetch(new Request(`https://auth.example.com${path}`), env);
}

afterEach(() => vi.unstubAllGlobals());

describe("GET /callback", () => {
  it("redirects to the app with the token and state", async () => {
    const fetchMock = mockGitHub({ access_token: "gho_abc" });

    const response = await get("/callback?code=the-code&state=the-state");

    expect(response.status).toBe(302);
    expect(response.headers.get("Location")).toBe("myprs://auth?token=gho_abc&state=the-state");
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://github.com/login/oauth/access_token");
    expect(JSON.parse(init.body)).toEqual({
      client_id: "client-id",
      client_secret: "client-secret",
      code: "the-code",
    });
    expect(init.headers.Accept).toBe("application/json");
  });

  it("redirects with the GitHub error", async () => {
    mockGitHub({ error: "bad_verification_code" });

    const response = await get("/callback?code=old&state=s1");

    expect(response.headers.get("Location")).toBe("myprs://auth?error=bad_verification_code&state=s1");
  });

  it("redirects with exchange_failed when GitHub is unreachable", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("network")));

    const response = await get("/callback?code=c&state=s1");

    expect(response.headers.get("Location")).toBe("myprs://auth?error=exchange_failed&state=s1");
  });

  it("returns invalid_request when code is missing", async () => {
    const fetchMock = mockGitHub({});

    const response = await get("/callback?state=s1");

    expect(response.headers.get("Location")).toBe("myprs://auth?error=invalid_request&state=s1");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("returns invalid_request when state is missing", async () => {
    mockGitHub({});

    const response = await get("/callback?code=c");

    expect(response.status).toBe(302);
    expect(response.headers.get("Location")).toMatch(/^myprs:\/\/auth\?error=invalid_request/);
  });

  it("URL-encodes token and state in the redirect", async () => {
    mockGitHub({ access_token: "a+b&c=d" });

    const response = await get("/callback?code=c&state=x%26y%3Dz");

    expect(response.headers.get("Location")).toBe("myprs://auth?token=a%2Bb%26c%3Dd&state=x%26y%3Dz");
  });
});

describe("other paths", () => {
  it("returns 404", async () => {
    expect((await get("/")).status).toBe(404);
    expect((await get("/other")).status).toBe(404);
  });
});
