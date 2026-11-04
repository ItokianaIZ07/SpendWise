import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_depenses/core/themes/app_theme.dart';
import 'package:gestion_depenses/exception/daily_budget_not_found.dart';
// import 'package:gestion_depenses/core/utils/currency_util.dart';
import 'package:gestion_depenses/exception/monthly_salary_not_found_exception.dart';
import 'package:gestion_depenses/features/expense/widgets/edit_modal.dart';
import 'package:gestion_depenses/features/home/widgets/budget_stat_card.dart';
import 'package:gestion_depenses/features/home/widgets/home_page_header.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/features/expense/widgets/card.dart';
import 'package:gestion_depenses/features/home/widgets/salary_form.dart';
// import 'package:gestion_depenses/features/home/widgets/stat_card.dart';
import 'package:gestion_depenses/models/category.dart';
import 'package:gestion_depenses/models/daily_budget_situation.dart';
import 'package:gestion_depenses/models/expense.dart';
import 'package:gestion_depenses/models/monthly_budget_situation.dart';
import 'package:gestion_depenses/services/budget_service.dart';
import 'package:gestion_depenses/services/budget_cycle_service.dart';
import 'package:gestion_depenses/services/category_service.dart';
import 'package:gestion_depenses/services/expense_service.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToExpense;
  const HomePage({required this.onNavigateToExpense, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoading = false;
  String date = "";

  // final _formatAr = CurrencyUtil.getFormater();

  final List<Expense> _expenses = [];

  final GlobalKey<AnimatedListState> _expenseListKey =
      GlobalKey<AnimatedListState>();

  final List<Category> _categories = [];

  MonthlyBudgetSituation? _monthlySituation;

  DailyBudgetSituation? _situation;
  String _message = "";
  bool _isCheckingSalary = false;
  Timer? _cycleBoundaryTimer;
  int _cycleCheckGeneration = 0;

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getAllCategories();
      setState(() {
        _categories.clear();
        _categories.addAll(categories);
      });
    } catch (e) {
      debugPrint(
        "Une erreur est survenue lors du chargement des catégories: $e",
      );
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    DateTime today = DateTime.now();
    try {
      final expenses = await ExpenseService.getListExpenseByDate(today);

      setState(() {
        _expenses.clear();
        _expenses.addAll(expenses);
      });
    } catch (e) {
      debugPrint('Erreur chargement des dépenses : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExpense(Expense expense, int index) async {
    try {
      await ExpenseService.deleteExpense(expense);

      if (index >= _expenses.length) {
        return;
      }

      final removedExpense = _expenses.removeAt(index);

      _expenseListKey.currentState?.removeItem(index, (context, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: ExpenseCard(expense: removedExpense, onDelete: () {}),
          ),
        );
      }, duration: const Duration(milliseconds: 300));

      setState(() {});
    } catch (e) {
      debugPrint('Erreur suppression dépense : $e');
    }
  }

  Future<void> _initDate() async {
    date = await DatetimeUtil.getDate();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showEditModal(BuildContext context, Expense expense) async {
    final bool? modified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EditModal(categories: _categories, expense: expense);
      },
    );

    if (modified == true) {
      await _loadExpenses();
    }
  }

  Future<void> _checkMonthlySalary() async {
    if (_isCheckingSalary) return;
    _isCheckingSalary = true;
    try {
      final period = await BudgetCycleService.getCurrentPeriod();
      try {
        final situation = await BudgetService.getSituationForPeriod(period);

        if (!mounted) return;

        setState(() {
          _monthlySituation = situation;
        });
      } on MonthlySalaryNotFoundException {
        if (!mounted) return;

        final bool? saved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return SalaryForm(period: period);
          },
        );

        if (saved == true && mounted) {
          final situation = await BudgetService.getSituationForPeriod(period);

          if (!mounted) return;

          setState(() {
            _monthlySituation = situation;
          });
        }
      }
    } catch (e) {
      debugPrint(
        "Une erreur est survenue lors de la vérification du cycle budgétaire : $e",
      );
    } finally {
      _isCheckingSalary = false;
    }
  }

  Future<void> _scheduleCycleBoundaryCheck() async {
    final generation = ++_cycleCheckGeneration;
    _cycleBoundaryTimer?.cancel();
    try {
      final period = await BudgetCycleService.getCurrentPeriod();
      if (!mounted || generation != _cycleCheckGeneration) return;
      final delay = period.endDate.difference(DateTime.now());
      _cycleBoundaryTimer = Timer(
        delay.isNegative ? Duration.zero : delay,
        _refreshCycleAndSalary,
      );
    } catch (error) {
      debugPrint('Impossible de planifier le contrôle du cycle : $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCycleAndSalary();
    }
  }

  Future<void> _refreshCycleAndSalary() async {
    try {
      await BudgetCycleService.initialize();
    } catch (error) {
      debugPrint('Erreur lors de l’actualisation du cycle : $error');
    }
    if (!mounted) return;
    await _checkMonthlySalary();
    if (mounted) await _scheduleCycleBoundaryCheck();
  }

  Future<void> _loadDailySituation() async {
    DateTime today = DateTime.now();
    try {
      final situation = await BudgetService.getDailySituation(today);
      setState(() {
        _situation = situation;
      });
    } on DailyBudgetNotFound catch (e) {
      setState(() {
        _message = "$e";
      });
    } catch (e) {
      debugPrint(
        "Une erreur est survenue lors de la recuperation de la situation du budget quotidien dans la page home: $e",
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkMonthlySalary();
    _scheduleCycleBoundaryCheck();

    _initDate();
    _loadExpenses();
    _loadCategories();
    _loadDailySituation();
  }

  @override
  Widget build(BuildContext context) {
    // final totalDepense = ExpenseService.sumExpenseAmount(_expenses);

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.colors.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomePageHeader(
                      title: "Bonjour",
                      date: date,
                      montlySituation: _monthlySituation,
                    ),
                    const SizedBox(height: 20),
                    // Text(
                    //   'Vue d’ensemble',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w700,
                    //     color: AppTheme.colors.text,
                    //   ),
                    // ),
                    // const SizedBox(height: 14),
                    // SizedBox(
                    //   height: 170,
                    //   child: ListView(
                    //     scrollDirection: Axis.horizontal,
                    //     padding: EdgeInsets.zero,
                    //     children: [
                    //       SizedBox(
                    //         width: 230,
                    //         child: StatCard(
                    //           title: 'Dépenses totales',
                    //           mainContent: _formatAr.format(totalDepense),
                    //           icon: Icons.payments_outlined,
                    //           accentColor: AppTheme.colors.primary,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       SizedBox(
                    //         width: 180,
                    //         child: StatCard(
                    //           title: 'Transactions',
                    //           mainContent: _expenses.length.toString(),
                    //           icon: Icons.receipt_long_outlined,
                    //           accentColor: AppTheme.colors.secondary,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    BudgetStatCard(situation: _situation, message: _message),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dépenses d'ajourd'hui",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colors.text,
                          ),
                        ),
                        if (_expenses.isNotEmpty)
                          Text(
                            '${_expenses.length} éléments',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_expenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.colors.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius.lg,
                          ),
                          border: Border.all(color: AppTheme.colors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 40,
                              color: AppTheme.colors.textMuted,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Aucune dépense enregistrée pour aujourd\'hui',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.colors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ajoutez une nouvelle dépense pour suivre votre budget.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      AnimatedList(
                        key: _expenseListKey,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        initialItemCount: _expenses.length,
                        itemBuilder:
                            (
                              BuildContext context,
                              int index,
                              Animation<double> animation,
                            ) {
                              final expense = _expenses[index];

                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  child: ExpenseCard(
                                    expense: expense,
                                    onDelete: () async {
                                      await _deleteExpense(expense, index);
                                      await _loadDailySituation();
                                    },
                                    onEdit: () async {
                                      await _showEditModal(context, expense);
                                      await _loadExpenses();
                                      await _loadDailySituation();
                                    },
                                  ),
                                ),
                              );
                            },
                      ),
                  ],
                ),
              ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppTheme.colors.primary,
      //   foregroundColor: AppTheme.colors.primarySoft,
      //   onPressed: () async {
      //     // widget.onNavigateToExpense.call();
      //     await NotificationService.instance.showNotification(
      //       title: "SpendWise",
      //       body: "Test de notification",
      //     );
      //   },
      //   child: Icon(Icons.add),
      // ),
    );
  }

  @override
  void dispose() {
    _cycleCheckGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _cycleBoundaryTimer?.cancel();
    super.dispose();
  }
}
