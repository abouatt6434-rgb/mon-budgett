import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _txService = TransactionService();
  final _exportService = ExportService();

  String _theme = 'system';
  bool _notifications = true;
  bool _hideBalances = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final theme = await _settings.getThemeMode();
    final notif = await _settings.getNotificationsEnabled();
    final hide = await _settings.getHideBalances();
    if (!mounted) return;
    setState(() {
      _theme = theme;
      _notifications = notif;
      _hideBalances = hide;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          _sectionTitle('Apparence'),
          RadioListTile<String>(
            title: const Text('Clair'),
            value: 'light',
            groupValue: _theme,
            onChanged: (v) => _setTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('Sombre'),
            value: 'dark',
            groupValue: _theme,
            onChanged: (v) => _setTheme(v!),
          ),
          RadioListTile<String>(
            title: const Text('Système'),
            value: 'system',
            groupValue: _theme,
            onChanged: (v) => _setTheme(v!),
          ),
          const Divider(),
          _sectionTitle('Devise'),
          const ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('FCFA (XOF)'),
            subtitle: Text('Devise par défaut de l\'application'),
          ),
          const Divider(),
          _sectionTitle('Notifications'),
          SwitchListTile(
            title: const Text('Alertes de budget'),
            subtitle: const Text('Être averti à 50%, 75%, 90% et 100% du budget'),
            value: _notifications,
            onChanged: (v) async {
              await _settings.setNotificationsEnabled(v);
              setState(() => _notifications = v);
            },
          ),
          const Divider(),
          _sectionTitle('Sécurité'),
          SwitchListTile(
            title: const Text('Masquer les montants'),
            subtitle: const Text('Cache le solde et les montants sur l\'écran d\'accueil'),
            value: _hideBalances,
            onChanged: (v) async {
              await _settings.setHideBalances(v);
              setState(() => _hideBalances = v);
            },
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Code PIN et biométrie'),
            subtitle: Text('Disponible dans une prochaine version'),
            enabled: false,
          ),
          const Divider(),
          _sectionTitle('Données'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Exporter mes données (CSV)'),
            onTap: () async {
              final txs = await _txService.getAllTransactions();
              if (txs.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucune donnée à exporter.')),
                  );
                }
                return;
              }
              await _exportService.shareCsv(txs);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            title: const Text('Supprimer toutes les données', style: TextStyle(color: AppColors.danger)),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Supprimer toutes les données ?',
                message: 'Toutes vos transactions et budgets seront définitivement supprimés. Cette action est irréversible.',
                confirmLabel: 'Tout supprimer',
              );
              if (confirmed) {
                await DatabaseService.instance.wipeAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Toutes les données ont été supprimées.')),
                  );
                }
              }
            },
          ),
          const Divider(),
          _sectionTitle('À propos'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MON BUDGET'),
            subtitle: Text('Version 1.0.0'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _setTheme(String mode) async {
    await _settings.setThemeMode(mode);
    setState(() => _theme = mode);
    widget.onThemeChanged();
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      );
}
