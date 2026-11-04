import 'package:gestion_depenses/core/services/notification_service.dart';
import 'package:gestion_depenses/core/utils/currency_util.dart';
import 'package:gestion_depenses/exception/daily_budget_not_found.dart';
import 'package:gestion_depenses/exception/monthly_salary_not_found_exception.dart';
import 'package:gestion_depenses/exception/negative_amount_value.dart';
import 'package:gestion_depenses/models/daily_budget.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/models/monthly_budget_situation.dart';
import 'package:gestion_depenses/repositories/daily_budget_repository.dart';
import 'package:gestion_depenses/services/budget_service.dart';

class DailyBudgetService {
  static Future<DailyBudget?> getBudgetByDate(DateTime date) async {
    final budget = await DailyBudgetRepository.getByDate(date);
    if (budget == null) {
      throw DailyBudgetNotFound(date);
    }
    return budget;
  }

  static Future<int> saveBudget(DailyBudget budget) async {
    if (budget.amount <= 0) {
      throw NegativeAmountValue(message: 'Le budget doit être supérieur à 0.');
    }

    final existingBudget = await DailyBudgetRepository.getByDate(budget.date);

    if (existingBudget != null) {
      throw Exception('Un budget existe déjà pour cette journée.');
    }

    int insertedBudget = await DailyBudgetRepository.insert(budget);
    await _checkMonthlyBudgetLimit();

    return insertedBudget;
  }

  static Future<int> updateBudget(DailyBudget budget) async {
    if (budget.amount <= 0) {
      throw Exception('Le budget doit être supérieur à 0.');
    }

    int updatedBudget = await DailyBudgetRepository.update(budget);
    await _checkMonthlyBudgetLimit();

    return updatedBudget;
  }

  static Future<int> deleteBudget(int id) async {
    return await DailyBudgetRepository.delete(id);
  }

  static Future<double> calculateSumBudgetByPeriod(BudgetPeriod period) async {
    return DailyBudgetRepository.getSumBudgetByPeriod(period);
  }

  static Future<void> changeNotificationState(int id, int state) async {
    await DailyBudgetRepository.changeNotificationState(id, state: state);
  }

  static Future<List<DailyBudget>> getAllPlanifiedBudget({
    required int limit,
    required int offset,
  }) async {
    return await DailyBudgetRepository.getPerStack(
      limit: limit,
      offset: offset,
    );
  }

  static Future<void> _checkMonthlyBudgetLimit() async {
    try {
      final MonthlyBudgetSituation monthSituation =
          await BudgetService.getCurrentSituation();

      if (monthSituation.plannedBudget > monthSituation.salary) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Le total des budgets que vous avez planifiés "
              "ce cycle dépasse votre salaire qui est de "
              "${CurrencyUtil.getFormater().format(monthSituation.salary)}.",
        );
      } else if (monthSituation.spent > monthSituation.salary) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Vos dépenses réelles de ce mois ont dépassé "
              "votre salaire de "
              "${CurrencyUtil.getFormater().format(monthSituation.salary)}.",
        );
      } else if (monthSituation.plannedBudget >= monthSituation.salary * 0.8 &&
          monthSituation.plannedBudget < monthSituation.salary * 0.9) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Vous avez déjà planifié 80 % de votre salaire mensuel.",
        );
      } else if (monthSituation.plannedBudget >= monthSituation.salary * 0.9 &&
          monthSituation.plannedBudget < monthSituation.salary) {
        await NotificationService.instance.showNotification(
          title: "SpendWise Alert",
          body:
              "Attention ! Vous avez déjà planifié 90 % de votre salaire mensuel.",
        );
      }
    } on MonthlySalaryNotFoundException {
      return;
    }
  }
}
