import 'package:gestion_depenses/models/monthly_salary.dart';
import 'package:gestion_depenses/core/database/database_service.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:sqflite/sqflite.dart';

class MonthlySalaryRepository {
  static Database get _database => DatabaseService.instance.connexion!;
  static final String _tableName = "monthly_salary";

  static Future<MonthlySalary?> getByPeriodStart(DateTime periodStart) async {
    final results = await _database.query(
      _tableName,
      where: 'period_start = ?',
      whereArgs: [periodStart.toDateString()],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return MonthlySalary.fromMap(results.first);
  }

  static Future<MonthlySalary?> getForPeriod(BudgetPeriod period) =>
      getByPeriodStart(period.startDate);

  static Future<int> insert(MonthlySalary salary) async {
    return await _database.insert(_tableName, salary.toMap());
  }

  static Future<int> update(MonthlySalary salary) async {
    return await _database.update(
      _tableName,
      salary.toMap(),
      where: 'id = ?',
      whereArgs: [salary.id],
    );
  }

  static Future<int> delete(int id) async {
    return await _database.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<MonthlySalary>> getAll() async {
    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      orderBy: "period_start DESC",
    );

    return results.map((item) {
      return MonthlySalary.fromMap(item);
    }).toList();
  }
}
