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

    return BackgroundWithBlur(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
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
              if (widget.showNavigation)
                SafeArea(
                  top: false,
                  minimum: EdgeInsets.only(
                    left: _isCupertinoPlatform ? 0 : 16,
                    right: _isCupertinoPlatform ? 0 : 16,
                    bottom: _isCupertinoPlatform ? 12 : 16,
                  ),
                  child: CupertinoTheme(
                    data: cupertinoTheme,
                    child: LiquidGlassBottomBar(
                      tabs: bottomBarTabs,
                      selectedIndex:
                          _currentIndex.clamp(0, bottomBarTabs.length - 1),
                      onTabSelected: _onBottomTabSelected,
                      showIndicator: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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

bool get _isCupertinoPlatform {
  if (_isWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS;
}

bool get _isWeb => kIsWeb;
