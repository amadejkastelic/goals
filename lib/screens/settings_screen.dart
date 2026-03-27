import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/categories_provider.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          _buildThemeSection(),
          const Divider(),
          _buildSectionHeader('Notifications'),
          _buildNotificationSection(),
          const Divider(),
          _buildSectionHeader('Data'),
          _buildDataSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (modes) =>
                    themeProvider.setThemeMode(modes.first),
              ),
            ),
            SwitchListTile(
              title: const Text('Dynamic Colors'),
              subtitle: const Text(
                'Use Material You colors from your wallpaper',
              ),
              value: themeProvider.useDynamicColors,
              onChanged: (_) => themeProvider.toggleDynamicColors(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationSection() {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Daily Reminders'),
              subtitle: const Text('Get reminded twice daily'),
              value: notifProvider.notificationsEnabled,
              onChanged: notifProvider.isLoading
                  ? null
                  : (value) {
                      final goalsProvider = context.read<GoalsProvider>();
                      notifProvider.setNotificationsEnabled(
                        value,
                        activeGoals: goalsProvider.activeGoals,
                      );
                    },
            ),
            ListTile(
              title: const Text('Morning Reminder'),
              subtitle: Text(_formatHour(notifProvider.morningHour)),
              leading: const Icon(Icons.wb_sunny_outlined),
              enabled: notifProvider.notificationsEnabled,
              onTap: () =>
                  _pickTime(context, notifProvider.morningHour, (hour) async {
                    final goalsProvider = context.read<GoalsProvider>();
                    await notifProvider.setMorningHour(
                      hour,
                      activeGoals: goalsProvider.activeGoals,
                    );
                  }),
            ),
            ListTile(
              title: const Text('Evening Reminder'),
              subtitle: Text(_formatHour(notifProvider.eveningHour)),
              leading: const Icon(Icons.nightlight_outlined),
              enabled: notifProvider.notificationsEnabled,
              onTap: () =>
                  _pickTime(context, notifProvider.eveningHour, (hour) async {
                    final goalsProvider = context.read<GoalsProvider>();
                    await notifProvider.setEveningHour(
                      hour,
                      activeGoals: goalsProvider.activeGoals,
                    );
                  }),
            ),
          ],
        );
      },
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }

  Future<void> _pickTime(
    BuildContext context,
    int currentHour,
    Future<void> Function(int) onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    if (picked != null) {
      await onChanged(picked.hour);
    }
  }

  Widget _buildDataSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Export Backup'),
          subtitle: const Text('Save an encrypted copy of your database'),
          trailing: _isExporting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          enabled: !_isExporting && !_isImporting,
          onTap: _isExporting || _isImporting ? null : _startExport,
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('Import Backup'),
          subtitle: const Text('Restore from an encrypted backup file'),
          trailing: _isImporting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          enabled: !_isExporting && !_isImporting,
          onTap: _isExporting || _isImporting ? null : _startImport,
        ),
      ],
    );
  }

  encrypt.Key _deriveKey(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes.sublist(0, 32)));
  }

  Future<Uint8List> _encryptData(Uint8List data, String pin) async {
    final key = _deriveKey(pin);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  Future<Uint8List> _decryptData(Uint8List data, String pin) async {
    final key = _deriveKey(pin);
    final iv = encrypt.IV(data.sublist(0, 16));
    final encryptedBytes = data.sublist(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );
    return Uint8List.fromList(decrypted);
  }

  Future<String?> _showPinDialog({required bool isConfirm}) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isConfirm ? 'Confirm PIN' : 'Enter PIN'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'PIN',
              hintText: isConfirm
                  ? 'Re-enter your PIN'
                  : 'Enter a 4+ digit PIN',
            ),
            validator: (v) {
              if (v == null || v.length < 4) {
                return 'PIN must be at least 4 digits';
              }
              if (!RegExp(r'^\d+$').hasMatch(v)) {
                return 'PIN must contain only digits';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startExport() async {
    final pin = await _showPinDialog(isConfirm: false);
    if (pin == null) return;

    final confirmPin = await _showPinDialog(isConfirm: true);
    if (confirmPin == null) return;

    if (pin != confirmPin) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbBytes = await File(dbPath).readAsBytes();
      final encrypted = await _encryptData(dbBytes, pin);

      final dir = Directory.systemTemp;
      final now = DateTime.now();
      final timestamp =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';
      final backupPath = '${dir.path}/goals_backup_$timestamp.goals';
      await File(backupPath).writeAsBytes(encrypted);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'Goals Database Backup',
        subject: 'Goals Backup',
      );
      try {
        await File(backupPath).delete();
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
    if (mounted) setState(() => _isExporting = false);
  }

  Future<void> _startImport() async {
    final pin = await _showPinDialog(isConfirm: false);
    if (pin == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text(
          'This will replace all your current data with the backup. '
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['goals', 'db'],
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) throw Exception('Could not access file');

      final encryptedBytes = await File(filePath).readAsBytes();
      Uint8List decryptedBytes;
      try {
        decryptedBytes = await _decryptData(encryptedBytes, pin);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN or corrupted file')),
        );
        setState(() => _isImporting = false);
        return;
      }

      final dir = Directory.systemTemp;
      final tempPath = '${dir.path}/goals_restore_temp.db';
      await File(tempPath).writeAsBytes(decryptedBytes);

      final isValid = await DatabaseHelper.instance.validateBackup(tempPath);
      if (!isValid) {
        try {
          await File(tempPath).delete();
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid backup file')));
        setState(() => _isImporting = false);
        return;
      }

      await DatabaseHelper.instance.restoreFromBackup(tempPath);
      try {
        await File(tempPath).delete();
      } catch (_) {}

      if (!mounted) return;

      await Future.wait([
        context.read<GoalsProvider>().loadGoals(),
        context.read<CategoriesProvider>().loadCategories(),
      ]);

      final notifProvider = context.read<NotificationProvider>();
      if (notifProvider.notificationsEnabled) {
        await notifProvider.refreshAllNotifications(
          context.read<GoalsProvider>().goals,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
    if (mounted) setState(() => _isImporting = false);
  }
}
