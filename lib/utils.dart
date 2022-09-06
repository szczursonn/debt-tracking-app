import 'package:debt_tracking_app/models.dart';

const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
]; 

class Utils {

  static String formatDate (DateTime dt) {

    String day = dt.day.toString();

    String month = _months[dt.month-1];

    String year = dt.year.toString();

    return '$day $month $year';
  }

  static int sumDebtors(Iterable<Debtor> debtors) {
    return debtors.map((e) => e.amount).fold(0, (value, element) => value+=element);
  }
}