#!/bin/bash
# Packages the launcher, the layer DLLs and the install/run scripts as
# "FH2 Port.app" inside a drag-to-install .dmg.
# Usage: tools/app/make_app.sh <version>
# Output: dist/FH2 Port.app and dist/FH2-Port-<version>.dmg (ad-hoc signed, arm64).
set -euo pipefail

version=${1:?usage: make_app.sh <version>}
repo=$(cd "$(dirname "$0")/../.." && pwd)
dist="$repo/dist"
app="$dist/FH2 Port.app"
min_macos=15.0
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

make -C "$repo" all >/dev/null
for dll in d3d12.dll fh2pad.dll; do
    if strings "$repo/build/$dll" | grep -q "$HOME"; then
        echo "warning: build/$dll embeds paths under $HOME" >&2
    fi
done

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/layer" "$app/Contents/Resources/scripts"

# CrossOver's D3DMetal only exists on Apple silicon: arm64 is enough.
swiftc -O -target arm64-apple-macos$min_macos -o "$app/Contents/MacOS/FH2Port" "$repo/app/Launcher.swift"

cp "$repo/build/d3d12.dll" "$repo/build/fh2pad.dll" "$app/Contents/Resources/layer/"
cp "$repo/scripts/install.sh" "$repo/scripts/run.sh" "$app/Contents/Resources/scripts/"
chmod +x "$app/Contents/Resources/scripts/"*.sh

# Icon.
swift "$repo/tools/app/make_icon.swift" "$scratch/icon.png"
iconset="$scratch/AppIcon.iconset"
mkdir "$iconset"
for s in 16 32 128 256 512; do
    sips -z $s $s "$scratch/icon.png" --out "$iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$scratch/icon.png" --out "$iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>FH2 Port</string>
    <key>CFBundleDisplayName</key><string>FH2 Port</string>
    <key>CFBundleIdentifier</key><string>io.github.fladnag86.fh2-port</string>
    <key>CFBundleExecutable</key><string>FH2Port</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$version</string>
    <key>CFBundleVersion</key><string>$version</string>
    <key>LSMinimumSystemVersion</key><string>$min_macos</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.racing-games</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Not affiliated with or endorsed by Microsoft, Playground Games or Almost There Games.</string>
</dict>
</plist>
EOF

[ -f "$repo/LICENSE" ] && cp "$repo/LICENSE" "$app/Contents/Resources/LICENSE.txt"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"

# Disk image: the app, a link to /Applications and the first-run notes.
stage="$scratch/dmg"
mkdir "$stage"
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
cp "$repo/tools/app/READ ME FIRST.txt" "$stage/"
dmg="$dist/FH2-Port-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "FH2 Port $version" -srcfolder "$stage" -fs HFS+ -format UDZO "$dmg" >/dev/null
echo "$dmg"
shasum -a 256 "$dmg"
