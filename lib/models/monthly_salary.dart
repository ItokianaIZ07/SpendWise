class MonthlySalary {
  int? id;
  final DateTime periodStart;
  double amount;

  MonthlySalary({this.id, required this.periodStart, required this.amount});

  int get month => periodStart.month;
  int get year => periodStart.year;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_start': _dateString(periodStart),
      'amount': amount,
    };
  }

  factory MonthlySalary.fromMap(Map<String, dynamic> map) {
    return MonthlySalary(
      id: map["id"],
      periodStart: DateTime.parse(map["period_start"] as String),
      amount: map["amount"],
    );
  }

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
