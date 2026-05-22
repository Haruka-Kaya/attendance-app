# iOS / iPhone ビルド手順

このリポジトリは Flutter 製で iOS ターゲットもセット済み。

| 項目 | 値 |
|---|---|
| Bundle ID | `jp.zenshin9498.attendance` |
| 表示名 | `出欠管理` |
| 配布方法 | Apple Developer Program + TestFlight |
| OTA アップデート | **iOS では無効** (`UpdateService.isSupported` が false 固定) |
| 最小 iOS バージョン | プロジェクト初期値 (`flutter create` 既定) |

> **OTA について**: iOS は OS の制約で任意 IPA をアプリから DL/インストールできないため、Android の `release-apk.ps1` 相当の自動更新フローは作らない。配信は **TestFlight / App Store** に一本化する。

---

## 1. 事前準備 (Mac 借りる前)

### 1-1. Apple Developer Program 加入 ($99/年)

1. https://developer.apple.com/programs/ → "Enroll" → Apple ID でサインイン
2. 個人 (Individual) で登録
3. クレカで $99 支払い → **数時間〜2日** で承認メール

加入が遅延するので Mac 借りる前にやっておく方が効率良い。

### 1-2. App Store Connect でアプリ枠を作成

1. https://appstoreconnect.apple.com → 「マイ App」→「+」→「新規 App」
2. 設定:
   - プラットフォーム: **iOS**
   - 名前: `出欠管理`
   - 言語: 日本語
   - Bundle ID: `jp.zenshin9498.attendance` (Xcode 初回 archive 時に自動登録されるので **後から** でもOK)
   - SKU: 任意 (例 `attendance-2026`)

---

## 2. Mac 上のワンタイム設定

```bash
# Xcode (Mac App Store から、約 8GB)
sudo xcode-select --install
sudo xcodebuild -license accept

# CocoaPods
sudo gem install cocoapods

# Flutter
brew install --cask flutter
flutter doctor   # 全部 ✓ にする (iOS toolchain, Xcode, CocoaPods 必須)
```

Xcode を起動 → **Settings → Accounts** → 「+」で自分の Apple ID を追加 → "Manage Certificates" で iOS 開発証明書を作成。

---

## 3. プロジェクト取得 & 初回ビルド

```bash
git clone https://github.com/Himanaraba/attendance-app.git
cd attendance-app

flutter pub get
cd ios && pod install && cd ..
```

### 実機テスト (iPhone をケーブル接続)

iPhone 側の **設定 → 一般 → VPN とデバイス管理** で開発者を信頼。

```bash
flutter devices         # iPhone が表示されることを確認
flutter run --release   # 実機にインストール (1〜2分)
```

---

## 4. TestFlight 配布 (Xcode GUI)

1. `ios/Runner.xcworkspace` を **Xcode で開く** (※ `.xcodeproj` ではなく `.xcworkspace`)
2. 上部のターゲット選択を `Any iOS Device (arm64)` にする
3. `Runner` を選択 → `Signing & Capabilities` タブ → Team を Apple Developer の自分のチームに
4. メニュー: **Product → Archive** (3〜5分)
5. 完了後 `Organizer` ウィンドウが開く → 該当 archive を選択 → **Distribute App** → **App Store Connect** → **Upload**
6. App Store Connect ([appstoreconnect.apple.com](https://appstoreconnect.apple.com)) の **TestFlight** タブ:
   - ビルド処理: 約 **15〜30分**
   - 内部テスターを追加 (最大 100人, Apple ID 招待)
   - 外部テスター配布の場合は審査必要 (約 24時間)

テスターは iPhone に **TestFlight アプリ** を入れて招待リンクから入る。

---

## 5. CLI 配布 (オプション・自動化版)

CocoaPods / archive / upload を一発で回すスクリプト。App Store Connect API キーが必要 (App Store Connect → ユーザとアクセス → キー → 「+」)。

環境変数を `.env.ios` に置く (gitignore 対象):
```bash
export APP_STORE_CONNECT_KEY_ID="ABCD1234EF"
export APP_STORE_CONNECT_ISSUER_ID="69a6de70-..."
export APP_STORE_CONNECT_KEY_PATH="$HOME/.appstoreconnect/AuthKey_ABCD1234EF.p8"
```

```bash
chmod +x scripts/release-ipa.sh   # 初回のみ
source .env.ios
./scripts/release-ipa.sh 1.6.0 "iOS版初回リリース"
```

---

## 6. バージョン管理の方針

`pubspec.yaml` の `version: 1.5.7+15` を共通バージョン番号として使う:
- `1.5.7` = `CFBundleShortVersionString` / Android `versionName`
- `+15` = `CFBundleVersion` / Android `versionCode`

iOS は TestFlight 配布のたびに `+N` を上げないとアップロード拒否される。

Android と iOS を **同じ** バージョンで揃えたい場合の理想フロー:
```
1. release-apk.ps1 -Version 1.6.0 -Notes "..."    (Windows)
2. git pull                                        (Mac)
3. ./scripts/release-ipa.sh 1.6.0 "..."           (Mac)
```

---

## 7. トラブルシューティング

| 症状 | 対処 |
|---|---|
| Xcode で `No team found` | Apple Developer 加入完了後、数時間待つ。または Xcode → Settings → Accounts でログインし直す |
| `pod install` がエラー | `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update` |
| `code signing failed` | Xcode → Runner ターゲット → Signing & Capabilities → Team を選択し、"Automatically manage signing" を ON |
| TestFlight に上がらない | App Store Connect の **App Store** タブの「ビルド」セクション。エラーメッセージはメールでも届く (Apple ID 宛) |
| `liquid_glass_widgets` がビルドエラー | iOS 12 未満をサポートしている場合は ios/Podfile の `platform :ios, '12.0'` を `'14.0'` などに上げる |
| 起動時に「インターネット接続なし」と出る | Info.plist の ATS デフォルトは HTTPS のみ。本番 URL (DuckDNS + LE) は問題なし。開発で http://localhost を叩く時は ATS 例外追加が必要 |

---

## 8. 既知の差異 (Android vs iOS)

| 機能 | Android | iOS |
|---|---|---|
| OTA アップデート | ✅ 自動 (`release-apk.ps1`) | ❌ 不可。TestFlight で受信 |
| プロフィールの「アップデートを確認」ボタン | 表示 | 非表示 (`Platform.isAndroid` 分岐) |
| システムナビバー非表示 | ✅ (`immersiveSticky`) | iOS は元々ナビバー無し |
| Liquid Glass | 動作 | 動作 (iOS の方が映える) |
| 通知 | 未実装 | 未実装 |
