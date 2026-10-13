#!/usr/bin/env bash
# Archiva Rumies y lo sube a App Store Connect (TestFlight) en un solo paso.
#
# Firma manual: necesita en el llavero el certificado "Apple Distribution" del
# equipo y el perfil "Rumies Marco" instalado (doble clic en el
# .mobileprovision). Ambos los crea el titular de la cuenta; ver
# docs/LANZAMIENTO_APP_STORE.md. Uso:
#
#   ios-native/scripts/subir-testflight.sh
#
# El número de build se genera con la fecha y hora (AAAAMMDDHHMM), así siempre
# es mayor que el anterior y no hay que tocarlo a mano. Si la subida directa
# falla (p. ej. Xcode no tiene acceso de subida con tu cuenta), deja el .ipa en
# el Escritorio para arrastrarlo a Transporter.
set -euo pipefail

BUNDLE_ID="com.marcobarroso.rumis"
PROFILE="Rumies Marco"
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "Falta XcodeGen: brew install xcodegen" >&2; exit 1; }
security find-identity -v -p codesigning | grep -q "Apple Distribution" || {
  echo "No hay ningún certificado \"Apple Distribution\" en el llavero." >&2
  echo "Haz doble clic en el .cer que te mandó el titular de la cuenta." >&2
  exit 1
}

git pull --ff-only
xcodegen generate

TEAM_ID="$(awk '/DEVELOPMENT_TEAM:/ {print $2; exit}' project.yml)"
BUILD="$(date +%Y%m%d%H%M)"
ARCHIVE="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Rumies-$BUILD.xcarchive"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "→ Archivando build $BUILD…"
xcodebuild archive \
  -project Rumis.xcodeproj \
  -scheme Rumis \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -quiet \
  CURRENT_PROJECT_VERSION="$BUILD"

export_options() {
  cat > "$WORK/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>$1</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>$BUNDLE_ID</key>
		<string>$PROFILE</string>
	</dict>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
EOF
}

echo "→ Subiendo a App Store Connect…"
export_options upload
if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$WORK/ExportOptions.plist" \
    -exportPath "$WORK/upload"; then
  echo "✓ Build $BUILD subida. Aparecerá en TestFlight en 10-30 minutos."
  exit 0
fi

echo "⚠︎ La subida directa ha fallado. Exportando el .ipa para Transporter…"
OUT="$HOME/Desktop/Rumies-$BUILD"
export_options export
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$WORK/ExportOptions.plist" \
  -exportPath "$OUT" \
  -quiet
echo "✓ .ipa listo en $OUT"
echo "  Ábrelo con Transporter (Mac App Store), entra con tu Apple ID, arrastra el .ipa y pulsa Entregar."
open -a Transporter 2>/dev/null || true
open "$OUT"
