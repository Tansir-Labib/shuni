import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// # RecordingIndicator
/// 
/// A blinking/flashing red status badge that signals an active call recording is in progress.
/// 
/// ## Learning Note
/// Standard blinking states can be achieved using a simple loop inside a StatefulWidget
/// and an [AnimationController]. By repeating the animation with `reverse: true`, the opacity
/// oscillates smoothly, giving a premium glowing pulse effect rather than a harsh blinking transition.
class RecordingIndicator extends StatefulWidget {
  final String label;

  const RecordingIndicator({
    super.key,
    this.label = 'REC',
  });

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.recording.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.recording.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsating red dot
          AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.recording,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.recording,
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          // Tag Label
          Text(
            widget.label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.recording,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
