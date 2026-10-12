#!/usr/bin/env bash
# Installs create-dmg v1.3.0 from a pinned commit and puts it on PATH for later CI steps.
# A commit SHA is content-addressed, so no separate checksum is needed.
set -euo pipefail

commit="a2b71d0fda6d0df2a86dc7f67082d4d73e84c59f" # v1.3.0

dir="${RUNNER_TEMP:?RUNNER_TEMP is required}/create-dmg"
git clone --quiet https://github.com/create-dmg/create-dmg.git "$dir"
git -C "$dir" checkout --quiet "$commit"
echo "$dir" >> "${GITHUB_PATH:?GITHUB_PATH is required}"
