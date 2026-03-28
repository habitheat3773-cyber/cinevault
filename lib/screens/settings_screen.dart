import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../providers/stream_providers.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = StorageService.isAdmin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.bgPrimary,
      ),
      body: ListView(
        children: [
          // ─ Content Providers ──────────────────────────────
          _SectionTitle('Content Providers'),
          _buildProvidersList(),
          
          // ─ Playback ───────────────────────────────────────
          _SectionTitle('Playback'),
          _buildQualitySelector(),
          _buildAutoPlayToggle(),
          
          // ─ Subtitles ──────────────────────────────────────
          _SectionTitle('Subtitles'),
          _buildSubtitleSize(),
          
          // ─ Data Management ────────────────────────────────
          _SectionTitle('Data Management'),
          _buildDataManagement(),
          
          // ─ Admin Panel ────────────────────────────────────
          _SectionTitle('Admin'),
          _buildAdminSection(),
          
          // ─ About ──────────────────────────────────────────
          _SectionTitle('About'),
          _buildAbout(),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
    final providers = ProviderRegistry.all;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: providers.asMap().entries.map((entry) {
          final i = entry.key;
          final provider = entry.value;
          final isEnabled = StorageService.isProviderEnabled(provider.name);
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.accent.withOpacity(0.15)
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.movie_outlined,
                    color: isEnabled ? AppTheme.accent : AppTheme.textMuted,
                    size: 18,
                  ),
                ),
                title: Text(provider.name,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: AppTheme.textPrimary,
                        fontSize: 14)),
                subtitle: Text(
                  provider.supportsMovies && provider.supportsShows
                      ? 'Movies + TV Shows'
                      : provider.supportsMovies
                          ? 'Movies only'
                          : 'TV Shows only',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: AppTheme.textMuted,
                      fontSize: 12),
                ),
                trailing: Switch(
                  value: isEnabled,
                  activeColor: AppTheme.accent,
                  onChanged: (v) async {
                    final disabled = StorageService.disabledProviders;
                    if (!v) {
                      disabled.add(provider.name);
                    } else {
                      disabled.remove(provider.name);
                    }
                    await StorageService.setDisabledProviders(disabled);
                    setState(() {});
                  },
                ),
              ),
              if (i < providers.length - 1)
                const Divider(height: 1, color: AppTheme.divider, indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQualitySelector() {
    final qualities = ['Auto', '1080p', '720p', '480p'];
    final current = StorageService.defaultQuality;
    return _SettingsTile(
      icon: Icons.hd_outlined,
      title: 'Default Quality',
      subtitle: current,
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgCard,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Quality',
                  style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 20,
                      letterSpacing: 1.5,
                      color: AppTheme.textPrimary)),
            ),
            ...qualities.map((q) => ListTile(
              title: Text(q, style: const TextStyle(
                  fontFamily: 'DMSans', color: AppTheme.textPrimary)),
              trailing: q == current
                  ? const Icon(Icons.check, color: AppTheme.accent)
                  : null,
              onTap: () async {
                await StorageService.setDefaultQuality(q);
                Navigator.pop(context);
                setState(() {});
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoPlayToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: const Icon(Icons.skip_next_outlined, color: AppTheme.accent),
        title: const Text('Auto-play Next Episode',
            style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textPrimary)),
        subtitle: const Text('Automatically play next episode',
            style: TextStyle(
                fontFamily: 'DMSans',
                color: AppTheme.textMuted,
                fontSize: 12)),
        value: StorageService.autoPlayNext,
        activeColor: AppTheme.accent,
        onChanged: (v) async {
          await StorageService.setAutoPlayNext(v);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSubtitleSize() {
    final sizes = ['small', 'medium', 'large', 'xlarge'];
    return _SettingsTile(
      icon: Icons.subtitles_outlined,
      title: 'Subtitle Size',
      subtitle: StorageService.subtitleSize,
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgCard,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes.map((s) => ListTile(
            title: Text(s.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            trailing: s == StorageService.subtitleSize
                ? const Icon(Icons.check, color: AppTheme.accent)
                : null,
            onTap: () async {
              await StorageService.setSubtitleSize(s);
              Navigator.pop(context);
              setState(() {});
            },
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildDataManagement() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: AppTheme.error),
            title: const Text('Clear Cache',
                style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () async {
              await StorageService.clearCache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared'),
                    backgroundColor: AppTheme.bgCard,
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, color: AppTheme.divider, indent: 56),
          ListTile(
            leading: const Icon(Icons.history_toggle_off, color: AppTheme.error),
            title: const Text('Clear Watch History',
                style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.bgCard,
                  title: const Text('Clear History?',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  content: const Text('This cannot be undone.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear', style: TextStyle(color: AppTheme.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await StorageService.clearHistory();
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    if (!_isAdmin) {
      return _SettingsTile(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin Panel',
        subtitle: 'Tap to unlock',
        onTap: () => _showAdminPinDialog(),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: AppTheme.accent),
            title: const Text('Featured Content Manager',
                style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () {},
          ),
          const Divider(height: 1, color: AppTheme.divider, indent: 56),
          ListTile(
            leading: const Icon(Icons.block, color: AppTheme.accent),
            title: const Text('Blacklist Content',
                style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () {},
          ),
          const Divider(height: 1, color: AppTheme.divider, indent: 56),
          ListTile(
            leading: const Icon(Icons.monitor_heart_outlined, color: AppTheme.accent),
            title: const Text('Provider Health Monitor',
                style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProviderHealthScreen())),
          ),
          const Divider(height: 1, color: AppTheme.divider, indent: 56),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppTheme.error),
            title: const Text('Lock Admin',
                style: TextStyle(fontFamily: 'DMSans', color: AppTheme.error)),
            onTap: () async {
              await StorageService.lockAdmin();
              setState(() => _isAdmin = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.movie_filter, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CineVault',
                      style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 22,
                          letterSpacing: 2,
                          color: AppTheme.textPrimary)),
                  Text('Every Movie. One Vault.',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'CineVault is a free movie aggregator. We do not host any content. '
            'All streams are sourced from publicly available providers on the internet.',
            style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Version 1.0.0',
            style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  void _showAdminPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Admin Access',
            style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 22,
                letterSpacing: 1.5,
                color: AppTheme.textPrimary)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: '• • • •',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await StorageService.unlockAdmin(pinController.text);
              Navigator.pop(context);
              if (ok) {
                setState(() => _isAdmin = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin mode unlocked ✓')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

// ─── Provider Health Monitor ─────────────────────────────────────────────────
class ProviderHealthScreen extends StatefulWidget {
  const ProviderHealthScreen({super.key});

  @override
  State<ProviderHealthScreen> createState() => _ProviderHealthScreenState();
}

class _ProviderHealthScreenState extends State<ProviderHealthScreen> {
  final Map<String, bool?> _healthStatus = {};
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() => _checking = true);
    for (final p in ProviderRegistry.all) {
      final ok = await p.checkHealth();
      if (mounted) setState(() => _healthStatus[p.name] = ok);
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Provider Health'),
        backgroundColor: AppTheme.bgPrimary,
        actions: [
          if (_checking)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkAll,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: ProviderRegistry.all.map((p) {
          final status = _healthStatus[p.name];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == null
                        ? AppTheme.textMuted
                        : status
                            ? AppTheme.success
                            : AppTheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(p.baseUrl,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Text(
                  status == null
                      ? 'Checking...'
                      : status
                          ? 'Online'
                          : 'Offline',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status == null
                        ? AppTheme.textMuted
                        : status
                            ? AppTheme.success
                            : AppTheme.error,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'DMSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppTheme.textMuted,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppTheme.accent),
      title: Text(title, style: const TextStyle(
          fontFamily: 'DMSans', color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(
          fontFamily: 'DMSans', color: AppTheme.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppTheme.textMuted),
      onTap: onTap,
    ),
  );
}
