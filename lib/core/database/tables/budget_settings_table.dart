import 'package:sqflite/sqflite.dart';

class BudgetSettingsTable {
  static const String tableName = 'budget_settings';

  static Future<void> createTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        renewal_day INTEGER NOT NULL DEFAULT 1
          CHECK(renewal_day BETWEEN 1 AND 31),
        last_observed_period_start TEXT
      )
    ''');
    await database.insert(tableName, {
      'id': 1,
      'renewal_day': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
