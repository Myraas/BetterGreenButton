#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="BetterGreenButton"
APP="dist/${APP_NAME}.app"
DMG="dist/${APP_NAME}.dmg"
STAGING="dist/.dmg-staging"

bash scripts/build-app.sh

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG" >/dev/null

rm -rf "$STAGING"
