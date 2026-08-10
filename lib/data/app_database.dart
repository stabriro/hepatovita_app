import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../services/security/security_crypto_service.dart';

class AppSnapshot {
  final int waterAmount;
  final int greenTeaCount;
  final bool chkVitD;
  final bool walk30;
  final bool sun15;
  final bool lowFatDay;
  final Map<String, dynamic>? analyzedResult;
  final List<Map<String, dynamic>> labs;
  final DateTime? updatedAt;

  AppSnapshot({
    required this.waterAmount,
    required this.greenTeaCount,
    required this.chkVitD,
    required this.walk30,
    required this.sun15,
    required this.lowFatDay,
    required this.analyzedResult,
    required this.labs,
    this.updatedAt,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'id': 1,
      'water_amount': waterAmount,
      'green_tea_count': greenTeaCount,
      'chk_vit_d': chkVitD ? 1 : 0,
      'walk_30': walk30 ? 1 : 0,
      'sun_15': sun15 ? 1 : 0,
      'low_fat_day': lowFatDay ? 1 : 0,
      'analyzed_result': analyzedResult == null ? null : jsonEncode(analyzedResult),
      'labs_json': jsonEncode(labs),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static AppSnapshot fromDbMap(Map<String, dynamic> map) {
    final rawAnalyzed = map['analyzed_result'] as String?;
    final rawLabs = map['labs_json'] as String?;
    final decodedLabs = rawLabs == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(rawLabs) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    return AppSnapshot(
      waterAmount: (map['water_amount'] as num?)?.toInt() ?? 0,
      greenTeaCount: (map['green_tea_count'] as num?)?.toInt() ?? 0,
      chkVitD: (map['chk_vit_d'] as num? ?? 0) == 1,
      walk30: (map['walk_30'] as num? ?? 0) == 1,
      sun15: (map['sun_15'] as num? ?? 0) == 1,
      lowFatDay: (map['low_fat_day'] as num? ?? 0) == 1,
      analyzedResult: rawAnalyzed == null ? null : jsonDecode(rawAnalyzed) as Map<String, dynamic>,
      labs: decodedLabs,
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()),
    );
  }
}

class LabHistoryEntry {
  final int? id;
  final String metric;
  final double value;
  final String unit;
  final String status;
  final String date;
  final String createdAt;

  LabHistoryEntry({
    this.id,
    required this.metric,
    required this.value,
    required this.unit,
    required this.status,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'metric': metric,
      'value': value,
      'unit': unit,
      'status': status,
      'date': date,
      'created_at': createdAt,
    };
  }

