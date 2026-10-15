# Decision log

Why MyPRs is built the way it is. Read this before proposing to change an
approach: several of these were tried the other way first. Oldest first.

## Menu bar app plus widget, not a widget alone

A widget extension cannot sign in, keep a token or poll GitHub on its own
schedule. The app does the fetching and writes a snapshot to the App Group;
the widget only reads it. The app is dockless (`LSUIElement`) so it feels like
part of the desktop.

## OAuth App with the web flow and PKCE, through a Cloudflare Worker

The device flow was rejected because it makes the user copy a code. An OAuth
App's web flow needs a client secret, which cannot ship in a public app, so a
Worker holds it and performs the code exchange. PKCE ties the code to the app
instance that started the login. A GitHub App (read-only, expiring tokens) is
a planned migration, not done yet.

## Default browser and a `myprs://` callback, not ASWebAuthenticationSession

`ASWebAuthenticationSession` always opened Safari. The app opens the
authorization URL in the default browser and receives the callback through its
URL scheme in the app delegate, matched by `state`.

## Custom domain for the Worker

The `*.workers.dev` URL showed the Cloudflare account name in the browser
during sign-in. The Worker is reachable only at `myprs-auth.zaintech.com.br`.

## Token in the login keychain

The data-protection keychain needs a provisioning profile carrying the keychain
access group; a Developer ID app without one is killed at launch. Release
builds use no profile, so the token is stored in the legacy login keychain,
restricted to the app's own item. A token the keychain refuses to store is
revoked and the error shown, rather than left as an orphaned grant.

## GraphQL `search` for every list

Open and recent PRs use fixed `search` queries (`type: ISSUE`, `author:@me`).
Saved searches use the same field with `ISSUE_ADVANCED` and the user's query
text passed as the `$q` variable, never interpolated into the document.
Saved-search links pasted from GitHub are parsed into that query text.

## "Unanswered" means not resolved and last comment not by the user

Chosen over "any open thread" so a thread the user already replied to stops
asking for attention.

## XcodeGen, and the `.xcodeproj` is not committed

`project.yml` is reviewable in a PR; a generated project is not. Run
`xcodegen generate` after checkout.

## `MyPRsKit` holds only what the widget also needs

Everything else stays in the app target. It keeps the widget small and the
boundary obvious; a type is `public` only when the app or widget needs it.

## Sparkle with a signed appcast on GitHub Releases

No server to run: the release workflow publishes the DMG and `appcast.xml` as
release assets and the app reads `releases/latest/download/appcast.xml`.
`SURequireSignedFeed` and `SUVerifyUpdateBeforeExtraction` are on, checks run
daily. The update window needs the app to switch its activation policy for a
moment, because a dockless app cannot bring a window in front otherwise.

## Release pipeline gated by an environment

A tag alone does not run the signing job. The `release` environment requires
the owner's approval and accepts only `v*` tags, and a ruleset limits those
tags to admins. Actions are pinned by SHA and downloaded tools are
checksummed. See `docs/release.md`.

## Settings inside the panel

A separate settings window opened behind or outside the menu bar panel. The
panel has routes instead (`PanelRoute`, `PanelNavigation`): list, settings,
search editor, prompt editor. Drafts survive the panel closing.

## Inline confirmations

`confirmationDialog` closes a `MenuBarExtra` panel. Destructive actions
confirm inline, in place of the row or button (`InlineConfirmation`).

## Own logo glyph

SF Symbols cannot be used as a logo or app icon under their license, so the
brand mark is a custom `BrandGlyph` shape.

## Refresh every 30 minutes by default

Two minutes was too aggressive for GitHub's rate limit and for notification
noise. The default is 30 with 5 to 60 selectable and a manual refresh. After a
refresh the widget is reloaded only when the data changed, because WidgetKit
throttles reloads; launch, sign-out and deleting a search reload it too.

## Generic AI review prompt in the app

The "copy AI review prompt" button ships a generic template. Prompts tailored
to a company are pasted by each user in Settings and are never committed.

## Prototypes are rendered, not launched

`scripts/preview` renders panel screens and widget views to PNG with fictional
data. Agents show those images instead of building, installing and launching
the app, which puts keychain and notification prompts on the user's screen.

## Fictional data everywhere, after a history rewrite

Tests and sample data once carried a real organization's repository names and
colleagues' logins. The history was rewritten to remove them, and `AGENTS.md`
now forbids real company data in tests, sample data, docs and PR descriptions.
