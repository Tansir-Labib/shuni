import 'package:flutter/material.dart';
import '../../core/permissions.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/animations.dart';
import '../../widgets/glass_card.dart';
import 'shizuku_check_screen.dart';

/// # OnboardingScreen
/// 
/// Guides the user through a list of required Android system permissions on first run.
/// 
/// ## Visual Flow
/// - Uses glass cards with custom checkboxes for each permission item.
/// - The "Continue" button is locked until all standard permissions are granted.
/// - Once granted, slides up to the [ShizukuCheckScreen].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Map<String, bool> _permissionStatus = {
    'microphone': false,
    'phone': false,
    'contacts': false,
    'location': false,
    'overlay': false,
    'storage': false,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await AppPermissions.getDetailedStatus();
    if (mounted) {
      setState(() {
        _permissionStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _grantStandardPermissions() async {
    await AppPermissions.requestStandardPermissions();
    await _checkPermissions();
  }

  Future<void> _grantStoragePermission() async {
    await AppPermissions.requestStorageManagement();
    await _checkPermissions();
  }

  Future<void> _grantOverlayPermission() async {
    await AppPermissions.requestOverlayPermission();
    await _checkPermissions();
  }

  bool _allStandardGranted() {
    return _permissionStatus['microphone']! &&
        _permissionStatus['phone']! &&
        _permissionStatus['contacts']! &&
        _permissionStatus['location']!;
  }

  bool _allGranted() {
    return _allStandardGranted() &&
        _permissionStatus['overlay']! &&
        _permissionStatus['storage']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFF0F0F26)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Title section
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup Permissions',
                            style: AppTypography.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Shuni requires several Android permissions to detect and record voice calls.',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Permissions list
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          // 1. Standard permissions group card
                          _buildPermissionCard(
                            title: 'Core Phone & Mic Permissions',
                            description: 'Requires Microphone, Call Logs, Contacts, and Phone state permissions to detect calls and record audio.',
                            isGranted: _allStandardGranted(),
                            onTap: _grantStandardPermissions,
                          ),
                          
                          // 2. Storage management
                          _buildPermissionCard(
                            title: 'Files Access (All Files)',
                            description: 'Required on Android 11+ to write and manage recording files in the public "/Shuni/" folder so they are accessible to you.',
                            isGranted: _permissionStatus['storage']!,
                            onTap: _grantStoragePermission,
                          ),

                          // 3. System alert overlay
                          _buildPermissionCard(
                            title: 'Display Over Other Apps',
                            description: 'Allows drawing the recording widget overlay card on top of active dialer call screens.',
                            isGranted: _permissionStatus['overlay']!,
                            onTap: _grantOverlayPermission,
                          ),
                        ],
                      ),
                    ),

                    // Continue button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _allGranted()
                              ? () {
                                  Navigator.of(context).pushReplacement(
                                    AppAnimations.slideUpRoute(const ShizukuCheckScreen()),
                                  );
                                }
                              : null,
                          child: const Text('Continue to Shizuku Setup'),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        color: isGranted 
            ? AppColors.primary.withOpacity(0.05) 
            : AppColors.surface.withOpacity(0.85),
        border: BorderSide(
          color: isGranted ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorder,
          width: 1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      color: isGranted ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.error_outline,
                  color: isGranted ? AppColors.success : AppColors.accent,
                  size: 28,
                ),
                const SizedBox(height: 12),
                if (!isGranted)
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'GRANT',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
