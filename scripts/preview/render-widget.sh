#!/usr/bin/env bash
# Renders the widget views to PNG, in light and dark: scripts/preview/render-widget.sh <output-dir>
# No Xcode project, signing or widget host; see scripts/preview/README.md.
set -euo pipefail

output_dir="${1:?usage: render-widget.sh <output-dir>}"
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
preview_dir="$repo_root/scripts/preview"
source "$preview_dir/stage-sources.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
staged="$work_dir/sources"
mkdir -p "$output_dir"

# The widget bundle (the @main entry point and its #Preview blocks) and the widget's own SampleData are left out.
stage_sources "$staged" \
  "$repo_root/Packages/MyPRsKit/Sources" \
  "$repo_root/MyPRsWidget/Intents" \
  "$repo_root/MyPRsWidget/Timeline/Provider.swift" \
  "$repo_root/MyPRsWidget/Views"

# The widget family is read-only in the environment, so the view takes it as a parameter instead.
patch_staged "$staged" EntryView.swift 's/@Environment(\\.widgetFamily) private var family/let family: WidgetFamily/'

# Outside a widget a Link paints its label in the system link color; inside one the label keeps its own colors.
patch_staged "$staged" PullRequestRowView.swift 's/Link(destination: pullRequest.url)/Group/'

compile_preview "$work_dir/widget-preview" "$staged" \
  "$preview_dir/Snapshot.swift" \
  "$preview_dir/SampleData.swift" \
  "$preview_dir/WidgetStubs.swift" \
  "$preview_dir/WidgetPreview.swift"

"$work_dir/widget-preview" "$output_dir"
echo "Widget previews written to $output_dir"
