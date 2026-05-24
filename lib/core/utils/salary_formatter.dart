class SalaryFormatter {
  SalaryFormatter._();

  static String format(String? salary) {
    if (salary == null || salary.isEmpty) return '-';
    return salary;
  }
}
