import 'package:flutter/material.dart';
import 'package:one_ui_scroll_view/src/one_ui_scaffold.dart';
import 'package:one_ui_scroll_view/src/one_ui_scroll_view.dart';

void main() {
  runApp(
    MaterialApp(
      home: OneUiExample(),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    ),
  );
}

class OneUiExample extends StatelessWidget {
  const OneUiExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OneUiScaffold(
      appBar: OneUiAppBar(
        expandedTitle: const Text(
          'Settings',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300),
        ),
        collapsedTitle: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      slivers: [
        _buildSettingsCard(
          context,
          Icons.wifi,
          'Connections',
          'Wi-Fi, Bluetooth, Data usage',
          top: 0,
        ),
        _buildSettingsCard(
          context,
          Icons.volume_up,
          'Sounds and vibration',
          'Sound mode, Ringtone',
        ),
        _buildSettingsCard(
          context,
          Icons.notifications,
          'Notifications',
          'Status bar, Do not disturb',
        ),
        _buildSettingsCard(
          context,
          Icons.display_settings,
          'Display',
          'Brightness, Blue light filter',
        ),
        _buildSettingsCard(
          context,
          Icons.wallpaper,
          'Wallpaper',
          'Home screen wallpaper',
        ),
        _buildSettingsCard(
          context,
          Icons.lock,
          'Lock screen',
          'Screen lock type, Clock style',
        ),
        _buildSettingsCard(
          context,
          Icons.security,
          'Security and privacy',
          'Biometrics, Permissions',
        ),
        _buildSettingsCard(
          context,
          Icons.account_circle,
          'Accounts and backup',
          'Manage accounts, Google Drive',
        ),
        _buildSettingsCard(
          context,
          Icons.settings,
          'Advanced features',
          'Lab, Side key, Multi window',
        ),
        _buildSettingsCard(
          context,
          Icons.health_and_safety,
          'Safety and emergency',
          'Medical info, SOS',
        ),
        _buildSettingsCard(
          context,
          Icons.brush,
          'Themes',
          'Wallpapers, Icons, Always On Display',
        ),
        _buildSettingsCard(
          context,
          Icons.font_download,
          'Accessibility',
          'TalkBack, Visibility enhancements',
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    double top = 12,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: SettingTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailPage(title: title)),
          ),
        ),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final String title;
  const DetailPage({super.key, required this.title});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return OneUiScaffold(
      appBar: OneUiAppBar(
        expandedTitle: Text(
          widget.title,
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300),
        ),
        collapsedTitle: Text(
          widget.title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
        bottom: BottomSwitch(
          enabled: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
        ),
        initiallyCollapsed: true,
        actionsAlignment: Alignment.topRight,
        collapsedTitleAlignment: Alignment.topLeft,
        stretch: true,
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      slivers: List.generate(
        20,
        (index) => _buildSettingsCard(
          Icons.settings,
          '${widget.title} Option $index',
          'Description for option $index',
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    IconData icon,
    String title,
    String subtitle, {
    double top = 12,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: SettingTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: () {},
          enabled: _enabled,
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: .5),
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        enabled: enabled,
      ),
    );
  }
}

class BottomSwitch extends StatelessWidget implements PreferredSizeWidget {
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const BottomSwitch({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Size get preferredSize => Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: ShapeDecoration(
          shape: StadiumBorder(),
          color: theme.colorScheme.secondaryContainer.withValues(alpha: .4),
        ),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            Text(
              'Enabled',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Spacer(),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
