import 'package:gestion_depenses/core/database/migrations/database_migration.dart';
import 'package:gestion_depenses/core/database/tables/daily_budget_table.dart';
import 'package:gestion_depenses/core/database/tables/budget_settings_table.dart';
import 'package:gestion_depenses/core/database/tables/monthly_salary_table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';
import 'tables/category_table.dart';
import 'tables/expense_table.dart';
import 'tables/limit_table.dart';
import 'tables/appMetadata_table.dart';
import 'seeders/category_seeder.dart';
import 'seeders/limit_seeder.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();

  DatabaseService._();

  static DatabaseService get instance => _instance;

  Database? connexion;

  Future<void> initialize() async {
    await _openDatabase();
  }

  Future<Database> _openDatabase() async {
    if (connexion != null) {
      return connexion!;
    }
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, DatabaseConstants.databaseName);
    connexion = await openDatabase(
      path,
      version: DatabaseConstants.version,
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertDefaultData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await DatabaseMigration.upgradeToVersion2(db);
        }
        if (oldVersion < 3) {
          await DatabaseMigration.upgradeToVersion3(db);
        }
      },
    );
    return connexion!;
  }

  Future<void> _createTables(Database database) async {
    await CategoryTable.createTable(database);
    await ExpenseTable.createTable(database);
    await LimitTable.createTable(database);
    await AppmetadataTable.createTable(database);
    await MonthlySalaryTable.createTable(database);
    await BudgetSettingsTable.createTable(database);
    await DailyBudgetTable.createTable(database);
  }

  Future<void> _insertDefaultData(Database database) async {
    await CategorySeeder.initialize(database);
    await LimitSeeder.initialize(database);
  }
}
