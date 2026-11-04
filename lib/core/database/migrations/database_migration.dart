import 'package:gestion_depenses/core/database/tables/daily_budget_table.dart';
import 'package:gestion_depenses/core/database/tables/budget_settings_table.dart';
import 'package:gestion_depenses/core/database/tables/monthly_salary_table.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseMigration {
  static Future<void> upgradeToVersion2(Database db) async {
    await MonthlySalaryTable.createTable(db);

    await DailyBudgetTable.createTable(db);
  }

  static Future<void> upgradeToVersion3(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(${MonthlySalaryTable.tableName})',
    );
    final columnNames = columns.map((column) => column['name']).toSet();
    final needsRebuild =
        !columnNames.contains('period_start') ||
        columnNames.contains('month') ||
        columnNames.contains('year');
    int? legacyRenewalDay;
    if (columnNames.contains('day')) {
      final oldSettings = await db.query(
        MonthlySalaryTable.tableName,
        columns: ['day'],
        orderBy: 'id DESC',
      );
      legacyRenewalDay = oldSettings
          .map((row) => row['day'])
          .whereType<int>()
          .firstWhere((day) => day >= 1 && day <= 31, orElse: () => 1);
    }

    if (needsRebuild) {
      final oldSalaries = await db.query(MonthlySalaryTable.tableName);
      await db.execute('DROP TABLE IF EXISTS monthly_salary_new');
      await db.execute('''
        CREATE TABLE monthly_salary_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          period_start TEXT NOT NULL UNIQUE,
          amount REAL NOT NULL CHECK(amount >= 0)
        )
      ''');

      for (final salary in oldSalaries) {
        final String periodStart;
        if (salary['period_start'] is String) {
          periodStart = (salary['period_start'] as String).substring(0, 10);
        } else {
          final year = salary['year'] as int;
          final month = salary['month'] as int;
          periodStart = '$year-${month.toString().padLeft(2, '0')}-01';
        }

        await db.insert('monthly_salary_new', {
          'id': salary['id'],
          'period_start': periodStart,
          'amount': salary['amount'],
        });
      }

      await db.execute('DROP TABLE ${MonthlySalaryTable.tableName}');
      await db.execute(
        'ALTER TABLE monthly_salary_new RENAME TO ${MonthlySalaryTable.tableName}',
      );
    }

    await BudgetSettingsTable.createTable(db);
    if (columnNames.contains('day')) {
      await db.update(BudgetSettingsTable.tableName, {
        'renewal_day': legacyRenewalDay ?? 1,
      }, where: 'id = 1');
    }
  }
}
