import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppSnapshot {
  final int waterAmount;
  final int greenTeaCount;
  final bool chkVitD;
  final bool walk30;
  final bool sun15;
  final bool lowFatDay;
  final Map<String, dynamic>? analyzedResult;
  final List<Map<String, dynamic>> labs;

  AppSnapshot({
    required this.waterAmount,
    required this.greenTeaCount,
    required this.chkVitD,
    required this.walk30,
    required this.sun15,
    required this.lowFatDay,
    required this.analyzedResult,
    required this.labs,
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
      waterAmount: (map['water_amount'] as num?)?.toInt() ?? 1250,
      greenTeaCount: (map['green_tea_count'] as num?)?.toInt() ?? 1,
      chkVitD: (map['chk_vit_d'] as num? ?? 0) == 1,
      walk30: (map['walk_30'] as num? ?? 0) == 1,
      sun15: (map['sun_15'] as num? ?? 0) == 1,
      lowFatDay: (map['low_fat_day'] as num? ?? 0) == 1,
      analyzedResult: rawAnalyzed == null ? null : jsonDecode(rawAnalyzed) as Map<String, dynamic>,
      labs: decodedLabs,
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

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbDir = await getDatabasesPath();
    final dbPath = join(dbDir, _dbName);

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

  Future<void> saveState(AppSnapshot snapshot) async {
    final db = await database;
    await db.insert(
      _stateTable,
      snapshot.toDbMap(),
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

    return AppSnapshot.fromDbMap(rows.first);
  }

  Future<void> addLabHistoryEntry(LabHistoryEntry entry) async {
    final db = await database;
    await db.insert(_labHistoryTable, entry.toDbMap());
  }

  Future<Map<String, List<LabHistoryEntry>>> getAllLabHistoryGrouped() async {
    final db = await database;
    final rows = await db.query(
      _labHistoryTable,
      orderBy: 'metric ASC, date ASC, id ASC',
    );

    final grouped = <String, List<LabHistoryEntry>>{};
    for (final row in rows) {
      final entry = LabHistoryEntry.fromDbMap(row);
      grouped.putIfAbsent(entry.metric, () => <LabHistoryEntry>[]).add(entry);
    }
    return grouped;
  }

  Future<void> deleteLabHistoryByMetric(String metric) async {
    final db = await database;
    await db.delete(
      _labHistoryTable,
      where: 'metric = ?',
      whereArgs: [metric],
    );
  }
}