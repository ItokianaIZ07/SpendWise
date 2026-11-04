import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/models/daily_budget.dart';
import 'package:gestion_depenses/core/database/database_service.dart';
import 'package:gestion_depenses/models/budget_period.dart';

class DailyBudgetRepository {
  static final _database = DatabaseService.instance.connexion!;
  static final String _tableName = "daily_budget";

  static Future<DailyBudget?> getByDate(DateTime date) async {
    final dateString = date.toDateString();

    final results = await _database.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [dateString],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return DailyBudget.fromMap(results.first);
  }

  static Future<int> insert(DailyBudget budget) async {
    return await _database.insert(_tableName, budget.toMap());
  }

  static Future<int> update(DailyBudget budget) async {
    return await _database.update(
      _tableName,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  static Future<int> delete(int id) async {
    return await _database.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<double> getSumBudgetByPeriod(BudgetPeriod period) async {
    const sql = '''
      SELECT COALESCE(SUM(amount), 0.0) AS total
      FROM daily_budget
      WHERE date >= ? AND date < ?
    ''';
    final results = await _database.rawQuery(sql, [
      period.startDate.toDateString(),
      period.endDate.toDateString(),
    ]);
    double total = 0;

    for (final item in results) {
      total += (item['total'] as num).toDouble();
    }

    return total;
  }

  static Future<void> changeNotificationState(
    int dailBudgetId, {
    int state = 0,
  }) async {
    String sql = "UPDATE $_tableName SET notification_sent=? WHERE id = ?";
    await _database.execute(sql, [state, dailBudgetId]);
  }

  static Future<List<DailyBudget>> getPerStack({
    required int limit,
    required int offset,
  }) async {
    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      orderBy: "date DESC",
      limit: limit,
      offset: offset,
    );

    return results.map((item) {
      return DailyBudget.fromMap(item);
    }).toList();
  }
}
