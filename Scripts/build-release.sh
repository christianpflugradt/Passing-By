#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
cd "$root"
swift build -c release --product PassingByApp
bin_path="$(swift build -c release --show-bin-path)"
app="$root/build/Passing By.app"
mkdir -p "$root/build"
staging="$(mktemp -d "$root/build/.passing-by.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
staged_app="$staging/Passing By.app"
mkdir -p "$staged_app/Contents/MacOS" "$staged_app/Contents/Resources"
cp "$bin_path/PassingByApp" "$staged_app/Contents/MacOS/PassingBy"
cp "$root/Resources/Info.plist" "$staged_app/Contents/Info.plist"
version="${RELEASE_VERSION:-}"
if [[ -z "$version" ]]; then
  latest_tag="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
  if [[ "${latest_tag#v}" =~ '^[1-9][0-9]*\.[0-9]+\.[0-9]+$' ]]; then
    version="${latest_tag#v}"
  else
    version="0.0.0"
  fi
else
  if [[ ! "$version" =~ '^[1-9][0-9]*\.[0-9]+\.[0-9]+$' ]]; then
    print -u2 "RELEASE_VERSION must be a numeric major.minor.patch version"
    exit 1
  fi
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$staged_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $version" "$staged_app/Contents/Info.plist"

icon_tmp="$(mktemp -d)"
trap 'rm -rf "$staging" "$icon_tmp"' EXIT
iconset="$icon_tmp/PassingBy.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  for scale in 1 2; do
    pixels=$((size * scale))
    suffix=""
    if (( scale == 2 )); then suffix="@2x"; fi
    sips -s format png -z "$pixels" "$pixels" \
      "$root/passing-by-icon-master.svg" \
      --out "$iconset/icon_${size}x${size}${suffix}.png" >/dev/null
  done
done
iconutil -c icns "$iconset" -o "$staged_app/Contents/Resources/PassingBy.icns"

codesign --force --sign - "$staged_app"
rm -rf "$app"
mv "$staged_app" "$app"
print "Built $app"
