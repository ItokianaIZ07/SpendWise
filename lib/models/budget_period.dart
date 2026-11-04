class BudgetPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final int renewalDay;

  BudgetPeriod._({
    required this.startDate,
    required this.endDate,
    required this.renewalDay,
  });

  int get totalDays => DateTime.utc(endDate.year, endDate.month, endDate.day)
      .difference(DateTime.utc(startDate.year, startDate.month, startDate.day))
      .inDays;

  static BudgetPeriod getCurrentPeriod({int renewalDay = 1, DateTime? now}) {
    return getPeriodByDate(now ?? DateTime.now(), renewalDay: renewalDay);
  }

  static BudgetPeriod getPeriodByDate(
    DateTime date, {
    required int renewalDay,
  }) {
    _validateRenewalDay(renewalDay);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    var startDate = _effectiveDate(date.year, date.month, renewalDay);

    if (normalizedDate.isBefore(startDate)) {
      final previousMonth = DateTime(date.year, date.month - 1, 1);
      startDate = _effectiveDate(
        previousMonth.year,
        previousMonth.month,
        renewalDay,
      );
    }

    final nextMonth = DateTime(startDate.year, startDate.month + 1, 1);
    final endDate = _effectiveDate(nextMonth.year, nextMonth.month, renewalDay);

    return BudgetPeriod._(
      startDate: startDate,
      endDate: endDate,
      renewalDay: renewalDay,
    );
  }

  BudgetPeriod getNextPeriod() {
    return getPeriodByDate(endDate, renewalDay: renewalDay);
  }

  static DateTime _effectiveDate(int year, int month, int renewalDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final effectiveDay = renewalDay.clamp(1, lastDay).toInt();
    return DateTime(year, month, effectiveDay);
  }

  static void _validateRenewalDay(int renewalDay) {
    if (renewalDay < 1 || renewalDay > 31) {
      throw ArgumentError.value(renewalDay, 'renewalDay', 'Must be 1..31');
    }
  }
}
