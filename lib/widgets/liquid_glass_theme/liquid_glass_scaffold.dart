import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nipaplay/providers/appearance_settings_provider.dart';
import 'package:nipaplay/widgets/liquid_glass_theme/liquid_glass_bottom_bar.dart';
import 'package:nipaplay/widgets/nipaplay_theme/custom_scaffold.dart';
import 'package:nipaplay/widgets/nipaplay_theme/switchable_view.dart';
import 'package:nipaplay/utils/video_player_state.dart';
import 'package:provider/provider.dart';

class LiquidGlassScaffold extends StatefulWidget {
  const LiquidGlassScaffold({
    super.key,
    required this.pages,
    required this.tabController,
    required this.tabs,
    required this.showNavigation,
    this.visibleTabIndices,
    this.onPlusPressed,
  });

  final List<Widget> pages;
  final TabController? tabController;
  final List<LiquidGlassBottomBarTab> tabs;
  final bool showNavigation;
  final List<int>? visibleTabIndices;
  final VoidCallback? onPlusPressed;

  @override
  State<LiquidGlassScaffold> createState() => _LiquidGlassScaffoldState();
}

class _LiquidGlassScaffoldState extends State<LiquidGlassScaffold> {
  int _currentIndex = 0;

  TabController? get _tabController => widget.tabController;

