#!/bin/zsh
set -euo pipefail

root="${0:A:h:h}"
cd "$root"
swift build -c release --product PassingByApp
bin_path="$(swift build -c release --show-bin-path)"
app="$root/build/Passing By.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_path/PassingByApp" "$app/Contents/MacOS/PassingBy"
cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"

iconset="$(mktemp -d)/PassingBy.iconset"
mkdir -p "$iconset"
trap 'rm -rf "${iconset:h}"' EXIT
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
iconutil -c icns "$iconset" -o "$app/Contents/Resources/PassingBy.icns"

codesign --force --sign - "$app"
print "Built $app"
