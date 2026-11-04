import 'package:flutter/material.dart';
import 'package:gestion_depenses/core/services/notification_service.dart';
import 'package:gestion_depenses/core/utils/currency_util.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/exception/daily_budget_not_found.dart';
import 'package:gestion_depenses/exception/monthly_salary_not_found_exception.dart';
import 'package:gestion_depenses/models/category.dart';
import 'package:gestion_depenses/models/category_with_limit.dart';
import 'package:gestion_depenses/models/daily_budget.dart';
import 'package:gestion_depenses/models/daily_budget_situation.dart';
import 'package:gestion_depenses/models/expense.dart';
import 'package:gestion_depenses/models/expense_group.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/models/monthly_budget_situation.dart';
import 'package:gestion_depenses/models/option_result.dart';
import 'package:gestion_depenses/repositories/expense_repository.dart';
import 'package:gestion_depenses/services/budget_service.dart';
import 'package:gestion_depenses/services/daily_budget_service.dart';

class ExpenseService {
  static OperationResult validateExpenseInput({
    required String amount,
    required String description,
    required CategoryWithLimit? category,
  }) {
    if (!_isAmountValid(amount)) {
      return OperationResult(
        success: false,
        message: 'Veuillez saisir un montant positif valide.',
      );
    }

    if (!_isDescriptionValid(description)) {
      return OperationResult(
        success: false,
        message: 'Veuillez saisir une description valide.',
      );
    }

    if (!_isCategorySelected(category)) {
      return OperationResult(
        success: false,
        message: 'Veuillez choisir une catégorie.',
      );
    }

    return OperationResult(success: true, message: 'Validation réussie.');
  }

  static Future<OperationResult> insertExpense(Expense expense) async {
    try {
      final DateTime today = DateTime.now();

      final bool isToday =
          expense.date.year == today.year &&
          expense.date.month == today.month &&
          expense.date.day == today.day;

      // Une dépense d'aujourd'hui nécessite obligatoirement
      // qu'un budget quotidien ait été fixé.
      if (isToday) {
        await _getRequiredDailyBudget(expense.date);
      }

      // Pour une ancienne date, le budget quotidien n'est pas obligatoire.
      await ExpenseRepository.createExpense(expense);

      // Vérification du dépassement uniquement si un budget existe.
      try {
        await _checkDailyBudgetNotification(expense.date);
      } on DailyBudgetNotFound {
        debugPrint(
          "Dépense ancienne enregistrée sans budget pour "
          "${DatetimeUtil.formatDate(expense.date)}",
        );
      }
      await _checkMonthlyExpenseLimit();

      return OperationResult(
        success: true,
        message: 'Dépense enregistrée avec succès',
      );
    } on DailyBudgetNotFound {
      return OperationResult(
        success: false,
        message: "Aucun budget n'a été fixé pour aujourd'hui.",
      );
    } catch (e) {
      debugPrint("Erreur lors de l'enregistrement de la dépense : $e");

      return OperationResult(
        success: false,
        message: 'Impossible d’enregistrer la dépense',
      );
    }
  }

  static bool _isAmountValid(String amount) {
    if (amount.isEmpty) {
      return false;
    }

    final double? parsed = double.tryParse(amount.replaceAll(',', '.'));

    return parsed != null && parsed > 0;
  }

  static bool _isDescriptionValid(String description) {
    return description.trim().isNotEmpty;
  }

  static bool _isCategorySelected(CategoryWithLimit? category) {
    return category != null;
  }

  // ---------------------------------------------------------------------------
  // RÉCUPÉRATION DES DÉPENSES
  // ---------------------------------------------------------------------------

  static Future<List<Expense>> getAllExpenses({
    int limit = 20,
    int offset = 0,
  }) async {
    return await ExpenseRepository.getAllExpenses(limit: limit, offset: offset);
  }

  static double sumExpenseAmount(List<Expense> expenses) {
    double sum = 0;

    for (var expense in expenses) {
      sum += expense.amount;
    }

    return sum;
  }

  static Future<List<Expense>> getByCategory(
    Category? category,
    int year,
    String? month, {
    int limit = 20,
    int offset = 0,
  }) async {
    final int? monthNumber = month == null ? null : int.tryParse(month);

    if (month != null && monthNumber == null) {
      return [];
    }

    if (category == null) {
      if (year < 0) {
        return await ExpenseRepository.getAllExpenses(
          limit: limit,
          offset: offset,
          month: monthNumber,
        );
      }

      return await ExpenseRepository.getByYear(
        year: year,
        limit: limit,
        offset: offset,
        month: monthNumber,
      );
    }

    if (year < 0) {
      return await ExpenseRepository.getExpensesByCategory(
        category,
        limit: limit,
        offset: offset,
        month: month,
      );
    }

    return await ExpenseRepository.getExpensesByCategoryAndYear(
      category,
      year,
      limit: limit,
      offset: offset,
      month: monthNumber,
    );
  }

  static Future<List<Expense>> searchByKeyWord(
    String keyword,
    int year, {
    int? month,
    int limit = 20,
    int offset = 0,
  }) async {
    if (year < 0) {
      return await ExpenseRepository.getByKeyword(
        keyword,
        month: month,
        limit: limit,
        offset: offset,
      );
    }

    return await ExpenseRepository.getByKeywordAndYear(
      keyword,
      year,
      month: month,
      limit: limit,
      offset: offset,
    );
  }

  static Future<List<Expense>> getByTransactionYear(
    int year, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await ExpenseRepository.getByYear(
      year: year,
      limit: limit,
      offset: offset,
    );
  }

  static Future<List<int>> getListYearTransaction() async {
    return await ExpenseRepository.getListYear();
  }

