import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recording_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/animations.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shizuku_status_badge.dart';
import '../home/home_screen.dart';

/// # ShizukuCheckScreen
/// 
/// Validates that Shizuku is active and authorized before allowing access to Shuni.
/// 
/// ## Features
/// - Real-time Shizuku status badge listener.
/// - Detailed instructions on how to install, launch, and pair Shizuku.
/// - "Request Permission" triggers native Shizuku binding popups.
/// - Activates "Get Started" once Shizuku resolves to `ready`.
class ShizukuCheckScreen extends ConsumerWidget {
  const ShizukuCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingProvider);
    final String status = recordingState.shizukuStatusString;
    final bool isReady = recordingState.isShizukuReady;

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shizuku Configuration',
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shuni requires Shizuku to record two-way audio on Android 16 without rooting.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Status Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  color: isReady 
                      ? AppColors.success.withOpacity(0.05) 
                      : AppColors.surface.withOpacity(0.85),
                  border: BorderSide(
                    color: isReady ? AppColors.success.withOpacity(0.3) : AppColors.cardBorder,
                    width: 1.5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status Connection',
                        style: AppTypography.titleMedium,
                      ),
                      ShizukuStatusBadge(
                        status: status,
                        onTap: () {
                          ref.read(recordingProvider.notifier).checkShizukuStatus();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Instructions / Guide
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Configuration Guide:',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildStep(
                      stepNumber: '1',
                      title: 'Install Shizuku',
                      description: 'If you haven\'t, install Shizuku from the Google Play Store.',
                    ),
                    _buildStep(
                      stepNumber: '2',
                      title: 'Start Shizuku Service',
                      description: 'Open Shizuku. Turn on Wireless Debugging in Android Developer Options, then complete the pairing process in Shizuku and tap "Start".',
                    ),
                    _buildStep(
                      stepNumber: '3',
                      title: 'Authorize Shuni',
                      description: 'Tap the button below to trigger the Shizuku authorization dialog and select "Allow Always".',
                    ),
                  ],
                ),
              ),

              // Actions Bottom Panel
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (!isReady && status == 'unauthorized')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(recordingProvider.notifier).requestShizukuAccess();
                          },
                          child: const Text('Authorize Shuni'),
                        ),
                      )
                    else if (!isReady)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(recordingProvider.notifier).checkShizukuStatus();
                          },
                          child: const Text('Recheck Status'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    
                    // Proceed button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isReady
                            ? () {
                                Navigator.of(context).pushReplacement(
                                  AppAnimations.fadeRoute(const HomeScreen()),
                                );
                              }
                            : null,
                        child: const Text('Start Using Shuni'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              stepNumber,
              style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
