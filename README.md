# 出欠管理アプリ (Flutter)

部活動向けの出欠管理 Android アプリ。Flask バックエンド (private repo) と JWT 認証で連携します。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/Himanaraba/attendance-app)](https://github.com/Himanaraba/attendance-app/releases/latest)

## 主な機能

- ログイン (JWT、自動リフレッシュ)
- ダッシュボード (出席率・直近活動)
- カレンダー (月別の活動表示)
- 個人の出欠記録
- 出欠登録 (出席 / 部分参加 / 欠席 + コメント)
- 管理者向け
  - 活動 CRUD
  - 日別出欠一括編集
  - 全ユーザ出席統計
  - 週次テンプレート (自動活動生成)
  - ユーザ管理
- アプリ内自動アップデート (OTA)
- 言語切替 (日本語 / English)
- ダーク/ライトテーマ
- 詳細エラー表示トグル (トラブルシュート用)

## アーキテクチャ

```
┌─────────────────┐         ┌─────────────────────┐
│  Flutter App    │  HTTPS  │  Flask API (VPS)    │
│  (この repo)    │ ──────▶ │  + Coolify          │
│                 │   JWT   │  + SQLite (volume)  │
└─────────────────┘         └─────────────────────┘
        ▲
        │ OTA APK
        │
┌─────────────────┐
│ GitHub Releases │
└─────────────────┘
```

## ディレクトリ構成

```
lib/
├── config/api_config.dart       # API ベース URL
├── models/                       # User / Event / Attendance
├── providers/                    # Auth / Event / Attendance / Theme / Language / Debug
├── services/
│   ├── api_service.dart          # Dio + JWT インターセプター
│   ├── update_service.dart       # OTA ダウンロード&インストール
│   └── i18n.dart                 # 翻訳テーブル (ja/en)
├── widgets/                      # EventCard / StatusChip
└── screens/                      # 各画面
    ├── login_screen.dart
    ├── dashboard_screen.dart
    ├── calendar_screen.dart
    ├── my_attendance_screen.dart
    ├── profile_screen.dart
    ├── update_screen.dart
    └── admin/                    # 管理画面群
```

## 開発環境セットアップ

### 必須
- Flutter SDK 3.x 以降 ([インストール](https://flutter.dev/docs/get-started/install))
- Android Studio (エミュレータ用)
- Git

### 初回セットアップ

```bash
git clone https://github.com/Himanaraba/attendance-app.git
cd attendance-app
flutter pub get
```

### ローカル開発で動かす

`lib/config/api_config.dart` の `kBaseUrl` をローカル Flask に向けます：

```dart
// Android エミュレータ → ホストの localhost
static const String kBaseUrl = 'http://10.0.2.2:5000';
```

エミュレータ起動 + Flask 起動した状態で：

```bash
flutter run
```

### 本番ビルド

```bash
flutter build apk --release
# 生成物: build/app/outputs/flutter-apk/app-release.apk
```

## リリース手順

開発者は `release-apk.ps1` (リポジトリ外、別途管理) で1コマンドリリース可能。
内部的には：

1. `pubspec.yaml` の `version` を SemVer で更新
2. `flutter build apk --release` でビルド
3. `gh release create vX.Y.Z app-release.apk` で GitHub Release 作成 + APK 添付
4. サーバ側 `app_version.json` を更新 → push
5. Coolify が自動デプロイ → 全ユーザのアプリが起動時にアップデート通知

`-Force` フラグで強制更新 (最低互換バージョンを引き上げ)。

## バージョン管理

`pubspec.yaml`:
```yaml
version: 1.2.2+5
#         ^^^^^ ^
#         |     └─ versionCode (Android, インクリメント必須)
#         └─ versionName (SemVer, ユーザに見える)
```

## API

主要エンドポイント (バックエンドは private repo):
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET  /api/v1/auth/me`
- `GET  /api/v1/events` / `/events/upcoming`
- `GET  /api/v1/attendance/my`
- `POST /api/v1/attendance/update`
- `GET  /api/v1/app/latest` (アップデートチェック、認証不要)
- `GET  /api/v1/users` (manager+)
- `GET  /api/v1/stats` (manager+)
- `/api/v1/templates/*` (manager+)

## ライセンス

[Apache License 2.0](LICENSE)

Copyright 2026 賀屋悠

## お問い合わせ

不具合・要望は [Issues](https://github.com/Himanaraba/attendance-app/issues) または直接 kayaharuka@hotmail.com まで。
