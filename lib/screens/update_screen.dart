import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateScreen extends StatefulWidget {
  final UpdateInfo info;
  final VoidCallback? onSkipped; // 任意更新でユーザがスキップした時
  const UpdateScreen({super.key, required this.info, this.onSkipped});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  double _progress = 0;
  String _status = '';
  bool _running = false;
  bool _failed = false;

  void _startUpdate() {
    setState(() { _running = true; _failed = false; _status = 'ダウンロード中...'; });
    UpdateService.downloadAndInstall(widget.info.downloadUrl).listen((event) {
      if (!mounted) return;
      if (event.error != null) {
        setState(() { _status = 'エラー: ${event.error}'; _failed = true; });
        return;
      }
      setState(() {
        _progress = event.percent;
        if (event.percent >= 99.9 && !event.done) {
          _status = 'インストーラを開いています...';
        } else if (event.done) {
          _status = 'インストーラが起動しました';
        } else {
          _status = 'ダウンロード中... ${event.percent.toStringAsFixed(0)}%';
        }
      });
    }, onError: (e) {
      if (mounted) setState(() { _status = 'エラー: $e'; _failed = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      info.isForced ? Icons.warning_amber_rounded : Icons.system_update,
                      size: 64,
                      color: info.isForced ? Colors.orange : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      info.isForced ? '必須アップデート' : '新しいバージョンが利用可能',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'v${info.currentVersion} → v${info.latestVersion}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    if (info.releaseNotes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('変更内容', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(info.releaseNotes, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (info.isForced) ...[
                      Text(
                        'このバージョンはサポート対象外です。続行するには更新が必要です。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_running || _failed) ...[
                      LinearProgressIndicator(
                        value: _running && !_failed ? _progress / 100 : null,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(_failed ? '再試行' : '今すぐ更新'),
                        onPressed: (_running && !_failed) ? null : _startUpdate,
                      ),
                    ),
                    if (!info.isForced && !_running) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onSkipped,
                        child: const Text('後で'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
