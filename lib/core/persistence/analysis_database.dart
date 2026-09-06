import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AnalysisRunRecord {
  const AnalysisRunRecord({
    required this.id,
    required this.scenarioName,
    required this.kind,
    required this.input,
    required this.result,
    required this.values,
    required this.createdAt,
  });

  final int? id;
  final String scenarioName;
  final String kind;
  final Map<String, Object?> input;
  final String result;
  final List<double> values;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'scenario_name': scenarioName,
    'kind': kind,
    'input_json': jsonEncode(input),
    'result_text': result,
    'values_json': jsonEncode(values),
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory AnalysisRunRecord.fromMap(Map<String, Object?> map) {
    return AnalysisRunRecord(
      id: map['id'] as int?,
      scenarioName: map['scenario_name']! as String,
      kind: map['kind']! as String,
      input: Map<String, Object?>.from(
        jsonDecode(map['input_json']! as String) as Map,
      ),
      result: map['result_text']! as String,
      values: [
        for (final value in jsonDecode(map['values_json']! as String) as List)
          (value as num).toDouble(),
      ],
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}

class ObservatoryRunRecord {
  const ObservatoryRunRecord({
    required this.name,
    required this.input,
    required this.result,
    required this.createdAt,
  });

  final String name;
  final Map<String, Object?> input;
  final Map<String, Object?> result;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'name': name,
    'input_json': jsonEncode(input),
    'result_json': jsonEncode(result),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
}

class AnalysisDatabase {
  AnalysisDatabase._();

  static final AnalysisDatabase instance = AnalysisDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasesPath, 'primeiro_radiante.db'),
      version: 2,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE scenarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id TEXT NOT NULL,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(project_id, name)
          )
        ''');
        await database.execute('''
          CREATE TABLE calculation_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scenario_id INTEGER NOT NULL,
            kind TEXT NOT NULL,
            input_json TEXT NOT NULL,
            result_text TEXT NOT NULL,
            values_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(scenario_id) REFERENCES scenarios(id)
          )
        ''');
        await database.insert('projects', {
          'id': 'default',
          'title': 'Primeiro Radiante',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            CREATE TABLE IF NOT EXISTS observatory_runs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              input_json TEXT NOT NULL,
              result_json TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
    return _database!;
  }

  Future<int> saveRun({
    required String scenarioName,
    required String kind,
    required Map<String, Object?> input,
    required String result,
    required List<double> values,
  }) async {
    final database = await this.database;
    return database.transaction((transaction) async {
      final now = DateTime.now().toUtc().toIso8601String();
      await transaction.insert('scenarios', {
        'project_id': 'default',
        'name': scenarioName,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final scenario = await transaction.query(
        'scenarios',
        where: 'project_id = ? AND name = ?',
        whereArgs: ['default', scenarioName],
        limit: 1,
      );
      return transaction.insert('calculation_runs', {
        'scenario_id': scenario.first['id'],
        'kind': kind,
        'input_json': jsonEncode(input),
        'result_text': result,
        'values_json': jsonEncode(values),
        'created_at': now,
      });
    });
  }

  Future<List<ProjectRecord>> projects() async {
    final database = await this.database;
    final rows = await database.query('projects', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => ProjectRecord(
            id: row['id']! as String,
            title: row['title']! as String,
            createdAt: DateTime.parse(row['created_at']! as String),
          ),
        )
        .toList();
  }

  Future<void> createProject({
    required String id,
    required String title,
  }) async {
    final database = await this.database;
    await database.insert('projects', {
      'id': id,
      'title': title.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> renameProject({
    required String id,
    required String title,
  }) async {
    final database = await this.database;
    await database.update(
      'projects',
      {'title': title.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteProject(String id) async {
    if (id == 'default') {
      throw ArgumentError('o projeto padrão não pode ser excluído');
    }
    final database = await this.database;
    await database.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AnalysisRunRecord>> recentRuns({int limit = 50}) async {
    final database = await this.database;
    final rows = await database.rawQuery(
      '''
      SELECT calculation_runs.*, scenarios.name AS scenario_name
      FROM calculation_runs
      INNER JOIN scenarios ON scenarios.id = calculation_runs.scenario_id
      ORDER BY calculation_runs.created_at DESC
      LIMIT ?
    ''',
      [limit],
    );
    return rows.map(AnalysisRunRecord.fromMap).toList();
  }

  Future<String> exportJson({int limit = 100}) async {
    final runs = await recentRuns(limit: limit);
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'engineVersion': 'analysis-1',
      'runs': runs.map((run) => run.toMap()).toList(),
    });
  }

  Future<String> exportText({int limit = 100}) async {
    final runs = await recentRuns(limit: limit);
    return runs
        .map(
          (run) =>
              '${run.scenarioName} | ${run.kind} | '
              '${run.createdAt.toLocal()}\n${run.result}',
        )
        .join('\n\n');
  }

  Future<int> saveObservatory({required ObservatoryRunRecord run}) async {
    final database = await this.database;
    await database.execute('''
      CREATE TABLE IF NOT EXISTS observatory_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        input_json TEXT NOT NULL,
        result_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    return database.insert('observatory_runs', run.toMap());
  }

  Future<List<ObservatoryRunRecord>> recentObservatory({int limit = 20}) async {
    final database = await this.database;
    final exists = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'observatory_runs'",
    );
    if (exists.isEmpty) return const [];
    final rows = await database.query(
      'observatory_runs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (row) => ObservatoryRunRecord(
            name: row['name']! as String,
            input: Map<String, Object?>.from(
              jsonDecode(row['input_json']! as String) as Map,
            ),
            result: Map<String, Object?>.from(
              jsonDecode(row['result_json']! as String) as Map,
            ),
            createdAt: DateTime.parse(row['created_at']! as String),
          ),
        )
        .toList();
  }

  Future<Map<String, Object?>> compareRuns(int firstId, int secondId) async {
    final database = await this.database;
    final rows = await database.query(
      'calculation_runs',
      where: 'id IN (?, ?)',
      whereArgs: [firstId, secondId],
    );
    if (rows.length != 2) throw ArgumentError('duas execuções são necessárias');
    final first = AnalysisRunRecord.fromMap(rows[0]);
    final second = AnalysisRunRecord.fromMap(rows[1]);
    return {
      'first': first.toMap(),
      'second': second.toMap(),
      'lastValueDelta': second.values.last - first.values.last,
    };
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
