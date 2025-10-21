import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nipaplay/providers/appearance_settings_provider.dart';
import 'package:nipaplay/widgets/liquid_glass_theme/liquid_glass_bottom_bar.dart';
import 'package:nipaplay/widgets/nipaplay_theme/background_with_blur.dart';
import 'package:nipaplay/widgets/nipaplay_theme/custom_scaffold.dart';
import 'package:nipaplay/widgets/nipaplay_theme/switchable_view.dart';
import 'package:provider/provider.dart';

class LiquidGlassScaffold extends StatefulWidget {
  const LiquidGlassScaffold({
    super.key,
    required this.pages,
    required this.tabController,
    required this.tabs,
    required this.showNavigation,
  });

  final List<Widget> pages;
  final TabController? tabController;
  final List<LiquidGlassBottomBarTab> tabs;
  final bool showNavigation;

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

  void _handleTabChanged() {
    final controller = _tabController;
    if (controller == null || !mounted) {
      return;
    }
    if (_currentIndex != controller.index) {
      setState(() {
        _currentIndex = controller.index;
      });
    }
  }

  void _onBottomTabSelected(int index) {
    final controller = _tabController;
    if (controller == null) {
      return;
    }
    if (controller.index != index) {
      controller.animateTo(index);
    }
    setState(() {
      _currentIndex = index;
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

    final appearanceSettings = Provider.of<AppearanceSettingsProvider>(context);
    final enableAnimation = appearanceSettings.enablePageAnimation;

    final brightness = Theme.of(context).brightness;
    final cupertinoTheme = CupertinoThemeData(
      brightness:
          brightness == Brightness.dark ? Brightness.dark : Brightness.light,
      primaryColor: CupertinoColors.activeBlue,
      barBackgroundColor: brightness == Brightness.dark
          ? CupertinoColors.black.withOpacity(0.2)
          : CupertinoColors.extraLightBackgroundGray.withOpacity(0.2),
    );

    final bottomBarTabs = widget.tabs;

    return Stack(
      children: [
        // 背景层
        const BackgroundWithBlur(
          child: SizedBox.expand(),
        ),
        // 添加夜间模式遮罩层，覆盖整个屏幕包括状态栏
        if (brightness == Brightness.dark)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        // 主内容
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              // 主内容区域 - 包含标题和页面内容
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // 苹果风格大标题导航栏
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 40,
                        bottom: 24,
                      ),
                      child: Text(
                        bottomBarTabs[_currentIndex.clamp(
                                0, bottomBarTabs.length - 1)]
                            .label,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          height: 1.2,
                        ),
                      ),
                    ),
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
                              .map((page) => RepaintBoundary(child: page))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 底部导航栏 - 更贴近底部
              if (widget.showNavigation)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 0, // 减少边距让导航栏更靠下
                  child: CupertinoTheme(
                    data: cupertinoTheme,
                    child: LiquidGlassBottomBar(
                      tabs: bottomBarTabs,
                      selectedIndex:
                          _currentIndex.clamp(0, bottomBarTabs.length - 1),
                      onTabSelected: _onBottomTabSelected,
                      showIndicator: true,
                      barHeight: 64, // 增加高度让导航栏更圆润
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

List<LiquidGlassBottomBarTab> createLiquidGlassTabs() {
  final isIOS = !_isWeb && defaultTargetPlatform == TargetPlatform.iOS;
  final items = <LiquidGlassBottomBarTab>[
    const LiquidGlassBottomBarTab(
      label: '主页',
      icon: CupertinoIcons.house,
      selectedIcon: CupertinoIcons.house_fill,
      glowColor: CupertinoColors.systemBlue,
    ),
    const LiquidGlassBottomBarTab(
      label: '播放',
      icon: CupertinoIcons.play_rectangle,
      selectedIcon: CupertinoIcons.play_rectangle_fill,
      glowColor: CupertinoColors.systemGreen,
    ),
    const LiquidGlassBottomBarTab(
      label: '媒体库',
      icon: CupertinoIcons.square_grid_2x2,
      selectedIcon: CupertinoIcons.square_grid_2x2,
      glowColor: CupertinoColors.systemPurple,
    ),
  ];

  if (!isIOS) {
    items.add(
      const LiquidGlassBottomBarTab(
        label: '新番',
        icon: CupertinoIcons.sparkles,
        selectedIcon: CupertinoIcons.sparkles,
        glowColor: CupertinoColors.systemOrange,
      ),
    );
  }

  items.add(
    const LiquidGlassBottomBarTab(
      label: '设置',
      icon: CupertinoIcons.settings,
      selectedIcon: CupertinoIcons.settings_solid,
      glowColor: CupertinoColors.systemIndigo,
    ),
  );

  return items;
}

bool get _isWeb => kIsWeb;
