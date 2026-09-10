import 'package:intl/intl.dart';

/// Formate un montant selon la devise active.
/// Architecture prête pour supporter d'autres devises plus tard
/// (il suffira de changer [symbol] et [decimalDigits] depuis les paramètres).
class CurrencyFormatter {
  static String symbol = 'FCFA';
  static int decimalDigits = 0;

  static String format(num amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    formatter.minimumFractionDigits = decimalDigits;
    formatter.maximumFractionDigits = decimalDigits;
    return '${formatter.format(amount)} $symbol';
  }

  static String formatSigned(num amount, {required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount.abs())}';
  }
}

class DateFormatter {
  static String short(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  static String long(DateTime date) =>
      DateFormat('dd MMMM yyyy', 'fr_FR').format(date);

  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'fr_FR').format(date);
}
