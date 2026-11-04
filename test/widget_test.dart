// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_depenses/features/home/widgets/salary_form.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('salary form displays the budget cycle dates', (
    WidgetTester tester,
  ) async {
    await initializeDateFormatting('fr_FR', null);
    final period = BudgetPeriod.getPeriodByDate(
      DateTime(2026, 11, 4),
      renewalDay: 20,
    );

    await tester.pumpWidget(MaterialApp(home: SalaryForm(period: period)));

    expect(find.textContaining('Période :'), findsOneWidget);
    expect(find.textContaining('20 oct. 2026'), findsOneWidget);
    expect(find.textContaining('19 nov. 2026'), findsOneWidget);
  });
}
