// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

Color _resolveIndicatorColor(
  Color? candidate,
  CupertinoThemeData theme,
) {
  if (candidate != null) {
    return candidate;
  }
  final fallback = theme.textTheme.textStyle.color;
  if (fallback != null) {
    return fallback.withValues(alpha: 0.15);
  }
  return CupertinoColors.systemGrey.withValues(alpha: 0.15);
}

Color _scaleAlpha(Color color, double opacityFactor) {
  final baseAlpha = color.alpha / 255.0;
  final newAlpha = (baseAlpha * opacityFactor).clamp(0.0, 1.0);
  return color.withValues(alpha: newAlpha);
}

/// 创建果冻弹性矩阵，基于手势速度生成更自然的挤压/拉伸效果
Matrix4 buildJellyTransform({
  required Offset velocity,
  double maxDistortion = 0.7,
  double velocityScale = 1000.0,
}) {
  final speed = velocity.distance;
  final direction = speed > 0 ? velocity / speed : Offset.zero;
  final distortionFactor =
      (speed / velocityScale).clamp(0.0, 1.0) * maxDistortion;

  if (distortionFactor == 0) {
    return Matrix4.identity();
  }

  final squashX = 1.0 - (direction.dx.abs() * distortionFactor * 0.5);
  final squashY = 1.0 - (direction.dy.abs() * distortionFactor * 0.5);
  final stretchX = 1.0 + (direction.dy.abs() * distortionFactor * 0.3);
  final stretchY = 1.0 + (direction.dx.abs() * distortionFactor * 0.3);

  final scaleX = squashX * stretchX;
  final scaleY = squashY * stretchY;
  final skewX = direction.dx * distortionFactor * 0.2;
  final skewY = direction.dy * distortionFactor * 0.2;

  final matrix = Matrix4.identity();
  matrix.setEntry(0, 1, skewX);
  matrix.setEntry(1, 0, skewY);
  matrix.scale(scaleX, scaleY);

  return matrix;
}

