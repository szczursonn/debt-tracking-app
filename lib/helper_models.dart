import 'models.dart';

class DebtorUser {
  final int amount;
  final User user;

  DebtorUser({required this.amount, required this.user});
}

class UserBalance {
  final int owed;
  final int paid;

  UserBalance({required this.owed, required this.paid});
}
