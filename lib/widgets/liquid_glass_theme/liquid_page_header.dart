import 'package:flutter/material.dart';

class LiquidPageHeader extends StatelessWidget {
  const LiquidPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.bottom,
    this.padding,
    this.titleFontSize,
    this.subtitleFontSize,
    this.titleLetterSpacing,
    this.subtitleSpacing,
    this.bottomSpacing,
    this.alignment = CrossAxisAlignment.start,
  });

  final String title;
  final String? subtitle;
  final Widget? bottom;
  final EdgeInsetsGeometry? padding;
  final double? titleFontSize;
  final double? subtitleFontSize;
  final double? titleLetterSpacing;
  final double? subtitleSpacing;
  final double? bottomSpacing;
  final CrossAxisAlignment alignment;

  static const double _defaultSubtitleSpacing = 8;
  static const double _defaultBottomSpacing = 20;
  static const double _defaultLetterSpacing = 0.4;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color titleColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    final double subtitleOpacity = brightness == Brightness.dark ? 0.72 : 0.65;
    final Color subtitleColor = titleColor.withOpacity(subtitleOpacity);

    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12);
    final double effectiveTitleFontSize = titleFontSize ?? 32;
    final double effectiveSubtitleFontSize = subtitleFontSize ?? 14;
    final double effectiveLetterSpacing =
        titleLetterSpacing ?? _defaultLetterSpacing;
    final double effectiveSubtitleSpacing =
        subtitle == null || subtitle!.isEmpty
            ? 0
            : (subtitleSpacing ?? _defaultSubtitleSpacing);
    final double effectiveBottomSpacing =
        bottom == null ? 0 : (bottomSpacing ?? _defaultBottomSpacing);

    return Padding(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: effectiveTitleFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: effectiveLetterSpacing,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: effectiveSubtitleSpacing),
            Text(
              subtitle!,
              style: TextStyle(
                color: subtitleColor,
                fontSize: effectiveSubtitleFontSize,
              ),
            ),
          ],
          if (bottom != null) ...[
            SizedBox(height: effectiveBottomSpacing),
            bottom!,
          ],
        ],
      ),
    );
  }
}
