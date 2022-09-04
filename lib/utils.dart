import 'package:debt_tracking_app/models.dart';

class Utils {

  static String formatDate (DateTime dt) {

    String day = dt.day.toString();
    if (day.length == 1) day='0$day';

    String month = dt.month.toString();
    if (month.length == 1) month='0$month';

    String year = dt.year.toString().substring(2);

    return '$day/$month/$year';
  }

  static int sumDebtors(Iterable<Debtor> debtors) {
    return debtors.map((e) => e.amount).fold(0, (value, element) => value+=element);
  }
}