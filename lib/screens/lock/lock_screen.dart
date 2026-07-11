import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/animations.dart';
import '../../widgets/pin_input_field.dart';
import '../home/home_screen.dart';

/// # LockScreen
/// 
/// The application entry guard. Enforces biometric verification or Linux-style PIN entry.
/// 
/// ## Visual Styling
/// - Black AMOLED background.
/// - Zero feedback PIN input.
/// - Interactive shake offset animation to notify users of wrong keys.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  
  // Animation for wrong pin shake feedback
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 370),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    // Auto-trigger biometric prompt on launch if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometric();
    });
  }

  Future<void> _attemptBiometric() async {
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    if (authState.isBiometricAvailable) {
      final bool success = await authNotifier.attemptBiometricUnlock();
      if (success && mounted) {
        _navigateToHome();
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      AppAnimations.fadeRoute(const HomeScreen()),
    );
  }

  Future<void> _handlePinSubmitted(String pin) async {
    if (pin.isEmpty) return;

    final authNotifier = ref.read(authProvider.notifier);
    final bool success = await authNotifier.attemptPinUnlock(pin);

    if (success) {
      _navigateToHome();
    } else {
      // Clear input and trigger shake
      _pinController.clear();
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                // Creates a horizontal shifting shake effect
                final double dx = _shakeAnimation.value * 
                    (double.parse((_shakeController.value * 10).toStringAsFixed(0)) % 2 == 0 ? 1 : -1);
                
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App branding
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Shuni Secured',
                    style: AppTypography.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your security credentials to unlock call archives.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // PIN entry input
                  if (authState.isLockedOut) ...[
                    // Lockout countdown visualizer
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.error, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            'Too many wrong attempts.',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.error),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try again in ${authState.lockoutSecondsRemaining} seconds.',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Zero feedback PIN editor
                    PinInputField(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      onSubmitted: _handlePinSubmitted,
                      onChanged: (val) {
                        // Optional live checking if length is fixed,
                        // otherwise submit when pressing enter on keyboard.
                      },
                    ),
                    
                    if (authState.error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        authState.error,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ],
                  ],
                  const SizedBox(height: 48),

                  // Biometrics fallback trigger button
                  if (authState.isBiometricAvailable && !authState.isLockedOut)
                    IconButton(
                      icon: const Icon(Icons.fingerprint, size: 48, color: AppColors.primary),
                      onPressed: _attemptBiometric,
                      tooltip: 'Unlock with fingerprint',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
