import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gestion_depenses/features/home/widgets/salary_form.dart';
import 'package:gestion_depenses/models/budget_period.dart';

void main() {
  testWidgets('salary form cannot be dismissed before saving', (tester) async {
    await initializeDateFormatting('fr_FR', null);
    final period = BudgetPeriod.getPeriodByDate(
      DateTime(2026, 11, 4),
      renewalDay: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => SalaryForm(period: period),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(SalaryForm), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SalaryForm), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(SalaryForm), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '1000000');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byType(SalaryForm), findsOneWidget);
    expect(find.textContaining('Enregistrement impossible'), findsOneWidget);
  });
}
