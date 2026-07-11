import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_settings.dart';
import '../../services/backup_service.dart';
import '../../services/update_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/update_dialog.dart';
import '../../core/constants.dart';

/// # SettingsScreen
/// 
/// Configuration panel for Shuni. Manages recording triggers, PIN/Biometric lock setups,
/// disk cleanup parameters, and Google Drive backups.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isGoogleSignedIn = false;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleSignIn();
  }

  Future<void> _checkGoogleSignIn() async {
    final bool signed = await BackupService.instance.isSignedIn();
    if (mounted) {
      setState(() {
        _isGoogleSignedIn = signed;
      });
    }
  }

  Future<void> _toggleGoogleSignIn() async {
    if (_isGoogleSignedIn) {
      await BackupService.instance.signOut();
      setState(() {
        _isGoogleSignedIn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out of Google account')),
      );
    } else {
      final bool success = await BackupService.instance.signIn();
      if (success) {
        setState(() {
          _isGoogleSignedIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully connected Google Drive')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in with Google')),
        );
      }
    }
  }

  Future<void> _triggerBackup() async {
    setState(() {
      _isBackingUp = true;
    });
    
    final bool success = await BackupService.instance.runFullBackup();
    
    if (mounted) {
      setState(() {
        _isBackingUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Backup uploaded successfully!'
              : 'Backup failed. Check internet or account.'),
        ),
      );
    }
  }

  void _showPinSetupDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Lock PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a secure passcode digits PIN. This will lock the app archives.'),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter 4-6 digit PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_pinController.text.length >= 4) {
                await ref.read(authProvider.notifier).registerPin(_pinController.text);
                await ref.read(settingsProvider.notifier).setPinLockEnabled(true);
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security PIN set successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shuni Configurations'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          // 1. Recording settings
          _buildSectionHeader('Recording Config'),
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto Record SIM Calls'),
                  subtitle: const Text('Start recording automatically when calls connect'),
                  value: settings.autoRecordEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) => settingsNotifier.toggleAutoRecord(),
                  contentPadding: EdgeInsets.zero,
                ),
                Divider(color: AppColors.divider),
                ListTile(
                  title: const Text('Opus Audio Quality'),
                  subtitle: Text('Current target: ${settings.audioQuality.name.toUpperCase()} (${settings.audioQuality.bitRate ~/ 1000} kbps)'),
                  contentPadding: EdgeInsets.zero,
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () {
                    // Quick dialog select
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Audio Quality'),
                        children: AudioQuality.values.map((q) {
                          return SimpleDialogOption(
                            onPressed: () {
                              settingsNotifier.setAudioQuality(q);
                              Navigator.pop(context);
                            },
                            child: Text('${q.name.toUpperCase()} (${q.bitRate ~/ 1000} kbps)'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Security settings
          _buildSectionHeader('Security & Lock'),
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Secure PIN Lock'),
                  subtitle: const Text('Locks app entry behind an invisible password code'),
                  value: settings.pinLockEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    if (val) {
                      _showPinSetupDialog();
                    } else {
                      ref.read(authProvider.notifier).disableSecurity();
                      settingsNotifier.setPinLockEnabled(false);
                      settingsNotifier.setBiometricLockEnabled(false);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (settings.pinLockEnabled) ...[
                  Divider(color: AppColors.divider),
                  SwitchListTile(
                    title: const Text('Biometric Fingerprint Lock'),
                    subtitle: const Text('Unlock quickly using local device biometrics'),
                    value: settings.biometricLockEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      settingsNotifier.setBiometricLockEnabled(val);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Backup Settings
          _buildSectionHeader('Google Drive Backup'),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Google Account Integration'),
                  subtitle: Text(_isGoogleSignedIn 
                      ? 'Connected to Google Drive' 
                      : 'Not connected'),
                  contentPadding: EdgeInsets.zero,
                  trailing: ElevatedButton(
                    onPressed: _toggleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGoogleSignedIn ? AppColors.accent : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(_isGoogleSignedIn ? 'Disconnect' : 'Connect'),
                  ),
                ),
                if (_isGoogleSignedIn) ...[
                  Divider(color: AppColors.divider),
                  SwitchListTile(
                    title: const Text('Auto Upload on Sync'),
                    subtitle: const Text('Runs backups dynamically in the background'),
                    value: settings.autoBackupEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) => settingsNotifier.setAutoBackupEnabled(val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppColors.divider),
                  SwitchListTile(
                    title: const Text('WiFi Only Uploads'),
                    subtitle: const Text('Save mobile data when syncing files'),
                    value: settings.backupWifiOnly,
                    activeColor: AppColors.primary,
                    onChanged: (val) => settingsNotifier.setBackupWifiOnly(val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppColors.divider),
                  ListTile(
                    title: const Text('Trigger Full Backup'),
                    subtitle: const Text('Compress and upload all files now'),
                    contentPadding: EdgeInsets.zero,
                    trailing: _isBackingUp
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.backup_outlined, color: AppColors.primary),
                            onPressed: _triggerBackup,
                          ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. About settings
          _buildSectionHeader('About App'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  title: Text('Shuni App Version'),
                  subtitle: Text('v1.0.0 (API 30+)'),
                  contentPadding: EdgeInsets.zero,
                ),
                Divider(color: AppColors.divider),
                ListTile(
                  title: const Text('Slogan'),
                  subtitle: Text('"${AppConstants.slogan}"\n${AppConstants.sloganEnglish}'),
                  contentPadding: EdgeInsets.zero,
                ),
                Divider(color: AppColors.divider),
                ListTile(
                  title: const Text('Check for Updates'),
                  subtitle: const Text('Manually check GitHub for new versions'),
                  trailing: const Icon(Icons.system_update, color: AppColors.accent, size: 20),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    // Show a loading snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking for updates...')),
                    );
                    
                    final release = await UpdateService().checkForUpdate();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (release != null) {
                        showDialog(
                          context: context,
                          builder: (context) => UpdateDialog(release: release),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You are on the latest version!')),
                        );
                      }
                    }
                  },
                ),
                Divider(color: AppColors.divider),
                const ListTile(
                  title: Text('Developer'),
                  subtitle: Text('Tansir Labib'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
