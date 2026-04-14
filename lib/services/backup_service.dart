import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stocksnap/services/database_service.dart';

class BackupService {
  static const _lastBackupKey = 'last_backup_date';

  static Future<String?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupKey);
  }

  static Future<void> _saveLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateFormat('MMM d, yyyy').format(DateTime.now());
    await prefs.setString(_lastBackupKey, now);
  }

  static Future<bool> backupNow(BuildContext context) async {
    try {
      final items = await DatabaseService.instance.getAllItems();
      final backup = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'items': items.map((e) => e.toMap()).toList(),
      };
      final json = jsonEncode(backup);
      final dir = await getTemporaryDirectory();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/stocksnap_backup_$date.json');
      await file.writeAsString(json);
      if (!context.mounted) return false;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 100, 100);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'StockSnap Backup',
        sharePositionOrigin: origin,
      );
      await _saveLastBackupDate();
      return true;
    } catch (e) {
      debugPrint('Backup error: $e');
      return false;
    }
  }

  static Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return false;
      final path = result.files.single.path;
      if (path == null) return false;
      final file = File(path);
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final db = await DatabaseService.instance.database;
      await db.delete('items');
      final itemsList = data['items'] as List;
      for (final e in itemsList) {
        await db.insert(
          'items',
          Map<String, dynamic>.from(e as Map)..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
