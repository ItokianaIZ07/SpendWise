import 'package:flutter/material.dart';
import 'package:gestion_depenses/core/themes/app_theme.dart';
import 'package:gestion_depenses/core/utils/datetime_util.dart';
import 'package:gestion_depenses/features/settings/pages/about_page.dart';
import 'package:gestion_depenses/features/settings/pages/daily_budget_page.dart';
import 'package:gestion_depenses/features/settings/pages/salary_page.dart';
import 'package:gestion_depenses/features/settings/widgets/option_menu.dart';
import 'package:gestion_depenses/features/settings/widgets/renewal_day_setting.dart';
import 'package:gestion_depenses/services/expense_service.dart';
import 'category_list_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.colors.success),
              const SizedBox(width: 8),
              const Text('Succès'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer la dépense ?"),
          content: const Text(
            "Cette action est irréversible. Voulez-vous vraiment supprimer toutes les dépenses ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ExpenseService.deleteAllExpenses();
      if (context.mounted) {
        _showSuccessDialog(context, "Toutes les dépenses ont été supprimées.");
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.colors.textMuted.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPreferenceMenuList(BuildContext context) {
    return Column(
      children: [
        OptionMenu(
          context: context,
          icon: const Icon(Icons.category_outlined),
          title: "Catégories",
          screen: const CategoriesPage(),
        ),
        OptionMenu(
          context: context,
          icon: const Icon(Icons.payments_outlined),
          title: "Salaire",
          screen: const SalaryPage(),
        ),
        const RenewalDaySetting(),
        OptionMenu(
          context: context,
          icon: const Icon(Icons.monetization_on_outlined),
          title: "Budget",
          screen: const DailyBudgetPage(),
        ),
        OptionMenu(
          context: context,
          icon: const Icon(Icons.info_outline),
          title: "À propos",
          screen: const AboutPage(),
        ),
      ],
    );
  }

  Widget _buildDataMenuList(BuildContext context) {
    return Column(
      children: [
        _buildSettingButton(
          label: "Supprimer toutes les dépenses",
          icon: Icon(
            Icons.delete_outline_outlined,
            color: AppTheme.colors.danger,
          ),
          color: AppTheme.colors.danger.withValues(alpha: 0.85),
          onPush: () async => await _confirmDelete(context),
        ),
      ],
    );
  }

  Widget _buildSettingButton({
    required String label,
    Icon? icon,
    required VoidCallback onPush,
    Color? color,
  }) {
    return InkWell(
      onTap: () {
        onPush.call();
      },
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.colors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors.shadow.withValues(alpha: 0.20),
              offset: const Offset(0, 3),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color ?? AppTheme.colors.text,
              ),
            ),
            icon ?? Icon(Icons.do_not_disturb_alt),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Préférences"),
              _buildPreferenceMenuList(context),
              const SizedBox(height: 16),
              _buildSectionTitle("Données"),
              _buildDataMenuList(context),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "\u00A9 ${DatetimeUtil.getNowYear()} - SpendWise by ItokianaIZ07. Compte bien, dépense peu",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
