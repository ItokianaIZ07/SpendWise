import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/models/category_limit.dart';
import 'package:gestion_depenses/models/category_with_limit.dart';
import 'package:gestion_depenses/models/expense_category.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/models/month.dart';
import 'package:sqflite/sqflite.dart';

import 'package:gestion_depenses/core/database/database_service.dart';
import 'package:gestion_depenses/core/database/tables/expense_table.dart';

import 'package:gestion_depenses/models/category.dart';
import 'package:gestion_depenses/models/expense.dart';

import 'category_repository.dart';

class ExpenseRepository {
  static final String _tableName = ExpenseTable.tableName;

  static Database get _database => DatabaseService.instance.connexion!;

  static Future<int> createExpense(Expense expense) {
    return _database.insert(_tableName, expense.toMap());
  }

  static Future<List<Expense>> getAllExpenses({
    required int limit,
    required int offset,
    int? month,
  }) async {
    String sql = """
      SELECT
        c.id AS category_id,
        c.name,
        c.color,
        e.id,
        e.description,
        e.date,
        e.amount

      FROM expenses e

      JOIN category c
        ON c.id = e.category_id
    """;

    final List<dynamic> arguments = [];

    // FILTRE MOIS
    if (month != null) {
      sql += """
        WHERE strftime('%m', e.date) = ?
      """;

      arguments.add(month.toString().padLeft(2, '0'));
    }

    sql += """
      ORDER BY e.date DESC
      LIMIT ? OFFSET ?
    """;

    arguments.add(limit);
    arguments.add(offset);

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    List<Expense> expenses = [];

    for (var map in results) {
      final Category category = Category(
        id: map['category_id'],
        name: map['name'],
        color: map['color'],
      );

      expenses.add(Expense.fromMap(map, category: category));
    }

    return expenses;
  }

  static Future<Expense?> getExpenseById(int id) async {
    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) {
      return null;
    }

    final map = results.first;

    Category? category = await CategoryRepository.getCategoryById(
      map['category_id'],
    );

    if (category == null) {
      return null;
    }

