import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
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
  String _statusKey = '';    // 翻訳キー (空文字なら表示なし)
  String _errorRaw  = '';    // 例外メッセージ (翻訳しない)
  bool _running = false;
  bool _failed = false;

  void _startUpdate() {
    setState(() {
      _running = true;
      _failed  = false;
      _statusKey = 'update.downloading';
      _errorRaw  = '';
    });
    UpdateService.downloadAndInstall(widget.info.downloadUrl).listen((event) {
      if (!mounted) return;
      if (event.error != null) {
        setState(() {
          _statusKey = 'update.error';
          _errorRaw  = event.error.toString();
          _failed    = true;
        });
        return;
      }
      setState(() {
        _progress = event.percent;
        if (event.percent >= 99.9 && !event.done) {
          _statusKey = 'update.installing';
        } else if (event.done) {
          _statusKey = 'update.installer_open';
        } else {
          _statusKey = 'update.downloading_pct';
        }
      });
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _statusKey = 'update.error';
          _errorRaw  = e.toString();
          _failed    = true;
        });
      }
    });
  }

  String _statusText(LanguageProvider lang) {
    if (_statusKey.isEmpty) return '';
    if (_statusKey == 'update.error') {
      return '${lang.t('update.error')}: $_errorRaw';
    }
    if (_statusKey == 'update.downloading_pct') {
      return lang.t('update.downloading_pct')
          .replaceAll('{pct}', _progress.toStringAsFixed(0));
    }
    return lang.t(_statusKey);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final lang = context.watch<LanguageProvider>();
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
                      info.isForced
                          ? lang.t('update.required')
                          : lang.t('update.available'),
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
                            Text(lang.t('update.notes'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(info.releaseNotes, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (info.isForced) ...[
                      Text(
                        lang.t('update.forced_msg'),
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
                      Text(_statusText(lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(_failed ? lang.t('update.retry') : lang.t('update.now')),
                        onPressed: (_running && !_failed) ? null : _startUpdate,
                      ),
                    ),
                    if (!info.isForced && !_running) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onSkipped,
                        child: Text(lang.t('update.later')),
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
