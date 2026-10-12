#!/usr/bin/env bash
# Archiva Rumis y lo sube a App Store Connect (TestFlight) en un solo paso.
#
# Se ejecuta en el Mac del titular de la cuenta de Apple Developer, con su
# Apple ID añadido en Xcode → Settings → Accounts. Uso:
#
#   ios-native/scripts/subir-testflight.sh [TEAM_ID]
#
# Sin TEAM_ID usa el DEVELOPMENT_TEAM de project.yml. El número de build se
# genera con la fecha y hora (AAAAMMDDHHMM), así siempre es mayor que el
# anterior y no hay que tocarlo a mano.
set -euo pipefail

TEAM_ID="${1:-}"
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "Falta XcodeGen: brew install xcodegen" >&2; exit 1; }

git pull --ff-only
xcodegen generate

BUILD="$(date +%Y%m%d%H%M)"
ARCHIVE="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Rumis-$BUILD.xcarchive"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TEAM_OVERRIDE=()
[[ -n "$TEAM_ID" ]] && TEAM_OVERRIDE=(DEVELOPMENT_TEAM="$TEAM_ID")

echo "→ Archivando build $BUILD…"
xcodebuild archive \
  -project Rumis.xcodeproj \
  -scheme Rumis \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -quiet \
  CURRENT_PROJECT_VERSION="$BUILD" \
  ${TEAM_OVERRIDE[@]+"${TEAM_OVERRIDE[@]}"}

cat > "$WORK/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>upload</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
EOF

echo "→ Subiendo a App Store Connect…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$WORK/ExportOptions.plist" \
  -exportPath "$WORK/export" \
  -allowProvisioningUpdates

echo "✓ Build $BUILD subida. Aparecerá en TestFlight en 10-30 minutos."