    return Expense.fromMap(map, category: category);
  }

  static Future<int> updateExpense(Expense expense) {
    return _database.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  static Future<int> deleteExpense(Expense expense) {
    return _database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  static Future<List<Expense>> getExpensesByCategory(
    Category category, {
    required int limit,
    required int offset,
    String? month,
  }) async {
    // final debugQuery = await _database.rawQuery("SELECT date, strftime('%Y', date) AS annee_extraite FROM expenses");
    // debugprint("DEBUG DATES EN BDD : $debugQuery");

    String? where = "category_id = ?";
    List<dynamic> whereArgs = [category.id];

    if (month != null) {
      where += " AND strftime('%m', date) = ?";
      whereArgs.add(month.padLeft(2, '0'));
    }

    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: "date DESC",
      limit: limit,
      offset: offset,
    );

    return results
        .map((map) => Expense.fromMap(map, category: category))
        .toList();
  }

  static Future<List<Expense>> getExpensesByCategoryAndYear(
    Category category,
    int year, {
    required int limit,
    required int offset,
    int? month,
  }) async {
    // final debugQuery = await _database.rawQuery("SELECT date, strftime('%Y', date) AS annee_extraite FROM expenses");
    // debugprint("DEBUG DATES EN BDD : $debugQuery");

    String sql = """
      SELECT
        c.id AS category_id,
        c.name,
        c.color,
        e.id,
        e.description,
        e.date,
        e.amount

      FROM expenses e

      JOIN category c
        ON c.id = e.category_id

      WHERE e.category_id = ?
        AND strftime('%Y', e.date) = ?
    """;

    final List<dynamic> arguments = [category.id, year.toString()];

    // FILTRE MOIS
    if (month != null) {
      sql += """
        AND strftime('%m', e.date) = ?
      """;

      arguments.add(month.toString().padLeft(2, '0'));
    }

    sql += """
      ORDER BY e.date DESC
      LIMIT ? OFFSET ?
    """;

    arguments.add(limit);
    arguments.add(offset);

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    return results
        .map((map) => Expense.fromMap(map, category: category))
        .toList();
  }

  // ─────────────────────────────────────────────
  // RECHERCHE PAR MOT-CLÉ
  // ─────────────────────────────────────────────

  static Future<List<Expense>> getByKeyword(
    String keyword, {
    int? month,
    required int limit,
    required int offset,
  }) async {
    String sql = """
      SELECT
        c.id AS category_id,
        c.name,
        c.color,
        e.id,
        e.description,
        e.date,
        e.amount

      FROM expenses e

      JOIN category c
        ON c.id = e.category_id

      WHERE e.description LIKE ? COLLATE NOCASE
    """;

    final List<dynamic> arguments = ["%$keyword%"];

    // FILTRE MOIS
    if (month != null) {
      sql += """
        AND strftime('%m', e.date) = ?
      """;

      arguments.add(month.toString().padLeft(2, '0'));
    }

    sql += """
      ORDER BY e.date DESC
      LIMIT ? OFFSET ?
    """;

    arguments.add(limit);
    arguments.add(offset);

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    return results.map((element) {
      final category = Category(
        id: element["category_id"],
        name: element["name"],
        color: element["color"],
      );

      return Expense(
        id: element["id"],
        description: element["description"],
        amount: (element["amount"] as num).toDouble(),
        category: category,
        date: DateTime.parse(element["date"]),
      );
    }).toList();
  }

  static Future<List<Expense>> getByKeywordAndYear(
    String keyword,
    int year, {
    int? month,
    required int limit,
    required int offset,
  }) async {
    String sql = """
      SELECT
        c.id AS category_id,
        c.name,
        c.color,
        e.id,
        e.description,
        e.date,
        e.amount

      FROM expenses e

      JOIN category c
        ON c.id = e.category_id

      WHERE strftime('%Y', e.date) = ?
        AND e.description LIKE ? COLLATE NOCASE
    """;

    final List<dynamic> arguments = [year.toString(), "%$keyword%"];

    // Si un mois est sélectionné
    if (month != null) {
      sql += """
        AND strftime('%m', e.date) = ?
      """;

      arguments.add(month.toString().padLeft(2, '0'));
    }

    sql += """
      ORDER BY e.date DESC
      LIMIT ? OFFSET ?
    """;

    arguments.add(limit);
    arguments.add(offset);

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    return results.map((element) {
      final category = Category(
        id: element["category_id"],
        name: element["name"],
        color: element["color"],
      );

      return Expense(
        id: element["id"],
        description: element["description"],
        amount: (element["amount"] as num).toDouble(),
        category: category,
        date: DateTime.parse(element["date"]),
      );
    }).toList();
  }

  static Future<List<Expense>> getByYear({
    required int year,
    required int limit,
    required int offset,
    int? month,
  }) async {
    String sql = """
      SELECT
        c.id as category_id,
        c.name,
        c.color,
        e.id,
        e.description,
        e.date,
        e.amount

      FROM expenses e

      JOIN category c
        ON c.id = e.category_id

      WHERE strftime('%Y', e.date) = ?
    """;

    final List<dynamic> arguments = [year.toString()];

    // FILTRE MOIS
    if (month != null) {
      sql += """
        AND strftime('%m', e.date) = ?
      """;

      arguments.add(month.toString().padLeft(2, '0'));
    }

    sql += """
      ORDER BY e.date DESC
      LIMIT ? OFFSET ?
    """;

    arguments.add(limit);
    arguments.add(offset);

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    return results.map((element) {
      Category category = Category(
        id: element["category_id"],
        name: element["name"],
        color: element["color"],
      );

      Expense expense = Expense(
        id: element["id"],
        description: element["description"],
        amount: (element["amount"] as num).toDouble(),
        category: category,
        date: DateTime.parse(element["date"]),
      );

      return expense;
    }).toList();
  }

  static Future<List<int>> getListYear() async {
    String sql =
        "SELECT DISTINCT strftime('%Y', date) as annee FROM $_tableName ORDER BY annee DESC";

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql);

    return results.map((element) {
      return int.parse(element["annee"]);
    }).toList();
  }

  static Future<double> getExpenseOfTheWeek(String week, String year) async {
    String sql =
        """
      SELECT COALESCE(SUM(amount), 0.0) as total
      FROM $_tableName e
      WHERE strftime('%W', e.date) = ?
        AND strftime('%Y', e.date) = ?
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      week,
      year,
    ]);

    // await testDebugDates();

    if (results.isNotEmpty && results.first["total"] != null) {
      return (results.first["total"] as num).toDouble();
    }

    return 0.0;
  }

  static Future<double> getExpenseOfTheMonth(String month, String year) async {
    String sql =
        """
      SELECT COALESCE(SUM(amount), 0.0) as total
      FROM $_tableName e
      WHERE strftime('%m', e.date) = ?
        AND strftime('%Y', e.date) = ?
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      month,
      year,
    ]);

    if (results.isNotEmpty && results.first["total"] != null) {
      return (results.first["total"] as num).toDouble();
    }

    return 0.0;
  }

  static Future<double> getExpenseForPeriod(BudgetPeriod period) async {
    final results = await _database.rawQuery(
      '''
        SELECT COALESCE(SUM(amount), 0.0) AS total
        FROM $_tableName
        WHERE substr(date, 1, 10) >= ? AND substr(date, 1, 10) < ?
      ''',
      [period.startDate.toDateString(), period.endDate.toDateString()],
    );
    return (results.first['total'] as num).toDouble();
  }

  static Future<List<ExpenseCategory>> getExpensePerCategoryForPeriod(
    BudgetPeriod period,
  ) async {
    final results = await _database.rawQuery(
      '''
        SELECT
          c.id,
          c.name,
          c.color,
          COALESCE(l.amount, 0.0) AS limit_amount,
          COALESCE(SUM(e.amount), 0.0) AS total
        FROM category c
        LEFT JOIN $_tableName e
          ON c.id = e.category_id
          AND substr(e.date, 1, 10) >= ?
          AND substr(e.date, 1, 10) < ?
        LEFT JOIN category_limit l ON l.category_id = c.id
        GROUP BY c.id, c.name, c.color, l.amount
        ORDER BY total DESC
      ''',
      [period.startDate.toDateString(), period.endDate.toDateString()],
    );

    return results.map((element) {
      final category = Category(
        id: element['id'] as int,
        name: element['name'] as String,
        color: element['color'] as String?,
      );
      final limit = CategoryLimit(
        amount: (element['limit_amount'] as num).toDouble(),
        category: category,
      );
      return ExpenseCategory(
        amount: (element['total'] as num).toDouble(),
        category: CategoryWithLimit(category: category, categoryLimit: limit),
      );
    }).toList();
  }

  static Future<Map<int, double>> getDailyExpenseForPeriod(
    BudgetPeriod period,
  ) async {
    final dailyData = <int, double>{
      for (var day = 1; day <= period.totalDays; day++) day: 0,
    };
    final results = await _database.rawQuery(
      '''
        SELECT substr(date, 1, 10) AS expense_date,
               COALESCE(SUM(amount), 0.0) AS total
        FROM $_tableName
        WHERE substr(date, 1, 10) >= ? AND substr(date, 1, 10) < ?
        GROUP BY substr(date, 1, 10)
      ''',
      [period.startDate.toDateString(), period.endDate.toDateString()],
    );

    for (final result in results) {
      final expenseDate = DateTime.parse(result['expense_date'] as String);
      final dayIndex =
          DateTime.utc(expenseDate.year, expenseDate.month, expenseDate.day)
              .difference(
                DateTime.utc(
                  period.startDate.year,
                  period.startDate.month,
                  period.startDate.day,
                ),
              )
              .inDays +
          1;
      dailyData[dayIndex] = (result['total'] as num).toDouble();
    }

    return dailyData;
  }

  static Future<double> getExpenseOfTheYear(String year) async {
    String sql =
        """
      SELECT COALESCE(SUM(amount), 0.0) as total
      FROM $_tableName e
      WHERE strftime('%Y', e.date) = ?
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      year,
    ]);

    if (results.isNotEmpty && results.first["total"] != null) {
      return (results.first["total"] as num).toDouble();
    }

    return 0.0;
  }

  static Future<List<ExpenseCategory>> getExpensePerCategory({
    required int option,
    required String week,
    required String month,
    required String year,
    required String condition,
  }) async {
    // COALESCE(...) pour remplacer NULL par 0.0
    String sql =
        """
      SELECT
        c.id,
        c.name,
        c.color,
        COALESCE(l.amount, 0.0) as limit_amount,
        COALESCE(SUM(e.amount), 0.0) as total
      FROM category c
      LEFT JOIN $_tableName e ON c.id = e.category_id
      LEFT JOIN category_limit l ON l.category_id = c.id
      $condition
      GROUP BY c.id, c.name, c.color, l.amount
      ORDER BY total DESC
    """;

    List<String> arguments = [];

    if (option == 0) {
      arguments = [week, year];
    } else if (option == 1) {
      arguments = [month, year];
    } else {
      arguments = [year.toString()];
    }

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    return results.map((element) {
      Category category = Category(
        id: element["id"],
        name: element["name"],
        color: element["color"],
      );

      double limitAmount = (element["limit_amount"] as num?)?.toDouble() ?? 0.0;

      double totalExpense = (element["total"] as num?)?.toDouble() ?? 0.0;

      CategoryLimit limit = CategoryLimit(
        amount: limitAmount,
        category: category,
      );

      CategoryWithLimit categoryWithLimit = CategoryWithLimit(
        category: category,
        categoryLimit: limit,
      );

      return ExpenseCategory(amount: totalExpense, category: categoryWithLimit);
    }).toList();
  }

  static Future<Map<int, double>> getDailyExpense(
    String week,
    String year,
  ) async {
    String sql =
        """
      SELECT
        strftime('%w', date) as day_index,
        COALESCE(SUM(amount), 0.0) as total
      FROM $_tableName
      WHERE strftime('%W', date) = ?
        AND strftime('%Y', date) = ?
      GROUP BY day_index
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      week,
      year,
    ]);

    Map<int, double> weeklyData = {
      1: 0.0, // Lundi
      2: 0.0, // Mardi
      3: 0.0, // Mercredi
      4: 0.0, // Jeudi
      5: 0.0, // Vendredi
      6: 0.0, // Samedi
      7: 0.0, // Dimanche (0 dans SQLite)
    };

    for (var data in results) {
      int dayIndex = int.parse(data["day_index"]);
      double total = (data["total"] as num).toDouble();

      if (dayIndex == 0) {
        weeklyData[7] = total;
      } else {
        weeklyData[dayIndex] = total;
      }
    }

    return weeklyData;
  }

  static Future<Map<int, double>> getMonthlyDailyExpense(
    String month,
    String year,
  ) async {
    int monthInt = int.parse(month);
    int yearInt = int.parse(year);

    int daysInMonth = DateTime(yearInt, monthInt + 1, 0).day;

    Map<int, double> monthlyData = {
      for (int i = 1; i <= daysInMonth; i++) i: 0.0,
    };

    // groupe par jour du mois ('%d')
    String sql =
        """
      SELECT
        strftime('%d', date) as day_of_month,
        COALESCE(SUM(amount), 0.0) as total
      FROM $_tableName
      WHERE strftime('%m', date) = ?
        AND strftime('%Y', date) = ?
      GROUP BY day_of_month
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      month,
      year,
    ]);

    for (var data in results) {
      int day = int.parse(data["day_of_month"]);
      double total = (data["total"] as num).toDouble();

      monthlyData[day] = total;
    }

    return monthlyData;
  }

  static Future<Map<int, double>> getYearlyMonthlyExpense(String year) async {
    Map<int, double> yearlyData = {
      for (int month = 1; month <= 12; month++) month: 0.0,
    };

    String sql =
        """
      SELECT
        strftime('%m', date) as month_index,
        COALESCE(SUM(amount), 0.0) as total
      FROM $_tableName
      WHERE strftime('%Y', date) = ?
      GROUP BY month_index
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      year,
    ]);

    for (var data in results) {
      int monthIndex = int.parse(data["month_index"]);
      double total = (data["total"] as num).toDouble();

      yearlyData[monthIndex] = total;
    }

    return yearlyData;
  }

  static Future<void> deleteAllExpenses() async {
    await _database.delete(_tableName);
  }

  static Future<List<Month>> getListMonths(String year) async {
    String sql =
        """
      SELECT DISTINCT
        strftime('%m', date) AS numero_mois,
        CASE strftime('%m', date)
          WHEN '01' THEN 'Janvier'
          WHEN '02' THEN 'Février'
          WHEN '03' THEN 'Mars'
          WHEN '04' THEN 'Avril'
          WHEN '05' THEN 'Mai'
          WHEN '06' THEN 'Juin'
          WHEN '07' THEN 'Juillet'
          WHEN '08' THEN 'Août'
          WHEN '09' THEN 'Septembre'
          WHEN '10' THEN 'Octobre'
          WHEN '11' THEN 'Novembre'
          WHEN '12' THEN 'Décembre'
        END AS mois
      FROM $_tableName
      WHERE strftime('%Y', date) = ?
      ORDER BY numero_mois ASC
    """;

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      year,
    ]);

    return results.map((item) {
      // return Month(
      //   "label": item["mois"].toString(),
      //   "value": item["numero_mois"].toString()
      // );

      return Month(
        label: item["mois"].toString(),
        value: item["numero_mois"].toString(),
      );
    }).toList();
  }

  static Future<List<Expense>?> getExpenseByMonthAndYear(
    Category category,
    String month,
    String year,
  ) async {
    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      where: "strftime('%m', date) = ? AND strftime('%Y', date) = ?",
      whereArgs: [month, year],
      orderBy: "date DESC",
    );

    if (results.isEmpty) {
      return null;
    }

    return results.map((expense) {
      return Expense.fromMap(expense, category: category);
    }).toList();
  }

  static Future<double> getExpenseByDate(DateTime date) async {
    String dateString = date.toDateString();

    String sql =
        "SELECT COALESCE(SUM(amount),0) as total FROM $_tableName WHERE strftime('%Y-%m-%d' ,date) = ?";

    final List<Map<String, dynamic>> results = await _database.rawQuery(sql, [
      dateString,
    ]);

    double total = 0;

    for (var element in results) {
      total += (element["total"] as num).toDouble();
    }

    return total;
  }

  static Future<List<Expense>> getExpenseByLimit(int limit) async {
    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      orderBy: "date DESC",
      limit: limit,
    );

    List<Expense> expenses = [];

    for (var map in results) {
      Category? category = await CategoryRepository.getCategoryById(
        map['category_id'],
      );

      if (category != null) {
        expenses.add(Expense.fromMap(map, category: category));
      }
    }

    return expenses;
  }

  static Future<List<DateTime>> getAllExpenseDates() async {
    String sql = "SELECT DISTINCT date FROM $_tableName";

    List<Map<String, dynamic>> results = await _database.rawQuery(sql);

    return results.map((item) {
      return DateTime.parse(item["date"] as String);
    }).toList();
  }

  static Future<List<Expense>> getListExpenseByDate(DateTime date) async {
    final List<Map<String, dynamic>> results = await _database.query(
      _tableName,
      where: "strftime('%Y-%m-%d', date) = ?",
      whereArgs: [date.toDateString()],
    );

    List<Expense> expenses = [];

    for (var map in results) {
      Category? category = await CategoryRepository.getCategoryById(
        map['category_id'],
      );

      if (category != null) {
        expenses.add(Expense.fromMap(map, category: category));
      }
    }

    return expenses;
  }

  static Future<double> getTotalExpenses({
    Category? category,
    required int year,
    String? month,
  }) async {
    String sql = """
      SELECT COALESCE(SUM(e.amount), 0) AS total
      FROM expenses e
      WHERE 1 = 1
    """;

    final List<dynamic> arguments = [];

    if (year > 0) {
      sql += """
      AND strftime('%Y', e.date) = ?
    """;

      arguments.add(year.toString());
    }

    if (category != null) {
      sql += """
      AND e.category_id = ?
    """;

      arguments.add(category.id);
    }

    if (month != null) {
      sql += """
      AND strftime('%m', e.date) = ?
    """;

      arguments.add(month.padLeft(2, '0'));
    }

    final List<Map<String, dynamic>> results = await _database.rawQuery(
      sql,
      arguments,
    );

    return (results.first['total'] as num).toDouble();
  }

  //   static Future<void> testDebugDates() async {
  //   // Sélectionne les dates brutes ainsi que la semaine et l'année calculées par SQLite
  //   String sql = """
  //     SELECT
  //       date,
  //       strftime('%W', date) AS semaine_sqlite,
  //       strftime('%Y', date) AS annee_sqlite,
  //       amount
  //     FROM $_tableName
  //     LIMIT 10
  //   """;

  //   debugPrint("--- TEST DEBUG DATES ---");
  //   for (var row in results) {
  //     debugPrint(
  //       "Date BDD: ${row['date']} | Semaine SQLite: '${row['semaine_sqlite']}' | Année SQLite: '${row['annee_sqlite']}' | Montant: ${row['amount']}"
  //     );
  //   }
  //   debugPrint("------------------------");
  // }
}
