#!/usr/bin/env bash
# Renders the menu bar panel screens to PNG, in light and dark: scripts/preview/render-panel.sh <output-dir>
# No Xcode project, signing or app launch; see scripts/preview/README.md.
set -euo pipefail

output_dir="${1:?usage: render-panel.sh <output-dir>}"
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
preview_dir="$repo_root/scripts/preview"
source "$preview_dir/stage-sources.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
staged="$work_dir/sources"
mkdir -p "$output_dir"

# MenuContentView is the real panel; the monitor and updater it needs are stubbed in PanelStubs.swift.
stage_sources "$staged" \
  "$repo_root/Packages/MyPRsKit/Sources" \
  "$repo_root/MyPRs/Components" \
  "$repo_root/MyPRs/Features/AIReview" \
  "$repo_root/MyPRs/Features/MenuBar" \
  "$repo_root/MyPRs/Features/OpenPullRequests" \
  "$repo_root/MyPRs/Features/RecentPullRequests" \
  "$repo_root/MyPRs/Features/Review" \
  "$repo_root/MyPRs/Features/Settings" \
  "$repo_root/MyPRs/Features/SignIn/SignedOutView.swift" \
  "$repo_root/MyPRs/Features/Updates/CheckForUpdatesButton.swift" \
  "$repo_root/MyPRs/Services/GitHub/ClosedPullRequestPage.swift" \
  "$repo_root/MyPRs/Services/GitHub/SavedSearchLink.swift" \
  "$repo_root/MyPRs/Services/Monitoring/NewPullRequestDetector.swift" \
  "$repo_root/MyPRs/Services/Monitoring/NotificationPermission.swift" \
  "$repo_root/MyPRs/Services/Monitoring/SavedSearchRefresh.swift" \
  "$repo_root/MyPRs/Services/Monitoring/SavedSearches.swift"

# Pick the tab to show: the panel has no input to switch tabs offscreen.
patch_staged "$staged" MenuContentView.swift 's/@State private var tab = PanelTab.open/@State private var tab = PanelPreviewState.tab/'

# Exercise collapsed boxes without adding preview state to the production view.
patch_staged "$staged" GroupedPullRequestList.swift 's/@State private var collapsedGroupIDs: Set<String> = \[\]/@State private var collapsedGroupIDs: Set<String>/'
patch_staged "$staged" GroupedPullRequestList.swift 's/self.groups = groups/self.groups = groups; self._collapsedGroupIDs = State(initialValue: PanelPreviewState.collapseGroups ? Set(groups.filter { $0.isRelated }.map { $0.id }) : [])/'

# The panel is capped at 60% of the screen height; use a fixed height so renders match across machines.
screen_height='NSScreen.main?.visibleFrame.height ?? PanelSize.defaultScreenHeight'
patch_staged "$staged" MenuContentView.swift "s/$screen_height/PanelPreviewState.screenHeight/g"
patch_staged "$staged" PanelScreen.swift "s/$screen_height/PanelPreviewState.screenHeight/g"

compile_preview "$work_dir/panel-preview" "$staged" \
  "$preview_dir/SnapshotWriter.swift" \
  "$preview_dir/RunOffscreen.swift" \
  "$preview_dir/SampleData.swift" \
  "$preview_dir/PanelSampleData.swift" \
  "$preview_dir/PanelStubs.swift" \
  "$preview_dir/PanelPreview.swift"

"$work_dir/panel-preview" "$output_dir"
echo "Panel previews written to $output_dir"
