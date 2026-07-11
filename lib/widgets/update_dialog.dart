import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// # UpdateDialog
/// 
/// A popup dialog that shows release notes (changelog) and optionally
/// allows downloading a new APK version directly inside Shuni.
/// 
/// When [isLatest] is true, the user is already on the newest version
/// and we only show the changelog without a download button.
class UpdateDialog extends StatefulWidget {
  final AppRelease release;
  final bool isLatest;
  
  const UpdateDialog({
    super.key,
    required this.release,
    this.isLatest = false,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  final UpdateService _updateService = UpdateService();

  Future<void> _startDownload() async {
    if (widget.release.downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No APK found in this release.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      await _updateService.downloadAndInstall(
        widget.release.downloadUrl,
        (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
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
      }
    }
  }

  Future<void> _openWebsite() async {
    if (widget.release.htmlUrl.isEmpty) return;
    final url = Uri.parse(widget.release.htmlUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = !widget.isLatest;
    
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isUpdate ? Icons.system_update : Icons.article_outlined,
                  color: isUpdate ? AppColors.accent : AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUpdate
                            ? 'Update Available!'
                            : 'Release Notes',
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUpdate
                            ? 'New version: v${widget.release.version}'
                            : 'Current: v${widget.release.version} — You\'re up to date ✓',
                        style: AppTypography.bodySmall.copyWith(
                          color: isUpdate ? AppColors.accent : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Changelog section
            const Text('Changelog:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Markdown(
                data: widget.release.changelog,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (_isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}% Downloaded',
                    style: AppTypography.bodySmall,
                  ),
                ],
              )
            else if (isUpdate)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download & Install'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openWebsite,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open on GitHub'),
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
              )
            else
              // Already on latest — just a close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
          ],
        ),
      ),
    );
  }
}
