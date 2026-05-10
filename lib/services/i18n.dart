/// シンプルな2言語(ja/en)翻訳テーブル。
/// 追加する場合は両方の言語に同じキーを追加してください。
library;

const Map<String, Map<String, String>> kTranslations = {
  'ja': {
    'app_title':           '出欠管理',

    // ── 共通 ───────────────────────────────
    'common.save':         '保存',
    'common.cancel':       'キャンセル',
    'common.delete':       '削除',
    'common.edit':         '編集',
    'common.add':          '追加',
    'common.update':       '更新',
    'common.confirm':      '確認',
    'common.refresh':      '再読み込み',
    'common.required':     '入力してください',
    'common.error':        'エラー',
    'common.loading':      '読み込み中...',
    'common.no_data':      'データがありません',

    // ── ステータス ─────────────────────────
    'status.present':      '出席',
    'status.absent':       '欠席',
    'status.partial':      '部分参加',

    // ── 認証 ───────────────────────────────
    'auth.login':          'ログイン',
    'auth.logout':         'ログアウト',
    'auth.email':          'メールアドレス',
    'auth.password':       'パスワード',
    'auth.password_new':   '新しいパスワード',
    'auth.password_cur':   '現在のパスワード',
    'auth.password_conf':  '新しいパスワード（確認）',
    'auth.password_change':'パスワード変更',
    'auth.logout_confirm': 'ログアウトしますか？',
    'auth.login_failed':   'ログインに失敗しました',
    'auth.forgot_pw':      'パスワードを忘れた場合は kayaharuka@hotmail.com または直接 賀屋悠 に連絡してください。',

    // ── ナビゲーション ─────────────────────
    'nav.home':            'ホーム',
    'nav.calendar':        'カレンダー',
    'nav.my_attendance':   '出欠記録',
    'nav.admin':           '管理',
    'nav.profile':         'プロフィール',

    // ── ダッシュボード ─────────────────────
    'dash.attendance_rate':'出席率',
    'dash.recent_events':  '直近の活動',
    'dash.no_events':      '予定されている活動はありません',
    'dash.total':          '合計',

    // ── 活動 ───────────────────────────────
    'event.title':         'タイトル',
    'event.description':   '説明 (任意)',
    'event.date':          '日付',
    'event.start_time':    '開始時刻',
    'event.end_time':      '終了時刻',
    'event.add':           '活動追加',
    'event.edit':          '活動編集',
    'event.no_event_day':  'この日の活動はありません',
    'event.delete_confirm':'を削除しますか？',

    // ── 出欠登録 ───────────────────────────
    'att.register':        '出欠登録',
    'att.comment':         'コメント (任意)',
    'att.saved':           '保存しました',

    // ── プロフィール ───────────────────────
    'prof.theme':          'テーマ',
    'prof.theme_system':   'システム',
    'prof.theme_light':    'ライト',
    'prof.theme_dark':     'ダーク',
    'prof.language':       '言語',
    'prof.language_ja':    '日本語',
    'prof.language_en':    'English',

    // ── アップデート ───────────────────────
    'update.available':    '新しいバージョンが利用可能',
    'update.required':     '必須アップデート',
    'update.now':          '今すぐ更新',
    'update.later':        '後で',
    'update.notes':        '変更内容',
    'update.downloading':  'ダウンロード中',
    'update.installing':   'インストール画面を開いています...',
  },
  'en': {
    'app_title':           'Attendance',

    'common.save':         'Save',
    'common.cancel':       'Cancel',
    'common.delete':       'Delete',
    'common.edit':         'Edit',
    'common.add':          'Add',
    'common.update':       'Update',
    'common.confirm':      'Confirm',
    'common.refresh':      'Refresh',
    'common.required':     'Required',
    'common.error':        'Error',
    'common.loading':      'Loading...',
    'common.no_data':      'No data',

    'status.present':      'Present',
    'status.absent':       'Absent',
    'status.partial':      'Partial',

    'auth.login':          'Log in',
    'auth.logout':         'Log out',
    'auth.email':          'Email',
    'auth.password':       'Password',
    'auth.password_new':   'New password',
    'auth.password_cur':   'Current password',
    'auth.password_conf':  'Confirm new password',
    'auth.password_change':'Change password',
    'auth.logout_confirm': 'Log out?',
    'auth.login_failed':   'Login failed',
    'auth.forgot_pw':      'Forgot your password? Email kayaharuka@hotmail.com or contact 賀屋悠 directly.',

    'nav.home':            'Home',
    'nav.calendar':        'Calendar',
    'nav.my_attendance':   'My Attendance',
    'nav.admin':           'Admin',
    'nav.profile':         'Profile',

    'dash.attendance_rate':'Attendance Rate',
    'dash.recent_events':  'Upcoming Activities',
    'dash.no_events':      'No upcoming activities',
    'dash.total':          'Total',

    'event.title':         'Title',
    'event.description':   'Description (optional)',
    'event.date':          'Date',
    'event.start_time':    'Start time',
    'event.end_time':      'End time',
    'event.add':           'Add activity',
    'event.edit':          'Edit activity',
    'event.no_event_day':  'No activities on this day',
    'event.delete_confirm':' will be deleted. Continue?',

    'att.register':        'Register attendance',
    'att.comment':         'Comment (optional)',
    'att.saved':           'Saved',

    'prof.theme':          'Theme',
    'prof.theme_system':   'System',
    'prof.theme_light':    'Light',
    'prof.theme_dark':     'Dark',
    'prof.language':       'Language',
    'prof.language_ja':    '日本語',
    'prof.language_en':    'English',

    'update.available':    'Update available',
    'update.required':     'Update required',
    'update.now':          'Update now',
    'update.later':        'Later',
    'update.notes':        'Release notes',
    'update.downloading':  'Downloading',
    'update.installing':   'Opening installer...',
  },
};
