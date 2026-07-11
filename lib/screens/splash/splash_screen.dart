import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/animations.dart';
import '../lock/lock_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import '../../core/permissions.dart';

/// # SplashScreen
/// 
/// The initial landing screen of the Shuni application.
/// 
/// ## Responsibilities
/// - Renders an animated fade-in app branding logotype and slogan.
/// - Determines the routing path based on settings states:
///   1. If permissions are missing → goes to Onboarding.
///   2. If a PIN is configured → redirects to the LockScreen.
///   3. Otherwise → redirects to the HomeScreen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _logoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startAnimationAndRouting();
  }

  Future<void> _startAnimationAndRouting() async {
    // 1. Fade in logo
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _logoOpacity = 1.0;
      });
    }

    // 2. Wait for branding display
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 3. Verify permissions first. If missing, redirect to onboarding flow.
    final bool hasPermissions = await AppPermissions.hasAllRequiredPermissions();
    if (!hasPermissions) {
      _navigateTo(const OnboardingScreen());
      return;
    }

    // 4. Retrieve auth states
    final authState = ref.read(authProvider);
    
    if (authState.hasPin) {
      _navigateTo(const LockScreen());
    } else {
      _navigateTo(const HomeScreen());
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      AppAnimations.fadeRoute(page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              Color(0xFF101030), // Deep blue accent glow
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _logoOpacity,
            duration: AppAnimations.slow,
            curve: Curves.easeIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo representation
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic_none_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Name
                Text(
                  AppConstants.appName,
                  style: AppTypography.displayLarge.copyWith(
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appNameBangla,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Slogan
                Text(
                  AppConstants.slogan,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.sloganEnglish,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
