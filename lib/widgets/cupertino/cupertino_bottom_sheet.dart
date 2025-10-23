import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

/// 通用的 Cupertino 风格上拉菜单容器
/// 提供标准的上拉菜单外观和行为，内容完全可自定义
class CupertinoBottomSheet extends StatefulWidget {
  /// 菜单标题（可选）
  final String? title;

  /// 菜单内容，完全可自定义
  final Widget child;

  /// 菜单高度占屏幕的比例，默认 0.94
  final double heightRatio;

  /// 是否显示关闭按钮，默认 true
  final bool showCloseButton;

  /// 自定义关闭按钮回调，如果为 null 则使用默认的 Navigator.pop()
  final VoidCallback? onClose;

  /// 标题是否浮动（浮动标题会随滚动渐隐，不占用布局空间），默认 false
  final bool floatingTitle;

  const CupertinoBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.heightRatio = 0.94,
    this.showCloseButton = true,
    this.onClose,
    this.floatingTitle = false,
  });

  /// 显示上拉菜单的静态方法
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    double heightRatio = 0.94,
    bool showCloseButton = true,
    VoidCallback? onClose,
    bool floatingTitle = false,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) => CupertinoBottomSheet(
        title: title,
        child: child,
        heightRatio: heightRatio,
        showCloseButton: showCloseButton,
        onClose: onClose,
        floatingTitle: floatingTitle,
      ),
    );
  }

  @override
  State<CupertinoBottomSheet> createState() => _CupertinoBottomSheetState();
}

class _CupertinoBottomSheetState extends State<CupertinoBottomSheet> {
  double _scrollOffset = 0;

  bool get _hasTitle => widget.title != null && widget.title!.isNotEmpty;

  bool get _useFloatingTitle => widget.floatingTitle && _hasTitle;

  double get _floatingTitleOpacity =>
      (1.0 - (_scrollOffset / _floatingTitleFadeDistance)).clamp(0.0, 1.0);

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_useFloatingTitle) {
      return false;
    }

    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final double pixels =
        notification.metrics.pixels.clamp(0.0, double.infinity).toDouble();
    if ((pixels - _scrollOffset).abs() < 0.5) {
      return false;
    }

    setState(() {
      _scrollOffset = pixels;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double effectiveHeightRatio =
        widget.heightRatio.clamp(0.0, 1.0).toDouble();
    final double maxHeight = screenHeight * effectiveHeightRatio;
    final bool displayHeader = _hasTitle && !widget.floatingTitle;

    Widget content = widget.child;
    if (displayHeader) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(child: widget.child),
        ],
      );
    } else {
      final double topPadding = _calculateContentTopPadding(displayHeader);
      Widget paddedChild = Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: widget.child,
      );

      if (_useFloatingTitle) {
        paddedChild = NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: paddedChild,
        );
      }

      content = paddedChild;
    }

    final Color backgroundColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGroupedBackground,
      context,
    );

    final List<Widget> stackChildren = [
      Positioned.fill(child: content),
    ];

    final double gradientHeight = _useFloatingTitle
        ? _topOverlayReservedHeight() + _floatingTitleGradientExtra
        : 0;

    if (_useFloatingTitle) {
      stackChildren
        ..add(
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: gradientHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor,
                      backgroundColor.withOpacity(0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        )
        ..add(
          Positioned(
            top: _floatingTitleTop,
            left: _floatingTitleHorizontalPadding,
            right: widget.showCloseButton
                ? _floatingTitleRightPaddingWithClose
                : _floatingTitleHorizontalPadding,
            child: IgnorePointer(
              child: Opacity(
                opacity: _floatingTitleOpacity,
                child: Text(
                  widget.title!,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .navTitleTextStyle
                      .copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        );
    }

    if (widget.showCloseButton) {
      stackChildren.add(
        Positioned(
          top: _closeButtonPadding,
          right: _closeButtonPadding,
          child: _buildCloseButton(context),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          height: maxHeight,
          color: backgroundColor,
          child: SafeArea(
            top: false,
            child: Stack(children: stackChildren),
          ),
        ),
      ),
    );
  }

  double _calculateContentTopPadding(bool displayHeader) {
    if (displayHeader) {
      return 0;
    }
    return 0;
  }

  double _topOverlayReservedHeight() {
    if (!widget.showCloseButton) {
      return 0;
    }
    return _closeButtonPadding + _closeButtonSize;
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _headerHorizontalPadding,
        widget.showCloseButton ? 36 : 28,
        widget.showCloseButton ? _floatingTitleRightPaddingWithClose : 20,
        8,
      ),
      child: Text(
        widget.title!,
        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: _closeButtonSize,
      height: _closeButtonSize,
      child: IOS26Button.child(
        onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        style: IOS26ButtonStyle.glass,
        size: IOS26ButtonSize.large,
        child: Icon(
          CupertinoIcons.xmark,
          size: 24,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.label,
            context,
          ),
        ),
      ),
    );
  }

  static const double _closeButtonPadding = 12;
  static const double _closeButtonSize = 36;
  static const double _floatingTitleFadeDistance = 24;
  static const double _floatingTitleGradientExtra = 40;
  static const double _floatingTitleTop = 16;
  static const double _floatingTitleHorizontalPadding = 20;
  static const double _floatingTitleRightPaddingWithClose = 68;
  static const double _headerHorizontalPadding = 20;
}
