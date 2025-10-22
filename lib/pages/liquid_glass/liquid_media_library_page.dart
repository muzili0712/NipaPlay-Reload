import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:nipaplay/models/shared_remote_library.dart';
import 'package:nipaplay/pages/media_library_page.dart';
import 'package:nipaplay/providers/shared_remote_library_provider.dart';
import 'package:nipaplay/widgets/nipaplay_theme/blur_login_dialog.dart';
import 'package:nipaplay/widgets/nipaplay_theme/blur_snackbar.dart';
import 'package:nipaplay/widgets/nipaplay_theme/cached_network_image_widget.dart';
import 'package:nipaplay/widgets/nipaplay_theme/shared_remote_host_selection_sheet.dart';
import 'package:nipaplay/widgets/nipaplay_theme/themed_anime_detail.dart';

class LiquidMediaLibraryPage extends StatefulWidget {
  const LiquidMediaLibraryPage({super.key, this.onPlayEpisode});

  final OnPlayEpisodeCallback? onPlayEpisode;

  @override
  State<LiquidMediaLibraryPage> createState() => _LiquidMediaLibraryPageState();
}

class _LiquidMediaLibraryPageState extends State<LiquidMediaLibraryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _surfaceBackground;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Consumer<SharedRemoteLibraryProvider>(
          builder: (context, provider, child) {
            if (provider.isInitializing) {
              return Center(
                child: CupertinoActivityIndicator(
                  color: _primaryTextColor,
                ),
              );
            }

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () => _refreshLibrary(provider, userInitiated: true),
                ),
                ..._buildSlivers(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    SharedRemoteLibraryProvider provider,
  ) {
    final hasHosts = provider.hosts.isNotEmpty;
    final animeSummaries = provider.animeSummaries;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '媒体库',
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '连接 NipaPlay 共享客户端，远程访问家中的番剧资源',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildHostCard(context, provider),
            ],
          ),
        ),
      ),
    ];

    if (provider.errorMessage != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildErrorCard(provider),
          ),
        ),
      );
    }

    if (!hasHosts) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: _buildEmptyHostsPlaceholder(context),
          ),
        ),
      );
      return slivers;
    }

    if (provider.isLoading && animeSummaries.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
      return slivers;
    }

    if (animeSummaries.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: _buildEmptyLibraryPlaceholder(provider.activeHost),
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 190,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 7 / 11,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildAnimeCard(
              context,
              provider,
              animeSummaries[index],
            ),
            childCount: animeSummaries.length,
          ),
        ),
      ),
    );

    return slivers;
  }

  Widget _buildHostCard(
    BuildContext context,
    SharedRemoteLibraryProvider provider,
  ) {
    final host = provider.activeHost;
    final isLoading = provider.isLoading;

    if (provider.hosts.isEmpty) {
      return _buildEmptyCard(
        icon: CupertinoIcons.cloud,
        title: '尚未添加共享客户端',
        description:
            '添加并连接一台安装了 NipaPlay 客户端的设备，\n即可在任意地方访问其中的番剧。',
        primaryLabel: '添加客户端',
        onPrimaryPressed: () => _showHostDialog(context, provider),
      );
    }

    if (host == null) {
      return _buildEmptyCard(
        icon: CupertinoIcons.link,
        title: '请选择一个共享客户端',
        description: '当前有可用客户端，但尚未选择活跃连接。',
        primaryLabel: '选择客户端',
        secondaryLabel: '添加新的客户端',
        onPrimaryPressed: () => _showHostDialog(context, provider),
        onSecondaryPressed: () => _showAddHostDialog(context, provider),
      );
    }

    final reachIcon = provider.hasReachableActiveHost
        ? CupertinoIcons.cloud
        : CupertinoIcons.exclamationmark_triangle;

    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentBadgeBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reachIcon,
                  color: _accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.displayName,
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      host.baseUrl,
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFilledActionButton(
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: '切换',
                onPressed: () => _showHostDialog(context, provider),
                compact: true,
              ),
            ],
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  CupertinoActivityIndicator(color: _accentColor),
                  const SizedBox(width: 8),
                  Text(
                    '正在刷新…',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilledActionButton(
                icon: CupertinoIcons.refresh,
                label: '刷新库',
                onPressed: isLoading
                    ? null
                    : () => _refreshLibrary(provider, userInitiated: true),
              ),
              _buildOutlinedActionButton(
                icon: CupertinoIcons.add,
                label: '添加新客户端',
                onPressed: () => _showAddHostDialog(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHostsPlaceholder(BuildContext context) {
    return _buildEmptyCard(
      icon: CupertinoIcons.cloud,
      title: '没有可用的共享客户端',
      description:
          '在家里或服务器上运行 NipaPlay 后，\n点击下方按钮添加连接，即可随时访问远程媒体库。',
      primaryLabel: '添加客户端',
      onPrimaryPressed: () => _showHostDialog(
        context,
        Provider.of<SharedRemoteLibraryProvider>(context, listen: false),
      ),
      centerContent: true,
    );
  }

  Widget _buildEmptyLibraryPlaceholder(SharedRemoteHost? host) {
    final description = host == null
        ? '请选择一个共享客户端'
        : '客户端 “${host.displayName}” 尚未扫描任何番剧';
    return _buildStatusMessage(
      icon: CupertinoIcons.folder_open,
      message: description,
    );
  }

  Widget _buildErrorCard(SharedRemoteLibraryProvider provider) {
    final message = provider.errorMessage ?? '';
    return Container(
      decoration: BoxDecoration(
        color: _errorSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _errorBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, color: _errorColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _errorColor, fontSize: 13),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: provider.clearError,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: _errorColor.withOpacity(0.8),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(
    BuildContext context,
    SharedRemoteLibraryProvider provider,
    SharedRemoteAnimeSummary anime,
  ) {
    return GestureDetector(
      onTap: () => _openAnimeDetail(context, provider, anime),
      child: Container(
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorderColor),
          boxShadow: _cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 7 / 10,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImageWidget(
                  imageUrl: anime.imageUrl ?? '',
                  fit: BoxFit.cover,
                  delayLoad: false,
                  errorBuilder: (context, error) => Container(
                    color: _fallbackImageBackground,
                    child: Icon(
                      CupertinoIcons.photo,
                      color: _secondaryTextColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.nameCn?.isNotEmpty == true
                          ? anime.nameCn!
                          : anime.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          color: _secondaryTextColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatWatchTime(anime.lastWatchTime),
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String description,
    required String primaryLabel,
    VoidCallback? onPrimaryPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    bool centerContent = false,
  }) {
    final actions = <Widget>[
      _buildFilledActionButton(
        icon: CupertinoIcons.add,
        label: primaryLabel,
        onPressed: onPrimaryPressed,
      ),
    ];

    if (secondaryLabel != null) {
      actions.add(
        _buildOutlinedActionButton(
          icon: CupertinoIcons.add_circled,
          label: secondaryLabel,
          onPressed: onSecondaryPressed,
        ),
      );
    }

    final content = Column(
      crossAxisAlignment:
          centerContent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _secondaryTextColor, size: 36),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: centerContent ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: centerContent ? TextAlign.center : TextAlign.left,
          style: TextStyle(color: _secondaryTextColor, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: centerContent ? WrapAlignment.center : WrapAlignment.start,
          children: actions,
        ),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: centerContent ? Center(child: content) : content,
    );
  }

  Widget _buildStatusMessage({required IconData icon, required String message}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _secondaryTextColor, size: 40),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: _secondaryTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _showHostDialog(
    BuildContext context,
    SharedRemoteLibraryProvider provider,
  ) async {
    if (provider.hosts.isEmpty) {
      await _showAddHostDialog(context, provider);
    } else {
      await SharedRemoteHostSelectionSheet.show(context);
    }
  }

  Future<void> _showAddHostDialog(
    BuildContext context,
    SharedRemoteLibraryProvider provider,
  ) async {
    await BlurLoginDialog.show(
      context,
      title: '添加 NipaPlay 共享客户端',
      fields: const [
        LoginField(
          key: 'displayName',
          label: '备注名称',
          hint: '例如：客厅主机',
          required: false,
        ),
        LoginField(
          key: 'baseUrl',
          label: '访问地址',
          hint: '例如：http://192.168.1.66:8080',
        ),
      ],
      loginButtonText: '添加',
      onLogin: (values) async {
        final baseUrl = values['baseUrl']?.trim() ?? '';
        if (baseUrl.isEmpty) {
          return const LoginResult(success: false, message: '访问地址不能为空');
        }
        final displayName = values['displayName']?.trim().isEmpty ?? true
            ? baseUrl
            : values['displayName']!.trim();

        try {
          await provider.addHost(displayName: displayName, baseUrl: baseUrl);
          if (mounted) {
            BlurSnackBar.show(context, '已添加 $displayName');
          }
          return const LoginResult(success: true);
        } catch (e) {
          return LoginResult(success: false, message: '添加失败：$e');
        }
      },
    );
  }

  Future<void> _refreshLibrary(
    SharedRemoteLibraryProvider provider, {
    bool userInitiated = false,
  }) async {
    try {
      await provider.refreshLibrary(userInitiated: userInitiated);
    } catch (e) {
      if (mounted) {
        BlurSnackBar.show(context, '刷新失败：$e');
      }
    }
  }

  Future<void> _openAnimeDetail(
    BuildContext context,
    SharedRemoteLibraryProvider provider,
    SharedRemoteAnimeSummary anime,
  ) async {
    try {
      final result = await ThemedAnimeDetail.show(
        context,
        anime.animeId,
        sharedSummary: anime,
        sharedEpisodeLoader: () => provider.loadAnimeEpisodes(
          anime.animeId,
          force: true,
        ),
        sharedEpisodeBuilder: (episode) => provider.buildPlayableItem(
          anime: anime,
          episode: episode,
        ),
        sharedSourceLabel: provider.activeHost?.displayName,
      );

      if (result != null) {
        widget.onPlayEpisode?.call(result);
      }
    } catch (e) {
      if (!mounted) return;
      BlurSnackBar.show(context, '打开详情失败：$e');
    }
  }

  String _formatWatchTime(DateTime lastWatchTime) {
    final now = DateTime.now();
    final difference = now.difference(lastWatchTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${lastWatchTime.year}/${lastWatchTime.month.toString().padLeft(2, '0')}/${lastWatchTime.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildFilledActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool compact = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(18),
      color: _accentColor,
      onPressed: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 10 : 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CupertinoColors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accentColor.withOpacity(0.7), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isDark =>
      CupertinoTheme.of(context).brightness == Brightness.dark;

  Color get _surfaceBackground =>
      _isDark ? const Color(0xFF0F0F12) : const Color(0xFFF2F2F7);

  Color get _primaryTextColor =>
      _isDark ? CupertinoColors.white : CupertinoColors.black;

  Color get _secondaryTextColor =>
      _primaryTextColor.withOpacity(_isDark ? 0.68 : 0.6);

  Color get _cardSurface => CupertinoColors.white;

  Color get _cardBorderColor =>
      _isDark ? CupertinoColors.white.withOpacity(0.12) : CupertinoColors.black.withOpacity(0.06);

  List<BoxShadow> get _cardShadow => [
        BoxShadow(
          color: _isDark
              ? CupertinoColors.black.withOpacity(0.35)
              : CupertinoColors.black.withOpacity(0.05),
          blurRadius: 28,
          offset: const Offset(0, 22),
        ),
      ];

  Color get _accentColor =>
      _isDark ? CupertinoColors.systemBlue : CupertinoColors.activeBlue;

  Color get _accentBadgeBackground =>
      _isDark ? const Color(0xFF1E2942) : const Color(0xFFE1EDFF);

  Color get _errorColor =>
      _isDark ? CupertinoColors.systemRed : CupertinoColors.systemRed;

  Color get _errorSurface =>
      _errorColor.withOpacity(_isDark ? 0.18 : 0.12);

  Color get _errorBorder => _errorColor.withOpacity(0.2);

  Color get _fallbackImageBackground =>
      _isDark ? const Color(0xFF1E1E22) : const Color(0xFFE9E9EF);
}
