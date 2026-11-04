import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_depenses/models/budget_period.dart';

void main() {
  group('BudgetPeriod', () {
    test('uses inclusive start and exclusive end for regular months', () {
      final october = BudgetPeriod.getPeriodByDate(
        DateTime(2026, 10, 20),
        renewalDay: 20,
      );
      final november = october.getNextPeriod();

      expect(october.startDate, DateTime(2026, 10, 20));
      expect(october.endDate, DateTime(2026, 11, 20));
      expect(october.totalDays, 31);
      expect(november.startDate, DateTime(2026, 11, 20));
      expect(november.endDate, DateTime(2026, 12, 20));
    });

    test('clamps short months without changing the configured renewal day', () {
      final january = BudgetPeriod.getPeriodByDate(
        DateTime(2025, 1, 31),
        renewalDay: 31,
      );
      final february = january.getNextPeriod();
      final march = february.getNextPeriod();

      expect(january.endDate, DateTime(2025, 2, 28));
      expect(february.startDate, DateTime(2025, 2, 28));
      expect(february.endDate, DateTime(2025, 3, 31));
      expect(march.startDate, DateTime(2025, 3, 31));
      expect(february.renewalDay, 31);
    });

    test('handles leap years and year boundaries', () {
      final february = BudgetPeriod.getPeriodByDate(
        DateTime(2024, 2, 29),
        renewalDay: 31,
      );
      final january = BudgetPeriod.getPeriodByDate(
        DateTime(2024, 1, 30),
        renewalDay: 31,
      );

      expect(february.startDate, DateTime(2024, 2, 29));
      expect(february.endDate, DateTime(2024, 3, 31));
      expect(january.startDate, DateTime(2023, 12, 31));
    });

    test('chooses the correct current cycle boundary', () {
      expect(
        BudgetPeriod.getCurrentPeriod(
          renewalDay: 20,
          now: DateTime(2026, 11, 19, 23, 59),
        ).startDate,
        DateTime(2026, 10, 20),
      );
      expect(
        BudgetPeriod.getCurrentPeriod(
          renewalDay: 20,
          now: DateTime(2026, 11, 20),
        ).startDate,
        DateTime(2026, 11, 20),
      );
    });

    test('rejects invalid renewal days', () {
      expect(
        () => BudgetPeriod.getCurrentPeriod(renewalDay: 0),
        throwsArgumentError,
      );
    });
  });
}
