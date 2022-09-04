import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/models.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebtProvider extends ChangeNotifier {
  Map<int, Debt> _debtsById = {};
  Map<int, List<Debtor>> _debtorsByUserId = {};
  Map<int, List<Debtor>> _debtorsByDebtId = {};
  bool _loading = false;

  bool get loading => _loading;

  List<HistoryListItem> getDebtsIdsWithDates() => _debtsById.entries.map((e) => HistoryListItem(id: e.key, date: e.value.date, type: HistoryListItemType.debt)).toList();

  List<HistoryListItem> getUserDebtsIdsWithDates(int userId) => _debtorsByUserId[userId]?.map((e) => HistoryListItem(id: e.debtId, date: _debtsById[e.debtId]!.date, type: HistoryListItemType.debt)).toList() ?? [];

  Debtor getDebtor({required int userId, required int debtId}) => _debtorsByDebtId[debtId]!.where((e)=>e.userId==userId).first;

  List<Debtor> getDebtDebtors(int debtId) => _debtorsByDebtId[debtId]!;

  int getUserTotalOwedAmount(int userId) => Utils.sumDebtors(_debtorsByUserId[userId]?? []);

  Debt? getDebt(int debtId) => _debtsById[debtId];

  Future<void> createDebt({required String title, String? description, required Map<int, double> userAmounts, required DateTime date}) async {
    Debt debt = await DatabaseHelper.instance.createDebt(
      title: title,
      description: description,
      userAmounts: userAmounts,
      date: date
    );
    _debtsById[debt.id] = debt;
    var debtors = userAmounts.entries.map((e)=>Debtor(debtId: debt.id, userId: e.key, amount: (e.value*100).round())).toList();
    _debtorsByDebtId[debt.id] = debtors;
    for (var debtor in debtors) {
      if (_debtorsByUserId[debtor.userId] == null) _debtorsByUserId[debtor.userId] = [];
      _debtorsByUserId[debtor.userId]!.add(debtor);
    }

    notifyListeners();
  }

  Future<void> updateDebt(Debt debt, Map<int, double> userAmounts) async {
    throw UnimplementedError();

    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    var debts = await DatabaseHelper.instance.fetchAllDebts();
    _debtsById = {};
    for (var debt in debts) {
      _debtsById[debt.id] = debt;
    }

    var debtors = await DatabaseHelper.instance.fetchAllDebtors();
    _debtorsByUserId = {};
    for (var debtor in debtors) {
      if (_debtorsByUserId[debtor.userId] == null) _debtorsByUserId[debtor.userId] = [];
      _debtorsByUserId[debtor.userId]!.add(debtor);
    }
    _debtorsByDebtId = {};
    for (var debtor in debtors) {
      if (_debtorsByDebtId[debtor.debtId] == null) _debtorsByDebtId[debtor.debtId] = [];
      _debtorsByDebtId[debtor.debtId]!.add(debtor);
    }

    _loading = false;

    notifyListeners();
  }
}