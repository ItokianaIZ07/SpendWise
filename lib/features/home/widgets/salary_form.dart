import 'package:flutter/material.dart';
import 'package:gestion_depenses/core/themes/app_theme.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/models/budget_period.dart';
import 'package:gestion_depenses/models/monthly_salary.dart';
import 'package:gestion_depenses/services/monthly_salary_service.dart';

class SalaryForm extends StatefulWidget {
  final BudgetPeriod period;

  const SalaryForm({required this.period, super.key});

  @override
  State<SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends State<SalaryForm> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await MonthlySalaryService.saveSalary(
        MonthlySalary(
          periodStart: widget.period.startDate,
          amount: double.parse(_salaryController.text.replaceAll(',', '.')),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Enregistrement impossible : $error';
          _isSaving = false;
        });
      }
    }
  }

  String? _checkValue(double? value) {
    if (value == null) {
      return 'Veuillez entrer un montant valide';
    }

    if (value <= 0) {
      return 'Le salaire doit être supérieur à 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text(
          'Salaire du nouveau cycle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Période : ${DatetimeUtil.formatDate(widget.period.startDate)} '
                'au ${DatetimeUtil.formatDate(widget.period.endDate.subtract(const Duration(days: 1)))}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez renseigner votre salaire pour cette période.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _salaryController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  icon: const Icon(Icons.payments_rounded),
                  iconColor: AppTheme.colors.primary,
                  labelText: 'Salaire',
                  hintText: 'Exemple : 1500000',
                  suffixText: 'Ar',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez renseigner votre salaire';
                  }

                  final salary = double.tryParse(value.replaceAll(',', '.'));
                  return _checkValue(salary);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppTheme.colors.danger),
                ),
              ],
            ],
          ),
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
