#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 /path/to/CalendarWidget.app /path/to/CalendarWidget.dmg" >&2
  exit 64
fi

app_path="$1"
dmg_path="$2"
extension_path="$app_path/Contents/PlugIns/MonthWidgetExtension.appex"
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

: "${APPLE_DEVID_APP_CERT_NAME:?Certificate installer must run before packaging}"
: "${APPLE_ID_USER:?Missing Apple ID}"
: "${APPLE_ID_PASS:?Missing Apple ID app-specific password}"

if [[ "$APPLE_DEVID_APP_CERT_NAME" =~ ^Developer\ ID\ Application:.*\(([A-Z0-9]{10})\)$ ]]; then
  team_id="${BASH_REMATCH[1]}"
else
  echo "Expected a Developer ID Application certificate with a Team ID." >&2
  exit 1
fi

if [ ! -d "$app_path" ] || [ ! -d "$extension_path" ]; then
  echo "App or embedded widget extension is missing: $app_path" >&2
  exit 66
fi

# Sign nested code first and explicitly preserve each target's sandbox entitlements.
codesign --force --sign "$APPLE_DEVID_APP_CERT_NAME" --options runtime --timestamp \
  --entitlements "$repo_root/Widget/Widget.entitlements" "$extension_path"
codesign --force --sign "$APPLE_DEVID_APP_CERT_NAME" --options runtime --timestamp \
  --entitlements "$repo_root/App/App.entitlements" "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

bash "$repo_root/scripts/create-dmg.sh" "$app_path" "$dmg_path"
app_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")
codesign --force --sign "$APPLE_DEVID_APP_CERT_NAME" --timestamp \
  --identifier "$app_identifier.dmg" "$dmg_path"
codesign --verify --strict --verbose=2 "$dmg_path"

# Submit only the final DMG, which contains the signed app and extension.
result_path="$(mktemp)"
trap 'rm -f "$result_path"' EXIT
notary_args=(--apple-id "$APPLE_ID_USER" --password "$APPLE_ID_PASS" --team-id "$team_id")
submit_exit=0
xcrun notarytool submit "$dmg_path" "${notary_args[@]}" --wait --output-format json \
  > "$result_path" || submit_exit=$?
cat "$result_path"
status=$(plutil -extract status raw -o - "$result_path" 2>/dev/null || true)
if [ "$submit_exit" -ne 0 ] || [ "$status" != "Accepted" ]; then
  submission_id=$(plutil -extract id raw -o - "$result_path" 2>/dev/null || true)
  if [ -n "$submission_id" ]; then
    xcrun notarytool log "$submission_id" "${notary_args[@]}" || true
  fi
  echo "Notarization did not succeed; the DMG must not be published." >&2
  exit 1
fi

xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
