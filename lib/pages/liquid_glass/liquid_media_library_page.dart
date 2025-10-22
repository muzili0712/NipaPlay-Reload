import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:nipaplay/models/shared_remote_library.dart';
import 'package:nipaplay/pages/media_library_page.dart';
import 'package:nipaplay/providers/shared_remote_library_provider.dart';
import 'package:nipaplay/widgets/liquid_glass_theme/liquid_section_card.dart';
import 'package:nipaplay/widgets/nipaplay_theme/blur_login_dialog.dart';
import 'package:nipaplay/widgets/nipaplay_theme/blur_snackbar.dart';
import 'package:nipaplay/widgets/nipaplay_theme/cached_network_image_widget.dart';
import 'package:nipaplay/widgets/nipaplay_theme/shared_remote_host_selection_sheet.dart';
import 'package:nipaplay/widgets/nipaplay_theme/themed_anime_detail.dart';
import 'package:nipaplay/widgets/liquid_glass_theme/liquid_page_header.dart';

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
    return CupertinoPageScaffold(
      backgroundColor: _surfaceBackground,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Consumer<SharedRemoteLibraryProvider>(
          builder: (context, provider, child) {
            if (provider.isInitializing) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () =>
                      _refreshLibrary(provider, userInitiated: true),
                ),
                ..._buildSlivers(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(SharedRemoteLibraryProvider provider) {
    final hasHosts = provider.hosts.isNotEmpty;
    final animeSummaries = provider.animeSummaries;
    final bool isPhone = MediaQuery.of(context).size.shortestSide < 600;

    final EdgeInsets pagePadding = EdgeInsets.fromLTRB(
      isPhone ? 8 : 20,
      isPhone ? 12 : 32,
      isPhone ? 8 : 20,
      isPhone ? 24 : 48,
    );

    final double sectionSpacing = isPhone ? 20 : 28;
    final double footerSpacing = isPhone ? 80 : 120;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            pagePadding.left,
            pagePadding.top,
            pagePadding.right,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiquidPageHeader(
                title: '媒体库',
                subtitle: '连接 NipaPlay 共享客户端，远程访问家中的番剧资源',
                padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 12),
                titleFontSize: isPhone ? 30 : 40,
                subtitleFontSize: isPhone ? 14 : 16,
                titleLetterSpacing: 0.6,
                subtitleSpacing: 8,
              ),
              SizedBox(height: sectionSpacing),
              _buildHostSection(provider),
            ],
          ),
        ),
      ),
    ];

    if (provider.errorMessage != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              sectionSpacing,
              pagePadding.right,
              0,
            ),
            child: buildLiquidSectionCard(
              context: context,
              brightnessOverride: _brightness,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: _buildErrorChip(provider),
            ),
          ),
        ),
      );
    }

    if (provider.isLoading && animeSummaries.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pagePadding.left,
              sectionSpacing,
              pagePadding.right,
              pagePadding.bottom,
            ),
            child: const Center(child: CupertinoActivityIndicator()),
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(child: SizedBox(height: footerSpacing)),
      );
      return slivers;
    }

    if (animeSummaries.isEmpty) {
      final bool hasActiveHost = provider.activeHost != null;
      if (hasActiveHost) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pagePadding.left,
                sectionSpacing,
                pagePadding.right,
                pagePadding.bottom,
              ),
              child: _buildHostListRow(
                icon: CupertinoIcons.info,
                iconColor: _secondaryTextColor,
                text: '该共享客户端暂无已同步番剧',
                textColor: _secondaryTextColor,
                onTap: null,
              ),
            ),
          ),
        );
      }
      slivers.add(
        SliverToBoxAdapter(child: SizedBox(height: footerSpacing)),
      );
      return slivers;
    }

    slivers.add(
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          pagePadding.left,
          sectionSpacing,
          pagePadding.right,
          pagePadding.bottom,
        ),
        sliver: SliverToBoxAdapter(
          child: buildLiquidSectionCard(
            context: context,
            brightnessOverride: _brightness,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: _buildLibraryGrid(provider, animeSummaries),
          ),
        ),
      ),
    );

    slivers.add(
      SliverToBoxAdapter(child: SizedBox(height: footerSpacing)),
    );

    return slivers;
  }

  Widget _buildHostSection(SharedRemoteLibraryProvider provider) {
    final hosts = provider.hosts;
    final bool hasHosts = hosts.isNotEmpty;
    final String? activeHostId = provider.activeHostId;

    final rows = <Widget>[];

    if (hasHosts) {
      for (final host in hosts) {
        final bool isActive = host.id == activeHostId;
        final bool isOnline = host.isOnline;
        final icon =
            isOnline ? CupertinoIcons.cloud_fill : CupertinoIcons.cloud;
        final iconColor = isOnline ? _accentColor : _secondaryTextColor;

        final statusParts = <String>[];
        statusParts.add(isOnline ? '在线' : '离线');
        if (isActive) {
          statusParts.add('当前使用');
        }

        final label = statusParts.isEmpty
            ? host.displayName
            : '${host.displayName} · ${statusParts.join(' · ')}';

        rows.add(
          _buildHostListRow(
            icon: icon,
            iconColor: iconColor,
            text: label,
            highlight: isActive,
            textColor: isOnline ? _primaryTextColor : _secondaryTextColor,
            onTap: isActive
                ? null
                : () {
                    provider.setActiveHost(host.id);
                  },
          ),
        );
      }
    }

    rows.add(
      _buildHostListRow(
        icon: CupertinoIcons.add,
        iconColor: _accentColor,
        text: '添加共享客户端',
        onTap: () => _showAddHostDialog(provider),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) const SizedBox(height: 14),
        ]
      ],
    );
  }

  Widget _buildErrorChip(SharedRemoteLibraryProvider provider) {
    return Row(
      children: [
        Icon(CupertinoIcons.exclamationmark_triangle,
            color: _errorColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            provider.errorMessage ?? '',
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
    );
  }

  Widget _buildLibraryGrid(
    SharedRemoteLibraryProvider provider,
    List<SharedRemoteAnimeSummary> animeSummaries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '已同步番剧',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${animeSummaries.length} 部',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 18.0;
            const minTileWidth = 156.0;
            int crossAxisCount =
                (constraints.maxWidth / (minTileWidth + spacing)).floor();
            crossAxisCount = crossAxisCount.clamp(1, 5);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: animeSummaries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 7 / 11,
              ),
              itemBuilder: (context, index) => _buildAnimeTile(
                provider,
                animeSummaries[index],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimeTile(
    SharedRemoteLibraryProvider provider,
    SharedRemoteAnimeSummary anime,
  ) {
    final tileBackground =
        _isDark ? const Color(0xFF1C1C1F) : const Color(0xFFF9F9FC);
    final borderColor = _isDark
        ? CupertinoColors.white.withOpacity(0.12)
        : CupertinoColors.black.withOpacity(0.08);

    return GestureDetector(
      onTap: () => _openAnimeDetail(context, provider, anime),
      child: Container(
        decoration: BoxDecoration(
          color: tileBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 7 / 10,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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

  Widget _buildHostListRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    final resolvedIconColor =
        iconColor ?? (highlight ? _accentColor : _secondaryTextColor);
    final resolvedTextColor =
        textColor ?? (highlight ? _accentColor : _primaryTextColor);

    final row = buildLiquidSectionCard(
      context: context,
      brightnessOverride: _brightness,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: 18,
      child: Row(
        children: [
          Icon(
            icon,
            color: resolvedIconColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: resolvedTextColor,
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }

  Widget _buildStatusMessage(
      {required IconData icon, required String message}) {
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

  Future<void> _showHostDialog(SharedRemoteLibraryProvider provider) async {
    if (provider.hosts.isEmpty) {
      await _showAddHostDialog(provider);
    } else {
      await SharedRemoteHostSelectionSheet.show(context);
    }
  }

  Future<void> _showAddHostDialog(SharedRemoteLibraryProvider provider) async {
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

  Brightness? get _brightness => CupertinoTheme.of(context).brightness;

  bool get _isDark => _brightness == Brightness.dark;

  Color get _surfaceBackground =>
      _isDark ? const Color(0xFF0F0F12) : const Color(0xFFF2F2F7);

  Color get _primaryTextColor =>
      _isDark ? CupertinoColors.white : CupertinoColors.black;

  Color get _secondaryTextColor =>
      _primaryTextColor.withOpacity(_isDark ? 0.68 : 0.6);

  Color get _accentColor =>
      _isDark ? CupertinoColors.systemBlue : CupertinoColors.activeBlue;

  Color get _accentBadgeBackground =>
      _isDark ? const Color(0xFF1E2942) : const Color(0xFFE1EDFF);

  Color get _errorColor => CupertinoColors.systemRed;

  Color get _fallbackImageBackground =>
      _isDark ? const Color(0xFF1E1E22) : const Color(0xFFE9E9EF);
}
