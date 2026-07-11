import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// # PinInputField
/// 
/// A custom PIN input widget designed after the Linux terminal password entry style:
/// **absolutely zero visual representation of characters entered.**
/// 
/// ## Visual Behavior
/// - No asterisks, no dots, no lines.
/// - Shows a blinking underline or cursor to guide input focus.
/// - The keyboard is strictly restricted to Numeric digits.
/// 
/// ## Feedback Behavior
/// - Emits subtle haptic vibrations (`HapticFeedback.lightImpact`) on every keypress
///   so the user knows their typing registered.
/// 
/// ## Learning Note
/// Standard text fields show characters or replacement dots. To build an invisible field,
/// we hide the input characters using `obscureText: true` and set the obfuscation character
/// to a zero-width space `\u200B`. This makes the characters visually vanish while preserving
/// selection and layout bounds.
class PinInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autoFocus;

  const PinInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autoFocus = true,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    widget.controller.addListener(_handleTextChanges);
  }

  void _handleTextChanges() {
    // Trigger vibration on input changes
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanges);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).requestFocus(widget.focusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Invisible text field that manages active keyboard input
          SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              obscureText: true,
              obscuringCharacter: '\u200B', // Obscure with zero-width spaces (literally invisible)
              autofocus: widget.autoFocus,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(
                fontSize: 1,
                color: Colors.transparent,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Visual indicator (Linux terminal style)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.focusNode.hasFocus 
                    ? AppColors.primary.withOpacity(0.5) 
                    : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Password:',
                  style: AppTypography.headlineMedium.copyWith(
                    fontFamily: 'Courier', // Terminal monospace styling
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                // Blinking cursor
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: widget.focusNode.hasFocus 
                          ? _animationController.value 
                          : 0.0,
                      child: Container(
                        width: 10,
                        height: 20,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Type your PIN. Zero characters will be shown on screen.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