  static LabHistoryEntry fromDbMap(Map<String, dynamic> map) {
    return LabHistoryEntry(
      id: (map['id'] as num?)?.toInt(),
      metric: map['metric'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      status: map['status'] as String,
      date: map['date'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _dbName = 'hepatovita.db';
  static const _dbVersion = 3;
  static const _stateTable = 'app_state';
  static const _labHistoryTable = 'lab_history';

  Database? _db;
  final SecurityCryptoService _crypto = SecurityCryptoService.instance;

  Future<String> get databasePath async {
    final dbDir = await getDatabasesPath();
    return join(dbDir, _dbName);
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await databasePath;

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_stateTable (
            id INTEGER PRIMARY KEY,
            water_amount INTEGER NOT NULL,
            green_tea_count INTEGER NOT NULL,
            chk_vit_d INTEGER NOT NULL,
            walk_30 INTEGER NOT NULL,
            sun_15 INTEGER NOT NULL,
            low_fat_day INTEGER NOT NULL,
            analyzed_result TEXT,
            labs_json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_labHistoryTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            metric TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT NOT NULL,
            status TEXT NOT NULL,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $_stateTable ADD COLUMN labs_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE $_labHistoryTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              metric TEXT NOT NULL,
              value REAL NOT NULL,
              unit TEXT NOT NULL,
              status TEXT NOT NULL,
              date TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<String> exportDatabaseTo(String destinationPath) async {
    final sourcePath = await databasePath;
    final resolvedDestination = destinationPath.toLowerCase().endsWith('.hvbk')
        ? destinationPath
      : '$destinationPath.hvbk';

    await close();

    final source = File(sourcePath);
    if (!await source.exists()) {
      await database;
      throw Exception('Database file not found.');
    }

    final rawBytes = await source.readAsBytes();
    final encryptedBytes = await _crypto.encryptBytes(
      Uint8List.fromList(rawBytes),
    );
    await File(resolvedDestination).writeAsBytes(
      encryptedBytes,
      flush: true,
    );

    await database;
    return resolvedDestination;
  }

  Future<void> importDatabaseFrom(String backupFilePath) async {
    final backup = File(backupFilePath);
    if (!await backup.exists()) {
      throw Exception('Selected backup file does not exist.');
    }

    final targetPath = await databasePath;
    final target = File(targetPath);

    await close();

    if (await target.exists()) {
      await target.delete();
    }

    final backupBytes = Uint8List.fromList(await backup.readAsBytes());
    Uint8List rawDatabaseBytes;
    try {
      rawDatabaseBytes = await _crypto.decryptBytes(backupBytes);
    } on FormatException {
      // Backward compatibility with older plain .db backups.
      rawDatabaseBytes = backupBytes;
    }

    await target.writeAsBytes(rawDatabaseBytes, flush: true);
    await database;
  }

  Future<void> saveState(AppSnapshot snapshot) async {
    final db = await database;
    final map = snapshot.toDbMap();
    map['analyzed_result'] =
        await _encryptNullableText(map['analyzed_result'] as String?);
    map['labs_json'] = await _crypto.encryptText(map['labs_json'] as String);

    await db.insert(
      _stateTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppSnapshot?> loadState() async {
    final db = await database;
    final rows = await db.query(
      _stateTable,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = Map<String, dynamic>.from(rows.first);
    row['analyzed_result'] =
        await _decryptNullableText(row['analyzed_result'] as String?);
    row['labs_json'] = await _decryptTextSafely(row['labs_json'] as String);

    return AppSnapshot.fromDbMap(row);
  }

  Future<void> addLabHistoryEntry(LabHistoryEntry entry) async {
    final db = await database;
    final map = entry.toDbMap();
    map['metric'] = await _crypto.encryptText(map['metric'] as String);
    map['unit'] = await _crypto.encryptText(map['unit'] as String);
    map['status'] = await _crypto.encryptText(map['status'] as String);
    map['date'] = await _crypto.encryptText(map['date'] as String);
    map['created_at'] = await _crypto.encryptText(map['created_at'] as String);
    await db.insert(_labHistoryTable, map);
  }

  Future<Map<String, List<LabHistoryEntry>>> getAllLabHistoryGrouped() async {
    final db = await database;
    final rows = await db.query(
      _labHistoryTable,
      orderBy: 'metric ASC, date ASC, id ASC',
    );

    final grouped = <String, List<LabHistoryEntry>>{};
    for (final row in rows) {
      final decrypted = Map<String, dynamic>.from(row);
      decrypted['metric'] = await _decryptTextSafely(row['metric'] as String);
      decrypted['unit'] = await _decryptTextSafely(row['unit'] as String);
      decrypted['status'] = await _decryptTextSafely(row['status'] as String);
      decrypted['date'] = await _decryptTextSafely(row['date'] as String);
      decrypted['created_at'] =
          await _decryptTextSafely(row['created_at'] as String);

      final entry = LabHistoryEntry.fromDbMap(decrypted);
      grouped.putIfAbsent(entry.metric, () => <LabHistoryEntry>[]).add(entry);
    }
    return grouped;
  }

  Future<void> deleteLabHistoryByMetric(String metric) async {
    final db = await database;
    final rows = await db.query(
      _labHistoryTable,
      columns: ['id', 'metric'],
    );

    final idsToDelete = <int>[];
    for (final row in rows) {
      final decryptedMetric = await _decryptTextSafely(row['metric'] as String);
      if (decryptedMetric == metric) {
        final id = (row['id'] as num?)?.toInt();
        if (id != null) {
          idsToDelete.add(id);
        }
      }
    }

    for (final id in idsToDelete) {
      await db.delete(
        _labHistoryTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<String?> _encryptNullableText(String? value) async {
    if (value == null) {
      return null;
    }
    return _crypto.encryptText(value);
  }

  Future<String?> _decryptNullableText(String? value) async {
    if (value == null) {
      return null;
    }
    return _decryptTextSafely(value);
  }

  Future<String> _decryptTextSafely(String value) async {
    try {
      return await _crypto.decryptText(value);
    } catch (_) {
      // Keep backward compatibility for legacy plain or invalid values.
      return value;
    }
  }
}