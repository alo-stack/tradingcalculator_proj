import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

/// Calculator Screen Wrapper with styled app bar
class CalculatorScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  const CalculatorScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  const SizedBox(width: 70),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Section Card for grouping inputs
class CalculatorSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsets? padding;

  const CalculatorSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: 12,
            ),
            child: Text(
              title!.toUpperCase(),
              style: AppTypography.sectionHeader(),
            ),
          ),
        ],
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.transparent,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Styled Input Field for Calculator Screens
class CalculatorInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefixText;
  final String? suffix;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  const CalculatorInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixText,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.number,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        prefixText: prefixText,
        prefixStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 15,
        ),
        suffixText: suffix,
        suffixStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.accent, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      onTap: () => HapticFeedback.selectionClick(),
    );
  }
}

/// Selector button for dropdowns/dialogs
class CalculatorSelector extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const CalculatorSelector({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.text(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: AppRadius.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.sm,
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: AppTypography.text(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Result display row
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;
  final bool isNegative;
  final bool isLarge;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.isPositive = false,
    this.isNegative = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = AppColors.textPrimary;
    if (isPositive) {
      valueColor = AppColors.positive;
    } else if (isNegative) {
      valueColor = AppColors.negative;
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: isLarge
                ? GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )
                : GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOut, duration: 220.ms).fadeIn(duration: 220.ms);
  }
}

/// Calculate button
class CalculateButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;

  const CalculateButton({
    super.key,
    required this.onPressed,
    this.label = 'Calculate',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pill,
          ),
          elevation: 0,
          textStyle: AppTypography.text(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: isLoading ? null : () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }
}

/// Error/Warning message display
class MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const MessageBanner({
    super.key,
    required this.message,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isError ? AppColors.negativeBg : AppColors.positiveBg,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: isError ? AppColors.negative : AppColors.positive,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? AppColors.negative : AppColors.positive,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.text(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
