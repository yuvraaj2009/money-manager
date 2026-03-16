import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/apk_download_service.dart';
import '../../services/version_service.dart';

/// Blocking full-screen shown when the app version is below min_app_version.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.result});

  final VersionCheckResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_rounded, size: 80, color: Color(0xFF0F52FF)),
              const SizedBox(height: 24),
              Text(
                'Update Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your app version (${result.currentVersion}) is outdated.\n'
                'Please update to version ${result.latestVersion} to continue.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (result.apkUrl.isNotEmpty && Platform.isAndroid)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _DownloadButton(apkUrl: result.apkUrl),
                )
              else if (result.updateUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => launchUrl(
                      Uri.parse(result.updateUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Download Update'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dismissible dialog shown when a newer (but not mandatory) version is available.
class UpdateAvailableDialog extends StatefulWidget {
  const UpdateAvailableDialog({super.key, required this.result});

  final VersionCheckResult result;

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  final _downloadService = ApkDownloadService();
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final filePath = await _downloadService.downloadApk(
        widget.result.apkUrl,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (!mounted) return;
      await _downloadService.installApk(filePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Download failed. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Download failed. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _downloadService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return AlertDialog(
      icon: const Icon(Icons.system_update_rounded, size: 48, color: Color(0xFF0F52FF)),
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.message.isNotEmpty
                ? result.message
                : 'A new version (${result.latestVersion}) of Money Manager is available.',
            textAlign: TextAlign.center,
          ),
          if (_downloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _downloading
              ? () {
                  _downloadService.cancel();
                  Navigator.of(context).pop();
                }
              : () => Navigator.of(context).pop(),
          child: Text(_downloading ? 'Cancel' : 'Later'),
        ),
        if (!_downloading)
          FilledButton(
            onPressed: () {
              if (Platform.isAndroid && result.apkUrl.isNotEmpty) {
                _startDownload();
              } else if (result.updateUrl.isNotEmpty) {
                launchUrl(
                  Uri.parse(result.updateUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text('Update Now'),
          ),
      ],
    );
  }
}

/// A button that downloads and installs the APK with a progress indicator.
class _DownloadButton extends StatefulWidget {
  const _DownloadButton({required this.apkUrl});

  final String apkUrl;

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  final _downloadService = ApkDownloadService();
  bool _downloading = false;
  double _progress = 0;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      final filePath = await _downloadService.downloadApk(
        widget.apkUrl,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      if (mounted) await _downloadService.installApk(filePath);
    } catch (_) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _downloadService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_downloading) {
      return FilledButton(
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: _progress > 0 ? _progress : null,
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      );
    }
    return FilledButton(
      onPressed: _download,
      child: const Text('Download Update'),
    );
  }
}
