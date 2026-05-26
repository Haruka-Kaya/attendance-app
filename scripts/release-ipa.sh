#!/usr/bin/env bash
# 出欠管理 iOS リリーススクリプト (macOS 専用・Xcode GUI 不要)
#
# 使い方: ./scripts/release-ipa.sh 1.6.0 "リリースノート"
#
# 前提:
#   - Xcode に Apple ID がサインイン済み (初回のみ GUI で: Xcode → Settings → Accounts)
#   - CocoaPods インストール済み
#   - Flutter インストール済み
#
# 動作:
#   1. pubspec.yaml の version を更新
#   2. pod install
#   3. flutter build ipa --export-options-plist (CLI のみ、Xcode GUI 不要)
#   4. xcrun altool で App Store Connect (TestFlight) にアップロード
#   5. git push
#
# 環境変数 (必須):
#   APP_STORE_CONNECT_KEY_ID     App Store Connect API Key ID
#   APP_STORE_CONNECT_ISSUER_ID  同 Issuer ID
#   APP_STORE_CONNECT_KEY_PATH   .p8 ファイルのパス

set -euo pipefail

VERSION="${1:-}"
NOTES="${2:-}"

if [[ -z "$VERSION" || -z "$NOTES" ]]; then
  echo "Usage: $0 <version> \"<notes>\""
  echo "Example: $0 1.6.0 \"iOS初回リリース\""
  exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be SemVer (e.g. 1.6.0)"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

EXPORT_OPTIONS="$REPO_ROOT/ios/ExportOptions.plist"
if [[ ! -f "$EXPORT_OPTIONS" ]]; then
  echo "Error: ios/ExportOptions.plist not found"
  exit 1
fi

echo "=== iOS Release v$VERSION ==="

# 1. pubspec.yaml の version を bump
CURRENT_LINE=$(grep -E '^version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+' pubspec.yaml)
CODE=$(echo "$CURRENT_LINE" | sed -E 's/.*\+([0-9]+).*/\1/')
NEW_CODE=$((CODE + 1))
echo
echo "[1/5] pubspec.yaml: $CURRENT_LINE -> version: $VERSION+$NEW_CODE"
sed -i.bak -E "s/^version:.*/version: $VERSION+$NEW_CODE/" pubspec.yaml
rm -f pubspec.yaml.bak

# 2. CocoaPods
echo
echo "[2/5] pod install"
(cd ios && pod install)

# 3. flutter build ipa (Xcode GUI 不要)
echo
echo "[3/5] flutter build ipa --release"
flutter pub get
flutter build ipa --release --export-options-plist="$EXPORT_OPTIONS"

IPA_PATH=$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -1)
[[ -f "$IPA_PATH" ]] || { echo "Error: IPA not found in build/ios/ipa/"; exit 1; }
echo "  Built: $IPA_PATH ($(du -h "$IPA_PATH" | cut -f1))"

# 4. App Store Connect (TestFlight) にアップロード
echo
echo "[4/5] Uploading to TestFlight via xcrun altool"
: "${APP_STORE_CONNECT_KEY_ID:?env APP_STORE_CONNECT_KEY_ID is required}"
: "${APP_STORE_CONNECT_ISSUER_ID:?env APP_STORE_CONNECT_ISSUER_ID is required}"
: "${APP_STORE_CONNECT_KEY_PATH:?env APP_STORE_CONNECT_KEY_PATH is required}"

xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$APP_STORE_CONNECT_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

# 5. git commit & push
echo
echo "[5/5] git commit & push"
git add pubspec.yaml pubspec.lock
git -c user.email=kayaharuka@hotmail.com -c user.name=kayah \
  commit -m "release(ios): v$VERSION - $NOTES"
git push

echo
echo "[OK] Released iOS v$VERSION"
echo "  TestFlight: https://appstoreconnect.apple.com → ZENSHIN-Attendance → TestFlight"
echo "  ビルド処理に 15-30 分かかります。完了メールが Apple ID 宛に届きます。"
