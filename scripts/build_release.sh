#!/usr/bin/env bash
# Builds signed release APK/AAB and packages delivery artifacts.
# Usage: ./scripts/build_release.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PKG="com.gonzorevol.blocktap"

if [[ ! -f android/key.properties ]]; then
  echo "Missing android/key.properties — create keystore first (see DELIVERY.md)."
  exit 1
fi

echo "→ flutter pub get"
flutter pub get

echo "→ flutter build appbundle --release"
flutter build appbundle --release

echo "→ flutter build apk --release"
flutter build apk --release

mkdir -p release

cp build/app/outputs/flutter-apk/app-release.apk "release/${PKG}.apk"
cp build/app/outputs/bundle/release/app-release.aab "release/${PKG}.aab"
cp android/com.gonzorevol.blocktap.jks "release/${PKG}.jks"

echo "→ packaging ${PKG}.zip"
rm -f "release/${PKG}.zip"
TMP="$(mktemp -d)"
mkdir -p "$TMP/${PKG}"
rsync -a \
  --exclude 'build' \
  --exclude '.dart_tool' \
  --exclude '.git' \
  --exclude 'release' \
  --exclude 'ios/Pods' \
  --exclude 'ios/.symlinks' \
  --exclude '.idea' \
  "$ROOT/" "$TMP/${PKG}/"
(
  cd "$TMP"
  zip -rq "$ROOT/release/${PKG}.zip" "$PKG"
)
rm -rf "$TMP"

echo ""
echo "Done. Delivery files in release/:"
ls -lh "release/${PKG}."*
