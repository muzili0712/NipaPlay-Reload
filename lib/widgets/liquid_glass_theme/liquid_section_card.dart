import 'package:flutter/material.dart';

Widget buildLiquidSectionCard({
  required BuildContext context,
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  double borderRadius = 28,
  Brightness? brightnessOverride,
}) {
  final brightness = brightnessOverride ?? Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  final borderColor =
      isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06);
  final shadowColor =
      isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.05);

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 28,
          offset: const Offset(0, 22),
        ),
      ],
    ),
    padding: padding,
    child: child,
  );
}
