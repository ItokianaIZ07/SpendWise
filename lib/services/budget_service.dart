import 'package:gestion_depenses/exception/daily_budget_not_found.dart';
import 'package:gestion_depenses/exception/monthly_salary_not_found_exception.dart';
import 'package:gestion_depenses/models/daily_budget.dart';
import 'package:gestion_depenses/models/daily_budget_situation.dart';
import 'package:gestion_depenses/models/monthly_budget_situation.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/services/budget_cycle_service.dart';
import 'package:gestion_depenses/services/daily_budget_service.dart';
import 'package:gestion_depenses/services/expense_service.dart';
import 'package:gestion_depenses/services/monthly_salary_service.dart';

class BudgetService {
  static Future<DailyBudgetSituation> getDailySituation(DateTime date) async {
    DailyBudget? todayBudget = await DailyBudgetService.getBudgetByDate(date);
    double todayTotalExpense = await ExpenseService.calculateSumExpenseByDate(
      date,
    );
    if (todayBudget == null) {
      throw DailyBudgetNotFound(date);
    }

    double consommation = todayBudget.amount == 0
        ? 0
        : (todayTotalExpense / todayBudget.amount) * 100;

    double result = todayBudget.amount - todayTotalExpense;

    return DailyBudgetSituation(
      budget: todayBudget.amount,
      spent: todayTotalExpense,
      percentage: consommation,
      remaining: result,
    );
  }

  static Future<MonthlyBudgetSituation> getCurrentSituation() async {
    final period = await BudgetCycleService.getCurrentPeriod();
    return getSituationForPeriod(period);
  }

  static Future<MonthlyBudgetSituation> getSituationForPeriod(
    BudgetPeriod period,
  ) async {
    final monthlySalary = await MonthlySalaryService.getSalary(period);
    if (monthlySalary == null) {
      throw MonthlySalaryNotFoundException(
        period.startDate.month,
        period.startDate.year,
      );
    }

    final plannedBudget = await DailyBudgetService.calculateSumBudgetByPeriod(
      period,
    );
    final spent = await ExpenseService.getExpenseForPeriod(period);
    final remaining = monthlySalary.amount - spent;
    return MonthlyBudgetSituation(
      salary: monthlySalary.amount,
      plannedBudget: plannedBudget,
      availableBudget: monthlySalary.amount - spent,
      remaining: remaining,
      spent: spent,
    );
  }
}
