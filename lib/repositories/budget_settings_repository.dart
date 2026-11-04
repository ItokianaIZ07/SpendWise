import 'package:gestion_depenses/core/database/database_service.dart';
import 'package:gestion_depenses/core/database/tables/budget_settings_table.dart';
import 'package:sqflite/sqflite.dart';

class BudgetSettingsRepository {
  static Database get _database => DatabaseService.instance.connexion!;

  static Future<int> getRenewalDay() async {
    final settings = await _database.query(
      BudgetSettingsTable.tableName,
      columns: ['renewal_day'],
      where: 'id = 1',
      limit: 1,
    );
    if (settings.isEmpty) {
      throw StateError('Budget settings have not been initialized.');
    }
    return settings.first['renewal_day'] as int;
  }

  static Future<DateTime?> getLastObservedPeriodStart() async {
    final settings = await _database.query(
      BudgetSettingsTable.tableName,
      columns: ['last_observed_period_start'],
      where: 'id = 1',
      limit: 1,
    );
    if (settings.isEmpty) {
      throw StateError('Budget settings have not been initialized.');
    }
    final value = settings.first['last_observed_period_start'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  static Future<void> setLastObservedPeriodStart(DateTime date) async {
    await _database.update(BudgetSettingsTable.tableName, {
      'last_observed_period_start': _dateString(date),
    }, where: 'id = 1');
  }

  static String dateString(DateTime date) => _dateString(date);

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
