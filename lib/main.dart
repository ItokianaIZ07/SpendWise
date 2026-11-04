import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gestion_depenses/core/services/notification_service.dart';
import 'package:gestion_depenses/core/themes/app_theme.dart';
import 'core/database/database_service.dart';
import 'package:gestion_depenses/features/navigation/presentation/main_page.dart';
import 'package:gestion_depenses/services/budget_cycle_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  await DatabaseService.instance.initialize();

  await NotificationService.instance.initialize();
  await BudgetCycleService.initialize();

  runApp(
    MaterialApp(
      home: MainPage(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.colors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.colors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.colors.surface,
          foregroundColor: AppTheme.colors.text,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      themeMode: ThemeMode.light,
    ),
  );
}
