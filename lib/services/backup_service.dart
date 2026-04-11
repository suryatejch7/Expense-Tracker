import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import 'supabase_service.dart';

/// Full JSON backup & restore of all app data.
///
/// - **Backup**: serialises every `ls_*` key from SharedPreferences into a
///   single JSON file and opens the platform share sheet so the user can save
///   it anywhere (Drive, Files, email …).
/// - **Restore**: reads a previously exported JSON file, writes the values back
///   into SharedPreferences, and reloads the providers.
/// - **Auto-file backup**: after every write the service can persist a shadow
///   copy in the app's documents directory. This file is included in Android
///   Auto Backup so it survives reinstalls even without a manual export.
class BackupService {
  // -------------------- constants --------------------
  static const String _autoBackupFileName = 'expense_tracker_auto_backup.json';
  static const String _lsPrefix = 'ls_';

  // -------------------- AUTO FILE BACKUP --------------------

  /// Writes a snapshot of all `ls_*` keys to the internal documents directory.
  /// Called automatically after every data-mutating operation.
  static Future<void> autoSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backup = <String, dynamic>{};

      for (final key in prefs.getKeys()) {
        if (key.startsWith(_lsPrefix)) {
          backup[key] = prefs.get(key);
        }
      }

      backup['_backup_timestamp'] = DateTime.now().toIso8601String();
      backup['_backup_version'] = 1;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_autoBackupFileName');
      await file.writeAsString(jsonEncode(backup));
    } catch (_) {
      // Fail silently – auto-backup is a best-effort safety net.
    }
  }

  /// On startup, if SharedPreferences has no `ls_` data but an auto-backup
  /// file exists, restore from it. Returns `true` if a restore happened.
  static Future<bool> restoreFromAutoBackupIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getKeys().any((k) => k.startsWith(_lsPrefix));
      if (hasData) return false;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_autoBackupFileName');
      if (!await file.exists()) return false;

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await _writeMapToPrefs(prefs, json);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------- MANUAL BACKUP --------------------

  /// Creates a timestamped JSON backup and opens the share sheet.
  static Future<void> createAndShareBackup(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backup = <String, dynamic>{};

      for (final key in prefs.getKeys()) {
        if (key.startsWith(_lsPrefix)) {
          backup[key] = prefs.get(key);
        }
      }

      backup['_backup_timestamp'] = DateTime.now().toIso8601String();
      backup['_backup_version'] = 1;

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/expense_tracker_backup_$ts.json');
      await file.writeAsString(jsonEncode(backup));

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Vyaya Backup',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // -------------------- MANUAL RESTORE --------------------

  /// Restores from a JSON backup file at [filePath].
  /// Clears existing data first, writes backup data, then reloads providers.
  static Future<bool> restoreFromFile(
    BuildContext context,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError(context, 'Backup file not found.');
        return false;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        _showError(context, 'Invalid backup file format.');
        return false;
      }

      // Validate it looks like our backup
      final hasLsKeys = json.keys.any((k) => k.startsWith(_lsPrefix));
      if (!hasLsKeys) {
        _showError(context, 'This file does not contain valid app data.');
        return false;
      }

      // Clear and restore
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _writeMapToPrefs(prefs, json);

      // Re-initialise storage service
      await ExpenseSupabaseService.initialize();

      // Reload providers
      if (context.mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

        // Clear in-memory state
        expenseProvider.clearUserData();
        await userProvider.clearUser();

        // Trigger re-login flow by going back to auth screen
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully! Please log in again.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Restore failed: $e');
      }
      return false;
    }
  }

  // -------------------- helpers --------------------

  static Future<void> _writeMapToPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> data,
  ) async {
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      // Skip metadata keys
      if (key.startsWith('_')) continue;

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.cast<String>());
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
