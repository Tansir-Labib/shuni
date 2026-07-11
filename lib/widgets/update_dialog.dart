import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

class UpdateDialog extends StatefulWidget {
  final AppRelease release;
  
  const UpdateDialog({super.key, required this.release});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  final UpdateService _updateService = UpdateService();

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      await _updateService.downloadAndInstall(
        widget.release.downloadUrl,
        (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download update.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        // We do not pop the dialog automatically so the user sees it's complete,
        // or they can close it if the install prompt didn't show up.
      }
    }
  }

  Future<void> _openWebsite() async {
    final url = Uri.parse(widget.release.htmlUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassCard(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.system_update, color: AppColors.accent, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Update Available: ${widget.release.version}',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Changelog:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Markdown(
                  data: widget.release.changelog,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
              ),
              const SizedBox(height: 24),
              if (_isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    Text('${(_progress * 100).toStringAsFixed(1)}% Downloaded'),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _startDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Download & Install Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openWebsite,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Download from Website'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Later', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
