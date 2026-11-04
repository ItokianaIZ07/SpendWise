class MonthlySalaryNotFoundException implements Exception {
  final int month;
  final int year;

  MonthlySalaryNotFoundException(this.month, this.year);

  @override
  String toString() {
    return 'Aucun salaire enregistré pour le cycle commençant en $month/$year';
  }
}
