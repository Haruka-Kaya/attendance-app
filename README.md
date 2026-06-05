# 出欠管理アプリ (Flutter)

部活動向けの出欠管理モバイルアプリ。Android + iOS 両対応。Flask バックエンド ([attendance-system](https://github.com/Himanaraba/attendance-system)) と JWT 認証で連携。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/Himanaraba/attendance-app)](https://github.com/Himanaraba/attendance-app/releases/latest)

## ダウンロード

### Android
[GitHub Releases](https://github.com/Himanaraba/attendance-app/releases/latest) から最新 APK をダウンロード:
- `app-arm64-v8a-release.apk` (64bit、推奨、~18MB)
- `app-armeabi-v7a-release.apk` (32bit、~16MB、古い端末向け)

インストール後はアプリ内 OTA 更新が動作 (起動時に自動チェック)。

### iOS
**TestFlight 内部テスト + App Store 審査中** (Bundle ID `jp.zenshin9498.attendance`)

## 主な機能

### コア機能
- ログイン (JWT Access 2h / Refresh 30d、自動リフレッシュ)
- ダッシュボード (出席率・直近活動・今日の活動ワンタップ登録)
- カレンダー (月別表示、自分のステータスを色ドットで可視化)
- 個人の出欠記録 + 統計
- 出欠登録 (出席 / 部分参加 / 欠席 + コメント + 部分参加時刻)
- **全員の出欠状況を表示** (イベント詳細画面で出席予定者リスト + 集計バッジ)
- 管理者機能
  - 活動 CRUD
  - 日別出欠一括編集
  - 全ユーザ出席統計
  - 週次テンプレート (自動活動生成)
  - ユーザ管理 (検索・フィルタ)
- 言語切替 (日本語 / English、`LanguageProvider` で全画面追従)
- ダーク / ライト / システムテーマ
- 詳細エラー表示トグル (トラブルシュート用)

### UI / UX
- **Liquid Glass デザイン** (iOS 26 風、`liquid_glass_widgets` v0.10.9)
- 角丸・ソフトシャドウのモダンレイアウト
- `GlassBottomBar` + `GradientBackground` で動的な背景
- システムナビゲーションバー (下の3ボタン) を常時隠す (Android)
- ステータスごとの色分け (緑=出席 / 橙=部分 / 赤=欠席)

### アップデート機構
- **Android**: GitHub Releases から APK を自動 DL → OSインストーラー起動 (アプリ内 OTA)
- **iOS**: 新バージョン検知時に「TestFlight で更新」ボタン (`itms-beta://` 起動)
- 起動時自動チェック + プロフィールから手動チェック

### セキュリティ
- JWT 自動リフレッシュ
- `flutter_secure_storage` でトークン安全保存 (iOS Keychain / Android Keystore)
- `/api/v1/auth/logout` で JWT ブラックリスト登録 (再使用ブロック)

## アーキテクチャ

```
┌─────────────────┐    HTTPS+JWT   ┌─────────────────────┐
│  Flutter App    │ ─────────────▶ │  Flask API (VPS)    │
│  Android + iOS  │                │  + Coolify          │
└─────────────────┘                │  + SQLite (volume)  │
        ▲                          └─────────────────────┘
        │                                   ▲
        │ OTA APK (Android)                 │ git push
        │                          ┌─────────────────────┐
┌─────────────────┐                │  GitHub Actions     │
│ GitHub Releases │                │  (iOS auto-build,   │
└─────────────────┘                │   TestFlight upload)│
                                   └─────────────────────┘
```

## ディレクトリ構成

```
lib/
├── config/
│   ├── api_config.dart           # API ベース URL
│   └── glass_theme.dart          # Liquid Glass 設定
├── models/                        # User / Event (attendees/summary 含む) / Attendance
├── providers/                     # Auth / Event / Attendance / Theme / Language / Debug
├── services/
│   ├── api_service.dart           # Dio + JWT インターセプター
│   ├── update_service.dart        # OTA + iOS の TestFlight 誘導
│   └── i18n.dart                  # 翻訳テーブル (ja/en)
├── widgets/                       # EventCard / StatusChip / EmptyState / GradientBackground
└── screens/
    ├── login_screen.dart
    ├── onboarding_screen.dart     # 初回ログイン時のセットアップ
    ├── dashboard_screen.dart
    ├── calendar_screen.dart
    ├── my_attendance_screen.dart
    ├── profile_screen.dart
    ├── update_screen.dart         # OTA / TestFlight 誘導画面
    ├── change_password_screen.dart
    ├── event_detail_screen.dart   # 出席予定者リスト表示
    └── admin/                     # 管理画面群

ios/                               # iOS ターゲット (Bundle ID: jp.zenshin9498.attendance)
├── Runner.xcodeproj/
├── Runner/Info.plist              # CFBundleDisplayName: 出欠管理
└── ExportOptions.plist            # CLI ビルド用 (Team 7482F26LUS, automatic signing)

android/                           # Android ターゲット (R8 + shrinkResources 有効)
└── app/
    ├── build.gradle.kts           # split-per-abi, minify, proguard-rules
    └── proguard-rules.pro

scripts/
└── release-ipa.sh                 # Mac 上で TestFlight に一発配布
.github/workflows/
└── ios-release.yml                # GitHub Actions で Mac 不要 iOS リリース
IOS_BUILD.md                       # iOS ビルド手順 (Claude 引継ぎ用詳細)
```

## 開発環境セットアップ

### 必須
- Flutter SDK 3.x 以降
- Android: Android Studio (エミュレータ用)
- iOS: macOS + Xcode + CocoaPods

```bash
git clone https://github.com/Himanaraba/attendance-app.git
cd attendance-app
flutter pub get
```

### ローカル開発

`lib/config/api_config.dart` の `kBaseUrl` をローカル Flask に向ける:

```dart
// Android エミュレータ → ホストの localhost
static const String kBaseUrl = 'http://10.0.2.2:5000';
```

```bash
flutter run
```

### Android 本番ビルド

```bash
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/debug-info
# 生成物: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (18MB)
```

`compileSdk = 36`、R8 minify + `shrinkResources` 有効、ProGuard ルール (`android/app/proguard-rules.pro`) で Flutter / Dio / OkHttp / flutter_secure_storage / open_filex / url_launcher を保護。

### iOS 本番ビルド (Mac)

```bash
cd ios && pod install && cd ..
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

詳細は [IOS_BUILD.md](IOS_BUILD.md) (Apple Developer 加入から TestFlight 配布まで)。

### iOS CI/CD (Mac 不要、GitHub Actions)

`.github/workflows/ios-release.yml` で `workflow_dispatch` 手動トリガー。版とリリースノートを入力すると:
1. macOS runner で `flutter build ipa`
2. `xcrun altool` で App Store Connect (TestFlight) にアップロード
3. pubspec.yaml の version を bump して commit/push

事前に GitHub Secrets を登録する必要あり (`APPLE_P12_BASE64`, `APP_STORE_CONNECT_KEY_BASE64` 等)。

## リリース手順

### Android
```powershell
attendance-tools\release-apk.ps1 -Version 1.7.0 -Notes "リリースノート"
# 1. pubspec.yaml の version を更新
# 2. flutter build apk --split-per-abi --obfuscate
# 3. gh release create v1.7.0 app-arm64-v8a-release.apk
# 4. サーバ側 app_version.json 更新 → push
# 5. Coolify が自動デプロイ、起動時アップデート通知
```

`-Force` フラグで強制更新 (`min_supported_version` を引き上げ)。

### iOS
```bash
./scripts/release-ipa.sh 1.7.0 "リリースノート"  # Mac
# または GitHub Actions: workflow_dispatch
```

## バージョン管理

`pubspec.yaml`:
```yaml
version: 1.6.0+17
#         ^^^^^ ^^
#         |     └─ versionCode (Android) / CFBundleVersion (iOS)、必ずインクリメント
#         └─ versionName (SemVer、ユーザに見える)
```

Android と iOS で同じバージョンを揃えるのが理想。

## APK サイズ最適化

| 施策 | 効果 |
|---|---|
| split-per-abi (arm64 のみ配布) | -33MB (x86_64 / arm32 の native lib を除外) |
| R8 `isMinifyEnabled` | 未使用 Java/Kotlin コード除去 |
| `isShrinkResources` | 未使用リソース除去 |
| `--obfuscate --split-debug-info` | Dart コード難読化 + デバッグ情報分離 |
| `proguard-rules.pro` | Flutter + 全プラグインの keep ルール |

**結果**: 54MB → **18MB** (arm64-v8a、66% 削減)

## ライセンス

[Apache License 2.0](LICENSE)

Copyright 2026 賀屋悠

## お問い合わせ

不具合・要望は [Issues](https://github.com/Himanaraba/attendance-app/issues) または直接 kayaharuka@hotmail.com まで。

プライバシーポリシー: https://zenshin9498.duckdns.org/privacy
サポート: https://zenshin9498.duckdns.org/support
