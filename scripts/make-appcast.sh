#!/usr/bin/env bash
# Usage: make-appcast.sh <tag> <version> <dmg> <sign_update-output>
# sign_update-output looks like: sparkle:edSignature="..." length="..."
# The appcast itself is signed afterwards with `sign_update appcast.xml`
# (SURequireSignedFeed), because the signature covers the final file contents.
set -euo pipefail

xml_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g"
}

tag=$1
version=$2
dmg=$3
signature_attributes=$4

build=${BUILD_NUMBER:?BUILD_NUMBER is required}
download_url=$(xml_escape "https://github.com/jaugustodafranca/myprs/releases/download/${tag}/$(basename "$dmg")")
version=$(xml_escape "$version")
build=$(xml_escape "$build")
pub_date=$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")

cat > appcast.xml <<XML
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>MyPRs</title>
    <item>
      <title>Version ${version}</title>
      <pubDate>${pub_date}</pubDate>
      <sparkle:version>${build}</sparkle:version>
      <sparkle:shortVersionString>${version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure url="${download_url}" type="application/octet-stream" ${signature_attributes}/>
    </item>
  </channel>
</rss>
XML
