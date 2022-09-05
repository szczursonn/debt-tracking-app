import 'package:debt_tracking_app/pages/debt_create_page.dart';
import 'package:debt_tracking_app/pages/debt_page.dart';
import 'package:debt_tracking_app/pages/payment_create_page.dart';
import 'package:debt_tracking_app/pages/payment_page.dart';
import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/providers/payment_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:debt_tracking_app/widgets/debt_icon.dart';
import 'package:debt_tracking_app/widgets/payment_icon.dart';
import 'package:debt_tracking_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper_models.dart';
import '../models.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key, required this.userId}) : super(key: key);

  final int userId;

  @override
  State<UserPage> createState() => _UserPageState();
}

enum _Menu {edit, remove}

class _UserPageState extends State<UserPage> {

  void onAddDebtClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => DebtCreatePage(initialUserId: widget.userId)));
  }

  void onAddPaymentClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentCreatePage(userId: widget.userId)));
  }

  Widget buildHistory(List<HistoryListItem> items) {
    List<List<HistoryListItem>> groups = [];

    DateTime? prevDate;
    int index = -1;

    var sortedItems = [...items];
    sortedItems.sort((a,b) => a.date.compareTo(b.date));

    for (var item in sortedItems) {
      if (prevDate != null && item.date.day == prevDate.day && item.date.month == prevDate.month && item.date.year == prevDate.year) {
        groups[index].add(item);
      } else {
        index+=1;
        groups.add([item]);
      }
      prevDate = item.date;
    }

    groups = groups.reversed.toList();
    
    return ListView.builder(
      itemCount: groups.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (builder, i) {
        var group = groups[i];
        DateTime date = group.first.date;
    
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, left: 12, bottom: 4),
                child: Text(
                  Utils.formatDate(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17
                  )
                ),
              ),
              const Divider(thickness: 3),
              Column(
                children: group.map(buildItem).toList(),
              )
            ],
          ),
        );
      }
    );
  }

  Widget buildItem(HistoryListItem item) {

    String currency = Provider.of<SettingsProvider>(context).currency;

    switch (item.type) {
      case HistoryListItemType.debt:
        return Selector<DebtProvider, Debt?>(
          selector: (context, provider) => provider.getDebt(item.id),
          builder: (context, debt, _) => debt == null ? Container() : InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DebtPage(debtId: debt.id))),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    debt.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3
                  ),
                  subtitle: debt.description == null ? null : Text(debt.description!, overflow: TextOverflow.ellipsis, maxLines: 2),
                  leading: const DebtIcon(),
                  trailing: Selector<DebtProvider, int?>(
                    selector: (context, provider) => provider.getDebtor(userId: widget.userId, debtId: item.id)?.amount,
                    builder: (context, amount, _) => amount == null
                    ? Text('err', style: TextStyle(color: Theme.of(context).errorColor))
                    : Text('-${(amount/100).toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red))
                  ),
                ),
              ],
            )
          ),
        );
      case HistoryListItemType.payment:
        return Selector<PaymentProvider, Payment?>(
          selector: (context, provider) => provider.getPayment(widget.userId, item.id),
          builder: (context, payment, _) => payment == null ? Container() : InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(userId: widget.userId, paymentId: item.id))),
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Payment',
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: payment.description == null ? null : Text(payment.description!, overflow: TextOverflow.ellipsis, maxLines: 2),
                  leading: const PaymentIcon(),
                  trailing: Text('+${(payment.amount/100).toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                ),
              ],
            )
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<UserProvider, User?>(
      selector: (context, provider) => provider.getUser(widget.userId),
      builder: (context, user, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(user == null ? 'invalid user' : user.name),
            actions: [
              PopupMenuButton(
                enabled: user != null,
                onSelected: (_Menu item) {
                  switch (item) {
                    case _Menu.edit:
                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserCreatePage(editedUserId: widget.userId)));
                      break;
                    case _Menu.remove:
                      break;
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<_Menu>>[
                  PopupMenuItem(
                    value: _Menu.edit,
                    child: Row(
                      children: const [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    enabled: false,
                    value: _Menu.remove,
                    child: Row(
                      children: const [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Remove')
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
          body: user == null
          ? Text('Error: no user with id ${widget.userId}', style: TextStyle(color: Theme.of(context).errorColor))
          : SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAvatar(user: user, radius: 56),
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                  Selector2<DebtProvider, PaymentProvider, int>(
                    selector: (context, debtProvider, paymentProvider) => paymentProvider.getUserPaymentsTotal(widget.userId)-debtProvider.getUserTotalOwedAmount(widget.userId),
                    builder: (context, bal, _) => Consumer<SettingsProvider>(
                      builder: (context, value, _) => Text('${(bal/100).toStringAsFixed(2)} ${value.currency}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: (bal >= 0 ? Colors.green : Colors.red)))
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(onPressed: onAddDebtClick, child: const Text('Add debt')),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: onAddPaymentClick, child: const Text('Register payment')),
                    ],
                  ),
                  const Divider(color: Colors.black),
                  const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Selector2<PaymentProvider, DebtProvider, List<HistoryListItem>>(
                    selector: (context, paymentProvider, debtProvider) {
                      var payments = paymentProvider.getUserPaymentsIdsWithDates(widget.userId);
                      var debts = debtProvider.getUserDebtsIdsWithDates(widget.userId);
                      return [...payments, ...debts];
                    },
                    builder: (context, items, _) => buildHistory(items),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
