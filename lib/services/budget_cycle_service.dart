import 'package:gestion_depenses/core/database/database_service.dart';
import 'package:gestion_depenses/core/database/tables/budget_settings_table.dart';
import 'package:gestion_depenses/core/services/notification_service.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/repositories/budget_settings_repository.dart';
import 'package:sqflite/sqflite.dart';

class BudgetCycleService {
  static Database get _database => DatabaseService.instance.connexion!;

  static Future<int> getRenewalDay() =>
      BudgetSettingsRepository.getRenewalDay();

  static Future<BudgetPeriod> getCurrentPeriod({DateTime? now}) async {
    final renewalDay = await getRenewalDay();
    return BudgetPeriod.getCurrentPeriod(renewalDay: renewalDay, now: now);
  }

  static Future<void> updateRenewalDay(int renewalDay) async {
    BudgetPeriod.getCurrentPeriod(renewalDay: renewalDay);

    await _database.transaction((transaction) async {
      final settings = await transaction.query(
        BudgetSettingsTable.tableName,
        columns: ['renewal_day'],
        where: 'id = 1',
        limit: 1,
      );
      if (settings.isEmpty) {
        throw StateError('Les paramètres budgétaires sont introuvables.');
      }

      final oldRenewalDay = settings.first['renewal_day'] as int;
      if (oldRenewalDay == renewalDay) return;

      final now = DateTime.now();
      final oldPeriod = BudgetPeriod.getCurrentPeriod(
        renewalDay: oldRenewalDay,
        now: now,
      );
      final newPeriod = BudgetPeriod.getCurrentPeriod(
        renewalDay: renewalDay,
        now: now,
      );
      final oldStart = oldPeriod.startDate.toDateString();
      final newStart = newPeriod.startDate.toDateString();
      final currentSalary = await transaction.query(
        'monthly_salary',
        where: 'period_start = ?',
        whereArgs: [oldStart],
        limit: 1,
      );
      final targetSalary = await transaction.query(
        'monthly_salary',
        where: 'period_start = ?',
        whereArgs: [newStart],
        limit: 1,
      );

      if (currentSalary.isNotEmpty &&
          targetSalary.isNotEmpty &&
          currentSalary.first['id'] != targetSalary.first['id']) {
        throw StateError(
          'Modification impossible : un salaire historique existe déjà '
          'pour le cycle de destination. Aucun salaire n’a été modifié.',
        );
      }

      if (currentSalary.isNotEmpty && oldStart != newStart) {
        await transaction.update(
          'monthly_salary',
          {'period_start': newStart},
          where: 'id = ?',
          whereArgs: [currentSalary.first['id']],
        );
      }

      await transaction.update(BudgetSettingsTable.tableName, {
        'renewal_day': renewalDay,
        'last_observed_period_start': newStart,
      }, where: 'id = 1');
    });

    final newPeriod = await getCurrentPeriod();
    await NotificationService.instance.scheduleRenewal(
      newPeriod.getNextPeriod().startDate,
    );
  }

  static Future<void> initialize() async {
    final period = await getCurrentPeriod();
    final lastObserved =
        await BudgetSettingsRepository.getLastObservedPeriodStart();

    if (lastObserved != null && lastObserved.isBefore(period.startDate)) {
      await NotificationService.instance.showNotification(
        title: 'Nouveau cycle budgétaire',
        body:
            'Votre nouveau cycle a commencé le '
            '${DatetimeUtil.formatDate(period.startDate)}.',
      );
    }

    await BudgetSettingsRepository.setLastObservedPeriodStart(period.startDate);
    await NotificationService.instance.scheduleRenewal(
      period.getNextPeriod().startDate,
    );
  }
}
