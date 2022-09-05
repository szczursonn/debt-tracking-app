import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/pages/debt_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:debt_tracking_app/widgets/debt_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/settings_provider.dart';
import 'debt_create_page.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({Key? key}) : super(key: key);

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {

  bool _isFabVisible = true;

  Future<void> onFabClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtCreatePage()));
  }

  Widget buildDebtList(List<HistoryListItem> items) {
    List<List<HistoryListItem>> groups = [];

    DateTime? prevDate;
    int index = -1;

    for (var item in items) {
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
      itemBuilder: (context, index) {
        var groupItems = groups[index];
        DateTime date = groupItems.first.date;

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
                  ),
                ),
              ),
              const Divider(thickness: 3),
              Column(
                children: groupItems.map((item) => Selector<DebtProvider, Debt?>(
                  selector: (context, provider) => provider.getDebt(item.id),
                  builder: (context, debt, _) => InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DebtPage(debtId: item.id))),
                    child: Column(
                      children: [
                        debt == null
                        ? ListTile(
                          title: Text('error: no debt with id ${item.id}', style: TextStyle(color: Theme.of(context).errorColor)),
                          leading: const DebtIcon(),
                        )
                        : ListTile(
                          title: Text(debt.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: debt.description == null ? null : Text(debt.description!, overflow: TextOverflow.ellipsis, maxLines: 2),
                          leading: const DebtIcon(),
                          trailing: Selector<DebtProvider, int>(
                            selector: (context, provider) => Utils.sumDebtors(provider.getDebtDebtors(item.id)),
                            builder: (context, total, _) => Consumer<SettingsProvider>(
                              builder: (context, value, _) => Text(
                                '${(total/100).toStringAsFixed(2)} ${value.currency}',
                                style: const TextStyle(
                                  fontSize: 16
                                ),
                              )
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )).toList(),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DebtProvider, List<HistoryListItem>>(
      selector: (context, provider) => provider.getDebtsIdsWithDates(),
      builder: (context, items, _) => Scaffold(
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.forward && !_isFabVisible) {
              setState(() => _isFabVisible = true);
            } else if (notification.direction == ScrollDirection.reverse && _isFabVisible) {
              setState(() => _isFabVisible = false);
            }
            return true;
          },
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  items.isEmpty ? const Text('There are no debts') : Expanded(child: buildDebtList(items)),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _isFabVisible ? FloatingActionButton(
          onPressed: onFabClick,
          tooltip: 'Record debt',
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
}
