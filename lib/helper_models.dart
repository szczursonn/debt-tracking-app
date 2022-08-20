import 'models.dart';

class DebtViewData {
  final Debt debt;
  final List<DebtorUser> debtors;

  DebtViewData({required this.debt, required this.debtors});
}

class DebtorUser {
  final int amount;
  final User user;

  DebtorUser({required this.amount, required this.user});
}