  static Future<double> calculateSumExpenseByDate(DateTime date) async {
    return await ExpenseRepository.getExpenseByDate(date);
  }

  static Future<double> getExpenseOfTheMonth(int month, int year) async {
    return await ExpenseRepository.getExpenseOfTheMonth(
      DatetimeUtil.formatNumber(month),
      year.toString(),
    );
  }

  static Future<double> getExpenseForPeriod(BudgetPeriod period) =>
      ExpenseRepository.getExpenseForPeriod(period);

  static Future<List<Expense>> getExpenseByLimit(int limit) async {
    return await ExpenseRepository.getExpenseByLimit(limit);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  static Future<int> deleteExpense(Expense expense) async {
    final int deletedExpense = await ExpenseRepository.deleteExpense(expense);

    await _checkDailyBudgetNotification(expense.date);

    return deletedExpense;
  }

  static Future<void> deleteAllExpenses() async {
    final List<DateTime> expenseDates =
        await ExpenseRepository.getAllExpenseDates();

    await ExpenseRepository.deleteAllExpenses();

    for (final date in expenseDates) {
      await _checkDailyBudgetNotification(date);
    }
  }

  static Future<void> updateExpense(Expense expense) async {
    final Expense? oldExpense = await ExpenseRepository.getExpenseById(
      expense.id!,
    );

    if (oldExpense == null) {
      throw Exception("La dépense à modifier n'existe pas.");
    }

    if (oldExpense.date.toDateString() != expense.date.toDateString()) {
      await _getRequiredDailyBudget(expense.date);
    }

    await ExpenseRepository.updateExpense(expense);

    if (oldExpense.date.toDateString() != expense.date.toDateString()) {
      await _checkDailyBudgetNotification(oldExpense.date);
    }

    await _checkDailyBudgetNotification(expense.date);
    await _checkMonthlyExpenseLimit();
  }

  static Future<DailyBudget> _getRequiredDailyBudget(DateTime date) async {
    final DailyBudget? budget = await DailyBudgetService.getBudgetByDate(date);

    if (budget == null) {
      throw DailyBudgetNotFound(date);
    }

    return budget;
  }

  static Future<void> _checkDailyBudgetNotification(DateTime date) async {
    try {
      final double totalExpense = await calculateSumExpenseByDate(date);

      DailyBudget? budget;

      try {
        budget = await DailyBudgetService.getBudgetByDate(date);
      } on DailyBudgetNotFound {
        return;
      }

      final double remaining = budget!.amount - totalExpense;

      if (remaining < 0) {
        if (budget.notificationSent == 0) {
          await NotificationService.instance.showNotification(
            title: "SpendWise",
            body:
                "Vous avez dépassé le budget de ${budget.amount} "
                "fixé le ${DatetimeUtil.formatDate(date)}",
          );

          await DailyBudgetService.changeNotificationState(budget.id!, 1);
        }
      } else {
        if (budget.notificationSent == 1) {
          await DailyBudgetService.changeNotificationState(budget.id!, 0);
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification de la notification : $e");

      rethrow;
    }
  }

  static Future<void> _checkMonthlyExpenseLimit() async {
    try {
      final MonthlyBudgetSituation monthSituation =
          await BudgetService.getCurrentSituation();

      if (monthSituation.spent >= monthSituation.salary * 0.8 &&
          monthSituation.spent < monthSituation.salary * 0.9) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Vous avez déjà dépensé 80 % de votre salaire mensuel.",
        );
      } else if (monthSituation.spent >= monthSituation.salary * 0.9 &&
          monthSituation.spent < monthSituation.salary) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Vous avez déjà dépensé 90 % de votre salaire mensuel.",
        );
      }
      // Salaire dépassé.
      else if (monthSituation.spent > monthSituation.salary) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Vos dépenses réelles du cycle ont dépassé "
              "votre salaire de "
              "${CurrencyUtil.getFormater().format(monthSituation.salary)}.",
        );
      }
    } on MonthlySalaryNotFoundException {
      return;
    }
  }

  // static Future<void> _checkDailyNoExpense() async{
  //   DateTime now = DateTime.now();
  //   if(now.hour == 17){
  //     double expense = await ExpenseRepository.getExpenseByDate(now);
  //     if(expense == 0){ // mbol tsisy dépense izy eto
  //       // notifier l'utilisateur
  //     }
  //   }
  // }

  // ---------------------------------------------------------------------------
  // HISTORIQUE
  // ---------------------------------------------------------------------------

  static Future<List<Expense>> getListExpenseByDate(DateTime date) async {
    return await ExpenseRepository.getListExpenseByDate(date);
  }

  static Future<List<ExpenseGroup>> groupExpensesByDate(
    List<Expense> expenses,
  ) async {
    final Map<String, List<Expense>> grouped = {};

    for (final expense in expenses) {
      final dateKey = expense.date.toDateString();

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(expense);
    }

    final List<ExpenseGroup> groups = [];

    for (final entry in grouped.entries) {
      final DateTime date = DateTime.parse(entry.key);

      DailyBudgetSituation? situation;

      try {
        situation = await BudgetService.getDailySituation(date);
      } on DailyBudgetNotFound {
        situation = null;
      }

      groups.add(
        ExpenseGroup(date: date, expenses: entry.value, situation: situation),
      );
    }

    groups.sort((a, b) => b.date.compareTo(a.date));

    return groups;
  }

  static Future<double> calculateTotalExpense({
    Category? category,
    required int year,
    String? month,
  }) async {
    return await ExpenseRepository.getTotalExpenses(
      category: category,
      year: year,
      month: month,
    );
  }
}
