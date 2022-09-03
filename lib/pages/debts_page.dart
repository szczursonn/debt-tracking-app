import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/pages/debt_page.dart';
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
  late List<Debt> _debts;
  bool _loading = false;

  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  Future<void> loadDebts() async {
    setState(() => _loading = true);

    _debts = await DatabaseHelper.instance.fetchAllDebts();

    if (mounted) setState(() => _loading = false);
  }

  void onFabClick() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DebtCreatePage()))
      .then((value) {
        if (!mounted) return;
        if (value is Debt) {
          setState(() {
            _debts.add(value);
          });
        }
      });
  }

  Widget buildDebtList() {
    List<List<Debt>> groups = [];

    DateTime? prevDate;
    int index = -1;

    for (var item in _debts) {
      if (prevDate != null && item.date.day == prevDate.day && item.date.month == prevDate.month && item.date.year == prevDate.year) {
        groups[index].add(item);
      } else {
        index+=1;
        groups.add([item]);
      }
      prevDate = item.date;
    }

    groups = groups.reversed.toList();

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.forward && !_isFabVisible) {
          setState(() => _isFabVisible = true);
        } else if (notification.direction == ScrollDirection.reverse && _isFabVisible) {
          setState(() => _isFabVisible = false);
        }
        return true;
      },
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          var debts = groups[index];
          DateTime date = debts.first.date;

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
                  children: debts.map((debt) => InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => DebtPage(debt: debt)));
                    },
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(debt.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: debt.description == null ? null : Text(debt.description!, overflow: TextOverflow.ellipsis, maxLines: 2),
                          leading: const DebtIcon(),
                          trailing: FutureBuilder(
                            future: DatabaseHelper.instance.fetchDebtTotal(debtId: debt.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Consumer<SettingsProvider>(
                                  builder: (context, value, _) => Text(
                                    '${(snapshot.data as double).toStringAsFixed(2)} ${value.currency}',
                                    style: const TextStyle(
                                      fontSize: 16
                                    ),
                                  )
                                );
                              }
                              return const Text('Loading...');
                            },
                          ),
                        )
                      ],
                    ),
                  )).toList(),
                )
              ],
            ),
          );
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _loading ? const CircularProgressIndicator() : (_debts.isEmpty ? const Text('There are no debts') : Expanded(child: buildDebtList())),
            ],
          ),
        ),
      ),
      floatingActionButton: (_isFabVisible && !_loading) ? FloatingActionButton(
        onPressed: onFabClick,
        tooltip: 'Record debt',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
