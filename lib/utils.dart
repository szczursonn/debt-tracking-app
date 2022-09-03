class Utils {

  static String formatDate (DateTime dt) {

    String day = dt.day.toString();
    if (day.length == 1) day='0$day';

    String month = dt.month.toString();
    if (month.length == 1) month='0$month';

    String year = dt.year.toString().substring(2);

    return '$day/$month/$year';
  }
}