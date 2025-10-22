// settings_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kmbal_ionicons/kmbal_ionicons.dart';
import 'package:nipaplay/pages/settings/theme_mode_page.dart'; // 导入 ThemeModePage
import 'package:nipaplay/pages/settings/general_page.dart';
import 'package:nipaplay/pages/settings/developer_options_page.dart'; // 导入开发者选项页面
import 'package:nipaplay/utils/theme_notifier.dart';
import 'package:nipaplay/widgets/nipaplay_theme/custom_scaffold.dart';
import 'package:nipaplay/widgets/nipaplay_theme/responsive_container.dart'; // 导入响应式容器
import 'package:nipaplay/pages/settings/about_page.dart'; // 导入 AboutPage
import 'package:nipaplay/utils/globals.dart'
    as globals; // 导入包含 isDesktop 的全局变量文件
import 'package:nipaplay/pages/shortcuts_settings_page.dart';
import 'package:nipaplay/pages/settings/account_page.dart';
import 'package:nipaplay/pages/settings/player_settings_page.dart'; // 导入播放器设置页面
import 'package:nipaplay/pages/settings/remote_media_library_page.dart'; // 导入远程媒体库设置页面
import 'package:nipaplay/pages/settings/remote_access_page.dart'; // 导入远程访问设置页面
import 'package:nipaplay/pages/settings/ui_theme_page.dart'; // 导入UI主题设置页面
import 'package:nipaplay/pages/settings/watch_history_page.dart';
import 'package:nipaplay/pages/settings/backup_restore_page.dart';
import 'package:nipaplay/pages/settings/network_settings_page.dart';
import 'package:nipaplay/providers/ui_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  // currentPage 状态现在用于桌面端的右侧面板
  // 也可以考虑给它一个初始值，这样桌面端一进来右侧不是空的
  Widget? currentPage; // 初始可以为 null
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初始化TabController
    _tabController = TabController(length: 1, vsync: this);

    // 可以在这里为桌面端和平板设备设置一个默认显示的页面
    if (globals.isDesktop || globals.isTablet) {
      currentPage = const AboutPage(); // 例如默认显示 AboutPage
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 封装导航或更新状态的逻辑
  void _handleItemTap(Widget pageToShow, String title) {
    List<Widget> settingsTabLabels() {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ];
    }

    final List<Widget> pages = [pageToShow];
    if (globals.isDesktop || globals.isTablet) {
      // 桌面端和平板设备：更新状态，改变右侧面板内容
      setState(() {
        currentPage = pageToShow;
      });
    } else {
      // 移动端：导航到新页面
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomScaffold(
                  pages: pages,
                  tabPage: settingsTabLabels(),
                  pageIsHome: false,
                  tabController: _tabController,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UIThemeProvider>(
      builder: (context, uiThemeProvider, child) {
        final themeNotifier = context.read<ThemeNotifier>();
        final entries = _buildSettingsEntries(themeNotifier);

        final Widget settingsContent = uiThemeProvider.isLiquidGlassTheme
            ? _buildLiquidGlassSettings(entries)
            : _buildStandardSettingsList(entries);

        return ResponsiveContainer(
          currentPage: currentPage ?? Container(),
          child: settingsContent,
        );
      },
    );
  }

  List<_SettingsTileData> _buildSettingsEntries(ThemeNotifier themeNotifier) {
    final entries = <_SettingsTileData>[
      _SettingsTileData(
        title: '账号',
        description: '管理登录状态与用户资料',
        icon: Ionicons.person_circle_outline,
        onTap: () => _handleItemTap(const AccountPage(), '账号设置'),
      ),
      _SettingsTileData(
        title: '外观',
        description: '切换明暗模式与界面风格',
        icon: Ionicons.color_palette_outline,
        onTap: () => _handleItemTap(
          ThemeModePage(themeNotifier: themeNotifier),
          '外观设置',
        ),
      ),
      _SettingsTileData(
        title: '主题',
        description: '选择界面主题样式',
        icon: Ionicons.sparkles_outline,
        onTap: () => _handleItemTap(const UIThemePage(), '主题设置'),
      ),
      _SettingsTileData(
        title: '通用',
        description: '播放、字幕及常规首选项',
        icon: Ionicons.options_outline,
        onTap: () => _handleItemTap(const GeneralPage(), '通用设置'),
      ),
      _SettingsTileData(
        title: '网络',
        description: '代理、缓存与连通性设置',
        icon: Ionicons.globe_outline,
        onTap: () => _handleItemTap(const NetworkSettingsPage(), '网络设置'),
      ),
      _SettingsTileData(
        title: '观看记录',
        description: '查看与管理本地观看历史',
        icon: Ionicons.time_outline,
        onTap: () => _handleItemTap(const WatchHistoryPage(), '观看记录'),
      ),
    ];

    if (!globals.isPhone) {
      entries.add(
        _SettingsTileData(
          title: '备份与恢复',
          description: '导出或恢复应用配置',
          icon: Ionicons.archive_outline,
          onTap: () => _handleItemTap(const BackupRestorePage(), '备份与恢复'),
        ),
      );
    }

    entries.add(
      _SettingsTileData(
        title: '播放器',
        description: '渲染、解码与播放体验',
        icon: Ionicons.play_circle_outline,
        onTap: () => _handleItemTap(const PlayerSettingsPage(), '播放器设置'),
      ),
    );

    if (!globals.isPhone) {
      entries.addAll([
        _SettingsTileData(
          title: '快捷键',
          description: '自定义快速操作与控制',
          icon: Icons.keyboard_outlined,
          onTap: () => _handleItemTap(
            const ShortcutsSettingsPage(),
            '快捷键设置',
          ),
        ),
        _SettingsTileData(
          title: '远程访问（实验）',
          description: '配置远程访问服务',
          icon: Ionicons.cloud_outline,
          onTap: () => _handleItemTap(const RemoteAccessPage(), '远程访问'),
        ),
      ]);
    }

    entries.addAll([
      _SettingsTileData(
        title: '远程媒体库',
        description: '连接云端番剧库与同步',
        icon: Icons.tv_outlined,
        onTap: () => _handleItemTap(
          const RemoteMediaLibraryPage(),
          '远程媒体库',
        ),
      ),
      _SettingsTileData(
        title: '开发者选项',
        description: '调试工具与高级功能',
        icon: Ionicons.code_outline,
        onTap: () => _handleItemTap(
          const DeveloperOptionsPage(),
          '开发者选项',
        ),
      ),
      _SettingsTileData(
        title: '关于',
        description: '版本信息与鸣谢',
        icon: Ionicons.information_circle_outline,
        onTap: () => _handleItemTap(const AboutPage(), '关于'),
      ),
    ]);

    return entries;
  }

  Widget _buildStandardSettingsList(List<_SettingsTileData> entries) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          leading: Icon(
            entry.icon,
            color: Colors.white.withOpacity(0.8),
          ),
          title: Text(
            entry.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: entry.description != null
              ? Text(
                  entry.description!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: const Icon(
            Ionicons.chevron_forward_outline,
            color: Colors.white,
          ),
          onTap: entry.onTap,
        );
      },
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.white.withOpacity(0.08),
      ),
      itemCount: entries.length,
    );
  }

  Widget _buildLiquidGlassSettings(List<_SettingsTileData> entries) {
    final size = MediaQuery.of(context).size;
    final bool isWide = globals.isDesktop || globals.isTablet;
    final double cardWidth = isWide ? 230 : math.max(size.width - 48, 240);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '调节播放体验与账户安全',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: entries
                .map((entry) => _buildSettingsCard(entry, cardWidth))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(_SettingsTileData entry, double width) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: entry.onTap,
        child: _buildSettingsGlassCard(entry),
      ),
    );
  }

  Widget _buildSettingsGlassCard(_SettingsTileData entry) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(
          borderRadius: const Radius.circular(26),
        ),
        settings: LiquidGlassSettings(
          glassColor: Colors.white.withOpacity(0.08),
          blur: 18,
          thickness: 18,
          saturation: 1.22,
          lightAngle: math.pi / 3,
          ambientStrength: 0.35,
          lightIntensity: 1.25,
          blend: 14,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SizedBox(
            height: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(entry.icon, color: Colors.white, size: 28),
                const SizedBox(height: 18),
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 13,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '打开',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Ionicons.arrow_forward_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTileData {
  const _SettingsTileData({
    required this.title,
    required this.icon,
    required this.onTap,
    this.description,
  });

  final String title;
  final IconData icon;
  final String? description;
  final VoidCallback onTap;
}
