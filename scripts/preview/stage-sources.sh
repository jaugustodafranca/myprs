# Helpers for render-panel.sh and render-widget.sh. Source this file; do not run it.
#
# The previews compile the app, the widget and MyPRsKit together as one module with plain swiftc.
# Repository sources are never edited: they are copied into a scratch directory and the copies are patched.

# stage_sources <destination> <file or directory>...
# Copies the Swift files, flat, into <destination>. `import MyPRsKit` has nothing to import inside one module.
stage_sources() {
  local destination=$1
  shift
  mkdir -p "$destination"
  local path file
  for path in "$@"; do
    while IFS= read -r -d '' file; do
      stage_file "$file" "$destination"
    done < <(find "$path" -name '*.swift' -print0)
  done
}

stage_file() {
  local source=$1
  local target="$2/$(basename "$source")"
  if [ -e "$target" ]; then
    echo "error: two sources are named $(basename "$source")" >&2
    exit 1
  fi
  sed '/^import MyPRsKit$/d' "$source" > "$target"
}

# patch_staged <destination> <file name> <sed expression>
# Edits a staged copy. Fails when the expression no longer matches, so a refactor cannot silently drop a patch.
patch_staged() {
  local file="$1/$2"
  local before
  before=$(cksum < "$file")
  sed -i '' -e "$3" "$file"
  if [ "$before" = "$(cksum < "$file")" ]; then
    echo "error: the patch for $2 no longer matches; update scripts/preview" >&2
    exit 1
  fi
}

# compile_preview <binary> <staged sources directory> <preview swift file>...
compile_preview() {
  local binary=$1
  local staged=$2
  shift 2
  swiftc -parse-as-library -swift-version 5 -suppress-warnings -o "$binary" "$staged"/*.swift "$@"
}
