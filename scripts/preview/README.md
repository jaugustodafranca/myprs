# Preview harness

Renders the menu bar panel and the widget to PNG files, so a person or an agent can show how a screen
looks (a prototype, a before and after) without building, signing and launching the app.

Everything is compiled with plain `swiftc`: no Xcode project, no signing, no keychain, no network.
The views are drawn in an invisible window of a faceless process, so nothing opens on screen or takes focus.
It needs the Xcode command line tools with the macOS 26 SDK, like the app itself.

## Commands

```bash
scripts/preview/render-panel.sh <output-dir>    # the panel, about 25 seconds
scripts/preview/render-widget.sh <output-dir>   # the widget, about 25 seconds
```

Give a directory outside the repository, for example `$(mktemp -d)`. Each image is written twice, as
`<name>-light.png` and `<name>-dark.png`, at 2x.

| Script | Files | Shows |
| --- | --- | --- |
| `render-panel.sh` | `panel-open`, `panel-open-empty`, `panel-recent`, `panel-review`, `panel-settings`, `panel-signed-out` | The real `MenuContentView`, 440 pt wide and as tall as its content |
| `render-widget.sh` | `widget-<scenario>-<size>` | `EntryView` for the scenarios `mine`, `search`, `mine-empty`, `search-empty`, `signed-out` in the sizes `small` 170x170, `medium` 364x170, `large` 364x382 and `extra-large` 715x382 |

The editor screens (search and AI prompt) and the organization access banner are not rendered.

## How it works

The app, widget and `MyPRsKit` sources are copied into a temporary directory, patched there, and compiled
together with the files in this folder. The repository sources are never edited.

| File | Job |
| --- | --- |
| `stage-sources.sh` | Shared by both scripts: copies sources, applies a patch, runs `swiftc` |
| `SnapshotWriter.swift` | Draws a SwiftUI view in an invisible window and writes the PNG |
| `RunOffscreen.swift` | Runs the preview as a faceless app and exits when it is done |
| `SampleData.swift` | The pull requests, saved searches and snapshots both previews show |
| `PanelSampleData.swift` | Closed pull requests for the Recent tab, a type only the app has |
| `PanelStubs.swift` | Stand-ins for `PullRequestMonitor` and the Sparkle `Updater` |
| `PanelPreview.swift` | Builds the panel scenarios |
| `WidgetStubs.swift` | `PullRequestEntry.sample`, which `Provider.swift` refers to |
| `WidgetPreview.swift` | Builds the widget scenarios |

The files in this folder do not import `MyPRsKit`: everything is one module. `SampleData.swift` here is
not the widget's `MyPRsWidget/SampleData.swift`; the widget script leaves that one out on purpose.

## Source patches

Applied to the temporary copies only. A script stops with an error when a patch no longer matches, so a
refactor cannot silently change what is rendered: update the patch in the script.

| Script | File | Change | Why |
| --- | --- | --- | --- |
| both | every file | Delete `import MyPRsKit` | The package and its users are one module |
| panel | `MenuContentView.swift` | `@State private var tab = PanelTab.open` starts at `PanelPreviewState.tab` | Nothing can click a tab offscreen |
| panel | `MenuContentView.swift`, `PanelScreen.swift` | `NSScreen.main?.visibleFrame.height ?? ...` becomes `PanelPreviewState.screenHeight` | The panel stops growing at 60% of the screen height; a fixed tall screen gives the same images on every machine and shows the sample lists in full |
| widget | `EntryView.swift` | `@Environment(\.widgetFamily) private var family` becomes `let family: WidgetFamily` | The family cannot be set in the environment outside a widget host |
| widget | `PullRequestRowView.swift` | `Link(destination: pullRequest.url)` becomes `Group` | Outside a widget a `Link` paints its label in the system link color |

## Known limits

- The glass buttons in the panel header (refresh, settings) do not draw in light mode.
- The panel background is the plain window color, not the translucent material of the menu bar panel.
- The Version row of Settings reads `? (?)`: there is no app bundle.

## Sample data is fictional

Every organization, repository, branch and login in this folder is made up (`acme/storefront`, `octo/api`,
`northwind/reports`, `jdoe`, `mrivera`, `alee`, `kpatel`). Keep it that way: real company, repository or
colleague names must never enter this repository, so new samples are invented, never copied from real work.
