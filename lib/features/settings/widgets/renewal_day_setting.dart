import 'package:flutter/material.dart';
import 'package:gestion_depenses/core/themes/app_theme.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/features/home/widgets/salary_form.dart';
import 'package:gestion_depenses/services/monthly_salary_service.dart';
import 'package:gestion_depenses/services/budget_cycle_service.dart';

class RenewalDaySetting extends StatefulWidget {
  const RenewalDaySetting({super.key});

  @override
  State<RenewalDaySetting> createState() => _RenewalDaySettingState();
}

class _RenewalDaySettingState extends State<RenewalDaySetting> {
  int? _renewalDay;
  DateTime? _nextRenewalDate;
  bool _isLoading = true;
  bool _isSaving = false;

  Future<void> _load() async {
    try {
      final renewalDay = await BudgetCycleService.getRenewalDay();
      final period = await BudgetCycleService.getCurrentPeriod();
      if (!mounted) return;
      setState(() {
        _renewalDay = renewalDay;
        _nextRenewalDate = period.getNextPeriod().startDate;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Erreur lors du chargement du renouvellement : $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectRenewalDay(int? day) async {
    if (day == null || day == _renewalDay || _isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recalculer les cycles budgétaires ?'),
        content: const Text(
          'Les périodes, dépenses, budgets et montants restants seront '
          'recalculés immédiatement selon ce nouveau jour. Les dates des '
          'dépenses ne seront pas modifiées. La modification sera bloquée '
          'si elle entre en conflit avec un salaire historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await BudgetCycleService.updateRenewalDay(day);
      final period = await BudgetCycleService.getCurrentPeriod();
      final salary = await MonthlySalaryService.getSalary(period);
      if (salary == null && mounted) {
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => SalaryForm(period: period),
        );
      }
      if (!mounted) return;
      setState(() {
        _renewalDay = day;
        _nextRenewalDate = period.getNextPeriod().startDate;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jour de renouvellement mis à jour.')),
      );
    } catch (error) {
      debugPrint('Erreur lors de la modification du cycle : $error');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modification impossible : $error'),
          backgroundColor: AppTheme.colors.danger,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: Icon(Icons.event_repeat),
        title: Text('Jour de renouvellement'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.event_repeat),
        title: const Text('Jour de renouvellement du salaire'),
        subtitle: Text(
          _nextRenewalDate == null
              ? 'Paramètre indisponible'
              : 'Prochain renouvellement : '
                    '${DatetimeUtil.formatDate(_nextRenewalDate!)}',
        ),
        trailing: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : DropdownButton<int>(
                value: _renewalDay,
                onChanged: _selectRenewalDay,
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('$day')),
                ],
              ),
      ),
    );
  }
}
