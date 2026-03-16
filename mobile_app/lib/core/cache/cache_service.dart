import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Simple key-value cache backed by sqflite.
/// Stores JSON API responses with timestamps for staleness checks.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = join(await getDatabasesPath(), 'money_manager_cache.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Store a JSON-encodable value under [key].
  Future<void> put(String key, dynamic jsonData) async {
    final db = await _database;
    await db.insert(
      'cache',
      {
        'key': key,
        'data': jsonEncode(jsonData),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve cached JSON for [key], or null if missing.
  Future<dynamic> get(String key) async {
    final db = await _database;
    final rows = await db.query('cache', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String);
  }

  /// Remove a specific cache entry.
  Future<void> remove(String key) async {
    final db = await _database;
    await db.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  /// Clear all cached data (e.g. on logout).
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('cache');
  }
}