class LiquidGlassBottomBar extends StatefulWidget {
  const LiquidGlassBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.extraButton,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.bottomPadding = 20,
    this.barHeight = 64,
    this.glassSettings,
    this.showIndicator = true,
    this.indicatorColor,
  });

  final List<LiquidGlassBottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final LiquidGlassBottomBarExtraButton? extraButton;
  final double spacing;
  final double horizontalPadding;
  final double bottomPadding;
  final double barHeight;
  final LiquidGlassSettings? glassSettings;
  final bool showIndicator;
  final Color? indicatorColor;

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar> {
  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    final glassSettings = widget.glassSettings ??
        LiquidGlassSettings(
          refractiveIndex: 1.21,
          thickness: 30,
          blur: 8,
          saturation: 1.5,
          blend: 10,
          lightIntensity: isDark ? .7 : 1,
          ambientStrength: isDark ? .2 : .5,
          lightAngle: math.pi / 4,
          glassColor: CupertinoTheme.of(context)
              .barBackgroundColor
              .withValues(alpha: 0.6),
        );

    return LiquidGlassLayer(
      settings: glassSettings,
      child: Padding(
        padding: EdgeInsets.only(
          right: widget.horizontalPadding,
          left: widget.horizontalPadding,
          bottom: widget.bottomPadding,
          top: widget.bottomPadding,
        ),
        child: Row(
          spacing: widget.spacing,
          children: [
            Expanded(
              child: _TabIndicator(
                visible: widget.showIndicator,
                tabIndex: widget.selectedIndex,
                tabCount: widget.tabs.length,
                indicatorColor: widget.indicatorColor,
                onTabChanged: widget.onTabSelected,
                child: LiquidStretch(
                  child: LiquidGlass.inLayer(
                    clipBehavior: Clip.none,
                    shape: const LiquidRoundedSuperellipse(
                      borderRadius: Radius.circular(32),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: widget.barHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (var i = 0; i < widget.tabs.length; i++)
                            Expanded(
                              child: _BottomBarTab(
                                tab: widget.tabs[i],
                                selected: widget.selectedIndex == i,
                                onTap: () => widget.onTabSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.extraButton != null)
              _ExtraButton(config: widget.extraButton!),
          ],
        ),
      ),
    );
  }
}

class LiquidGlassBottomBarTab {
  const LiquidGlassBottomBarTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.glowColor,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Color? glowColor;
}

class LiquidGlassBottomBarExtraButton {
  const LiquidGlassBottomBarExtraButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.size = 64,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final double size;
}

class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final LiquidGlassBottomBarTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final iconColor =
        selected ? theme.primaryColor : theme.textTheme.textStyle.color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: tab.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (tab.glowColor != null)
                      Positioned(
                        top: -24,
                        right: -24,
                        left: -24,
                        bottom: -24,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          transformAlignment: Alignment.center,
                          curve: Curves.easeOutCirc,
                          transform: selected
                              ? Matrix4.identity()
                              : (Matrix4.identity()
                                ..scale(0.4)
                                ..rotateZ(-math.pi)),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: selected ? 1 : 0,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCirc,
                            builder: (context, value, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _scaleAlpha(
                                        tab.glowColor!,
                                        value * 0.6,
                                      ),
                                      blurRadius: 32,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        selected ? (tab.selectedIcon ?? tab.icon) : tab.icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraButton extends StatefulWidget {
  const _ExtraButton({required this.config});

  final LiquidGlassBottomBarExtraButton config;

  @override
  State<_ExtraButton> createState() => _ExtraButtonState();
}

class _ExtraButtonState extends State<_ExtraButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.config.onTap();
      },
      child: LiquidStretch(
        child: Semantics(
          button: true,
          label: widget.config.label,
          child: SingleMotionBuilder(
            motion: Motion.interactiveSpring(),
            value: _pressed ? 1.2 : 1,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: LiquidGlass.inLayer(
              shape: const LiquidOval(),
              child: GlassGlow(
                child: SizedBox(
                  height: widget.config.size,
                  width: widget.config.size,
                  child: Center(
                    child: Icon(
                      widget.config.icon,
                      size: 24,
                      color: theme.textTheme.textStyle.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIndicator extends StatefulWidget {
  const _TabIndicator({
    required this.child,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
    this.visible = true,
    this.indicatorColor,
  });

  final int tabIndex;
  final int tabCount;
  final bool visible;
  final Widget child;
  final Color? indicatorColor;
  final ValueChanged<int> onTabChanged;

  @override
  State<_TabIndicator> createState() => _TabIndicatorState();
}

class _TabIndicatorState extends State<_TabIndicator>
    with SingleTickerProviderStateMixin {
  bool _isDown = false;
  bool _isDragging = false;

  late double xAlign = computeXAlignmentForTab(widget.tabIndex);

  @override
  void initState() {
    super.initState();
  }

  double computeXAlignmentForTab(int tabIndex) {
    if (widget.tabCount <= 1) {
      return -1;
    }
    final relativeTabIndex = (tabIndex / (widget.tabCount - 1)).clamp(0.0, 1.0);
    return (relativeTabIndex * 2) - 1;
  }

  @override
  void didUpdateWidget(covariant _TabIndicator oldWidget) {
    if (oldWidget.tabIndex != widget.tabIndex ||
        oldWidget.tabCount != widget.tabCount) {
      setState(() {
        xAlign = computeXAlignmentForTab(widget.tabIndex);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  double _getAlignmentFromGlobalPostition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);

    final indicatorWidth = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - indicatorWidth;
    final padding = indicatorWidth / 2;

    final rawRelativeX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final normalizedX = (rawRelativeX - padding) / draggableRange;

    final adjustedRelativeX = _applyRubberBandResistance(normalizedX);
    return (adjustedRelativeX * 2) - 1;
  }

  void _onDragDown(DragDownDetails details) {
    setState(() {
      _isDown = true;
      xAlign = _getAlignmentFromGlobalPostition(details.globalPosition);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      xAlign = _getAlignmentFromGlobalPostition(details.globalPosition);
    });
  }

  double _applyRubberBandResistance(double value) {
    const double resistance = 0.4;
    const double maxOverdrag = 0.3;

    if (value < 0) {
      final overdrag = -value;
      final resistedOverdrag = overdrag * resistance;
      return -resistedOverdrag.clamp(0.0, maxOverdrag);
    } else if (value > 1) {
      final overdrag = value - 1;
      final resistedOverdrag = overdrag * resistance;
      return 1 + resistedOverdrag.clamp(0.0, maxOverdrag);
    } else {
      return value;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final box = context.findRenderObject() as RenderBox;
    final currentRelativeX = (xAlign + 1) / 2;
    final tabWidth = 1.0 / widget.tabCount;

    final indicatorWidth = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - indicatorWidth;
    final velocityX =
        (details.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;

    int targetTabIndex;

    if (currentRelativeX < 0) {
      targetTabIndex = 0;
    } else if (currentRelativeX > 1) {
      targetTabIndex = widget.tabCount - 1;
    } else {
      const velocityThreshold = 0.5;
      if (velocityX.abs() > velocityThreshold) {
        final projectedX = (currentRelativeX + velocityX * 0.3).clamp(0.0, 1.0);
        targetTabIndex =
            (projectedX / tabWidth).round().clamp(0, widget.tabCount - 1);

        final currentTabIndex =
            (currentRelativeX / tabWidth).round().clamp(0, widget.tabCount - 1);
        if (velocityX > velocityThreshold &&
            targetTabIndex <= currentTabIndex &&
            currentTabIndex < widget.tabCount - 1) {
          targetTabIndex = currentTabIndex + 1;
        } else if (velocityX < -velocityThreshold &&
            targetTabIndex >= currentTabIndex &&
            currentTabIndex > 0) {
          targetTabIndex = currentTabIndex - 1;
        }
      } else {
        targetTabIndex =
            (currentRelativeX / tabWidth).round().clamp(0, widget.tabCount - 1);
      }
    }
    xAlign = computeXAlignmentForTab(targetTabIndex);

    if (targetTabIndex != widget.tabIndex) {
      widget.onTabChanged(targetTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final indicatorColor = _resolveIndicatorColor(
      widget.indicatorColor,
      theme,
    );
    final targetAlignment = computeXAlignmentForTab(widget.tabIndex);

    return GestureDetector(
      onHorizontalDragDown: _onDragDown,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => setState(() {
        _isDragging = false;
        _isDown = false;
      }),
      child: VelocityMotionBuilder(
        converter: SingleMotionConverter(),
        value: xAlign,
        motion: _isDragging
            ? const Motion.interactiveSpring()
            : const Motion.bouncySpring(),
        builder: (context, value, velocity, child) {
          final alignment = Alignment(value, 0);
          return SingleMotionBuilder(
            motion: const Motion.snappySpring(
              duration: Duration(milliseconds: 300),
            ),
            value: widget.visible &&
                    (_isDown || (alignment.x - targetAlignment).abs() > 0.30)
                ? 1.0
                : 0.0,
            builder: (context, thickness, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (thickness < 1)
                    _IndicatorTransform(
                      velocity: velocity,
                      tabCount: widget.tabCount,
                      alignment: alignment,
                      thickness: thickness,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: widget.visible && thickness <= .2 ? 1 : 0,
                        ),
                        duration: const Duration(milliseconds: 120),
                        builder: (context, value, child) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: _scaleAlpha(indicatorColor, value),
                              borderRadius: BorderRadius.circular(64),
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  child!,
                  if (thickness > 0)
                    _IndicatorTransform(
                      velocity: velocity,
                      tabCount: widget.tabCount,
                      alignment: alignment,
                      thickness: thickness,
                      child: LiquidGlass(
                        settings: LiquidGlassSettings(
                          glassColor: Color.from(
                            alpha: .1 * thickness,
                            red: 1,
                            green: 1,
                            blue: 1,
                          ),
                          saturation: 1 + .5 * thickness,
                          refractiveIndex: 1.15,
                          thickness: thickness * 15,
                          lightIntensity: 2,
                          chromaticAberration: .5,
                        ),
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: Radius.circular(64),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              );
            },
            child: widget.child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _IndicatorTransform extends StatelessWidget {
  const _IndicatorTransform({
    required this.velocity,
    required this.tabCount,
    required this.alignment,
    required this.thickness,
    required this.child,
  });

  final double velocity;
  final int tabCount;
  final Alignment alignment;
  final double thickness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      const RelativeRect.fromLTRB(-14, -14, -14, -14),
      thickness,
    );
    return Positioned.fill(
      left: 4,
      right: 4,
      top: 4,
      bottom: 4,
      child: FractionallySizedBox(
        widthFactor: 1 / tabCount,
        alignment: alignment,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRelativeRect(
              rect: rect!,
              child: SingleMotionBuilder(
                motion: Motion.bouncySpring(
                  duration: const Duration(milliseconds: 600),
                ),
                value: velocity,
                builder: (context, velocity, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: buildJellyTransform(
                      velocity: Offset(velocity, 0),
                      maxDistortion: .8,
                      velocityScale: 10,
                    ),
                    child: child,
                  );
                },
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