  @override
  void initState() {
    super.initState();
    _attachController(widget.tabController);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController != widget.tabController) {
      _detachController(oldWidget.tabController);
      _attachController(widget.tabController);
    }
  }

  void _attachController(TabController? controller) {
    if (controller == null) {
      return;
    }
    _currentIndex = controller.index;
    controller.addListener(_handleTabChanged);
  }

  void _detachController(TabController? controller) {
    controller?.removeListener(_handleTabChanged);
  }

  List<int> get _visibleTabIndices {
    final controller = _tabController;
    final mapping = widget.visibleTabIndices;
    if (mapping != null &&
        mapping.length == widget.tabs.length &&
        (controller == null ||
            mapping.every(
              (index) => index >= 0 && index < controller.length,
            ))) {
      return mapping;
    }
    final fallbackLength = controller?.length ?? widget.tabs.length;
    if (fallbackLength <= 0) {
      return List<int>.filled(widget.tabs.length, 0);
    }
    return List<int>.generate(widget.tabs.length, (index) {
      if (index < fallbackLength) {
        return index;
      }
      return fallbackLength - 1;
    });
  }

  void _handleTabChanged() {
    final controller = _tabController;
    if (controller == null || !mounted) {
      return;
    }
    final newIndex = controller.index;
    final allowedIndices = _visibleTabIndices;
    if (!allowedIndices.contains(newIndex)) {
      final videoState = context.read<VideoPlayerState>();
      if (videoState.shouldShowAppBar()) {
        final fallbackIndex =
            allowedIndices.isNotEmpty ? allowedIndices.first : 0;
        if (fallbackIndex != newIndex) {
          controller.animateTo(fallbackIndex);
          return;
        }
      }
    }
    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _onBottomTabSelected(int index) {
    final controller = _tabController;
    if (controller == null) {
      return;
    }
    final indices = _visibleTabIndices;
    if (index < 0 || index >= indices.length) {
      return;
    }
    final targetIndex = indices[index];
    final safeIndex = targetIndex < 0
        ? 0
        : targetIndex >= controller.length
            ? controller.length - 1
            : targetIndex;
    if (controller.index != safeIndex) {
      controller.animateTo(safeIndex);
    }
    setState(() {
      _currentIndex = safeIndex;
    });
  }

  void _handlePageChanged(int index) {
    final controller = _tabController;
    if (controller == null) {
      return;
    }
    if (controller.index != index) {
      controller.animateTo(index);
    }
  }

  @override
  void dispose() {
    _detachController(widget.tabController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _tabController;
    if (controller == null) {
      return const Center(child: Text('TabController 未初始化'));
    }

    return Consumer2<AppearanceSettingsProvider, VideoPlayerState>(
      builder: (context, appearanceSettings, videoPlayerState, child) {
        final enableAnimation = appearanceSettings.enablePageAnimation;

        final brightness = Theme.of(context).brightness;
        final cupertinoTheme = CupertinoThemeData(
          brightness: brightness == Brightness.dark
              ? Brightness.dark
              : Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
          barBackgroundColor: brightness == Brightness.dark
              ? CupertinoColors.black.withOpacity(0.2)
              : CupertinoColors.extraLightBackgroundGray.withOpacity(0.2),
        );

        final bottomBarTabs = widget.tabs;
        final visibleIndices = _visibleTabIndices;

        // 检查是否应该显示导航栏（视频播放时隐藏）
        final shouldShowNavigation =
            widget.showNavigation && videoPlayerState.shouldShowAppBar();

        final selectedNavIndex = visibleIndices.indexOf(_currentIndex);
        final hasValidSelection = selectedNavIndex >= 0;

        if (shouldShowNavigation &&
            !hasValidSelection &&
            visibleIndices.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _onBottomTabSelected(0);
          });
        }

        final backgroundColor = brightness == Brightness.dark
            ? const Color(0xFF0F0F12)
            : const Color(0xFFF2F2F7);

        return Stack(
          children: [
            // 背景层 - 视频播放时隐藏
            if (shouldShowNavigation)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  color: backgroundColor,
                ),
              ),
            // 主内容
            Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: Stack(
                children: [
                  // 主内容区域 - 根据视频播放状态决定是否使用SafeArea
                  shouldShowNavigation
                      ? SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              // 苹果风格大标题导航栏 - 已取消
                              // Container(
                              //   width: double.infinity,
                              //   padding: const EdgeInsets.only(
                              //     left: 20,
                              //     right: 20,
                              //     top: 40,
                              //     bottom: 24,
                              //   ),
                              //   child: Text(
                              //     bottomBarTabs[_currentIndex.clamp(
                              //             0, bottomBarTabs.length - 1)]
                              //         .label,
                              //     style: const TextStyle(
                              //       fontSize: 36,
                              //       fontWeight: FontWeight.bold,
                              //       color: Colors.white,
                              //       letterSpacing: 0.4,
                              //       height: 1.2,
                              //     ),
                              //   ),
                              // ),
                              Expanded(
                                child: TabControllerScope(
                                  controller: controller,
                                  enabled: true,
                                  child: SwitchableView(
                                    controller: controller,
                                    enableAnimation: enableAnimation,
                                    currentIndex: controller.index,
                                    physics: enableAnimation
                                        ? const PageScrollPhysics()
                                        : const NeverScrollableScrollPhysics(),
                                    onPageChanged: _handlePageChanged,
                                    children: widget.pages
                                        .map((page) =>
                                            RepaintBoundary(child: page))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : // 视频播放时：无SafeArea，全屏显示
                      TabControllerScope(
                          controller: controller,
                          enabled: true,
                          child: SwitchableView(
                            controller: controller,
                            enableAnimation: enableAnimation,
                            currentIndex: controller.index,
                            physics: enableAnimation
                                ? const PageScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            onPageChanged: _handlePageChanged,
                            children: widget.pages
                                .map((page) => RepaintBoundary(child: page))
                                .toList(),
                          ),
                        ),
                  // 底部导航栏 - 更贴近底部
                  if (shouldShowNavigation)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 0, // 减少边距让导航栏更靠下
                      child: CupertinoTheme(
                        data: cupertinoTheme,
                        child: LiquidGlassBottomBar(
                          tabs: bottomBarTabs,
                          selectedIndex:
                              hasValidSelection ? selectedNavIndex : 0,
                          onTabSelected: _onBottomTabSelected,
                          showIndicator: hasValidSelection,
                          barHeight: 64, // 增加高度让导航栏更圆润
                          extraButton: widget.onPlusPressed == null
                              ? null
                              : LiquidGlassBottomBarExtraButton(
                                  icon: CupertinoIcons.add,
                                  label: '选择文件',
                                  onTap: widget.onPlusPressed!,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

List<LiquidGlassBottomBarTab> createLiquidGlassTabs() {
  return const <LiquidGlassBottomBarTab>[
    LiquidGlassBottomBarTab(
      label: '主页',
      icon: CupertinoIcons.house,
      selectedIcon: CupertinoIcons.house_fill,
      glowColor: CupertinoColors.systemBlue,
    ),
    LiquidGlassBottomBarTab(
      label: '媒体库',
      icon: CupertinoIcons.square_grid_2x2,
      selectedIcon: CupertinoIcons.square_grid_2x2,
      glowColor: CupertinoColors.systemPurple,
    ),
    LiquidGlassBottomBarTab(
      label: '设置',
      icon: CupertinoIcons.settings,
      selectedIcon: CupertinoIcons.settings_solid,
      glowColor: CupertinoColors.systemIndigo,
    ),
  ];
}

bool get _isWeb => kIsWeb;
