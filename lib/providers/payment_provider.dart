import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PaymentProvider extends ChangeNotifier {
  Map<int, Map<int, Payment>> _paymentsByUserId = {};
  bool _loading = false;

  bool get loading => _loading;

  List<HistoryListItem> getUserPaymentsIdsWithDates(int userId) => _paymentsByUserId[userId]?.entries.map((e) => HistoryListItem(id: e.key, date: e.value.date, type: HistoryListItemType.payment)).toList() ?? [];

  int getUserPaymentsTotal(int userId) => _paymentsByUserId[userId]?.values.map((e)=>e.amount).fold(0, (value, element) => value == null ? value=element : value+=element) ?? 0;

  Payment? getPayment(int userId, int paymentId) => _paymentsByUserId[userId]?[paymentId];

  Future<void> createPayment({required int userId, String? description, required int amount, required DateTime date}) async {
    Payment payment = await DatabaseHelper.instance.createPayment(userId: userId, description: description, amount: amount, date: date);
    if (_paymentsByUserId[userId] == null) _paymentsByUserId[userId] = {};
    _paymentsByUserId[userId]![payment.id] = payment;

    notifyListeners();
  }

  Future<void> updatePayment(Payment payment) async {
    var updated = await DatabaseHelper.instance.updatePayment(payment);
    if (_paymentsByUserId[updated.userId] == null) _paymentsByUserId[updated.userId] = {};
    _paymentsByUserId[updated.userId]![payment.id] = payment;

    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    var payments = await DatabaseHelper.instance.fetchAllPayments();
    
    _paymentsByUserId = {};
    for (var payment in payments) {
      if (_paymentsByUserId[payment.userId] == null) _paymentsByUserId[payment.userId] = {};
      _paymentsByUserId[payment.userId]![payment.id] = payment;
    }

    _loading = false;

    notifyListeners();
  }
}