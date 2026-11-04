import 'package:flutter/material.dart';
import 'package:gestion_depenses/core/themes/app_theme.dart';
import 'package:gestion_depenses/core/utils/currency_util.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/exception/monthly_salary_not_found_exception.dart';
import 'package:gestion_depenses/models/monthly_budget_situation.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/services/budget_service.dart';
import 'package:gestion_depenses/services/budget_cycle_service.dart';

class FinancialDetailPage extends StatefulWidget {
  const FinancialDetailPage({super.key});

  @override
  State<FinancialDetailPage> createState() => _FinancialDetailPageState();
}

class _FinancialDetailPageState extends State<FinancialDetailPage> {
  MonthlyBudgetSituation? _monthlySituation;
  BudgetPeriod? _period;
  bool _isLoading = true;
  String? _errorMessage;
  final _currency = CurrencyUtil.getFormater();

  @override
  void initState() {
    super.initState();
    _loadMonthlySituation();
  }

  Future<void> _loadMonthlySituation() async {
    try {
      final period = await BudgetCycleService.getCurrentPeriod();
      final situation = await BudgetService.getSituationForPeriod(period);

      if (!mounted) return;
      setState(() {
        _period = period;
        _monthlySituation = situation;
        _isLoading = false;
      });
    } on MonthlySalaryNotFoundException {
      setState(() {
        _errorMessage = 'Aucun salaire enregistré pour ce cycle.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les détails financiers.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        title: const Text(
          'Détails Financiers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_monthlySituation == null) {
      return const Center(child: Text('Aucune donnée disponible.'));
    }

    return _buildContent(_monthlySituation!);
  }

  Widget _buildContent(MonthlyBudgetSituation situation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(situation),
          const SizedBox(height: 22),
          _buildMetricCard(
            icon: Icons.payments_outlined,
            iconBackground: AppTheme.colors.primarySoft,
            iconColor: AppTheme.colors.primary,
            title: 'Salaire du cycle',
            value: _currency.format(situation.salary),
            valueColor: AppTheme.colors.primary,
          ),
          _buildMetricCard(
            icon: Icons.assignment_outlined,
            iconBackground: AppTheme.colors.primarySoft,
            iconColor: AppTheme.colors.primary,
            title: 'Budget total planifié',
            value: _currency.format(situation.plannedBudget),
            valueColor: AppTheme.colors.primary,
          ),
          _buildMetricCard(
            icon: Icons.savings_outlined,
            iconBackground: situation.availableBudget > 0
                ? AppTheme.colors.secondarySoft
                : AppTheme.colors.dangerSoft,
            iconColor: situation.availableBudget > 0
                ? AppTheme.colors.secondary
                : AppTheme.colors.danger,
            title: 'Budget réel disponible',
            value: _currency.format(situation.availableBudget),
            valueColor: situation.availableBudget >= 0
                ? AppTheme.colors.secondary
                : AppTheme.colors.danger,
          ),
          _buildMetricCard(
            icon: Icons.shopping_cart_outlined,
            iconBackground: AppTheme.colors.dangerSoft,
            iconColor: AppTheme.colors.danger,
            title: 'Dépenses réelles',
            value: _currency.format(situation.spent),
            valueColor: AppTheme.colors.danger,
            progress: situation.expenseRatio,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MonthlyBudgetSituation situation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.colors.primary,
            AppTheme.colors.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.radius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBubble(Icons.account_balance_wallet_outlined),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vue détaillée',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Du ${DatetimeUtil.formatDate(_period!.startDate)} '
                    'au ${DatetimeUtil.formatDate(_period!.endDate.subtract(const Duration(days: 1)))}',
                    style: const TextStyle(
                      color: Color(0xFFD5DDF1),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Reste Réel',
            style: TextStyle(color: Color(0xFFD5DDF1), fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            situation.remaining > 0
                ? _currency.format(situation.remaining)
                : "Vous avez dépensé tout votre salaire !",
            style: TextStyle(
              color: situation.remaining > 0
                  ? Color(0xFF72E5DB)
                  : AppTheme.colors.dangerSoft,
              fontSize: situation.remaining > 0 ? 32 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
    double? progress,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: AppTheme.radius.lgBorder,
        border: Border.all(color: AppTheme.colors.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBubble(icon, background: iconBackground, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.colors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.colors.primarySoft,
                valueColor: AlwaysStoppedAnimation(valueColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBubble(
    IconData icon, {
    Color background = const Color(0x335B7BC2),
    Color color = Colors.white,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
