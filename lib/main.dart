import 'package:flutter/material.dart';
import 'package:one_ui_scroll_view/src/one_ui_scaffold.dart';

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
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
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
    return Padding(
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
    );
  }
}

class DetailPage extends StatelessWidget {
  final String title;
  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return OneUiScaffold(
      expandedTitle: Text(
        title,
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w300),
      ),
      collapsedTitle: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
      initiallyCollapsed: true,
      actionsAlignment: Alignment.topRight,
      collapsedTitleAlignment: Alignment.topLeft,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
      children: List.generate(
        20,
        (index) => _buildSettingsCard(
          Icons.settings,
          '$title Option $index',
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
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: SettingTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () {},
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
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
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
