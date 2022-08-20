import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models.dart';
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

    _debts = await DatabaseHelper.instance.fetchDebts();

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

  Widget buildDebtList() => NotificationListener<UserScrollNotification>(
    onNotification: (notification) {
      if (notification.direction == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      } else if (notification.direction == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      }
      return true;
    },
    child: ListView.builder(itemCount: _debts.length, itemBuilder: (context, index) {
      Debt debt = _debts[index];
      return Card(
        elevation: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.paid)
              ),
              title: Text(
                debt.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${debt.date.year}/${debt.date.month}/${debt.date.day}'),
                trailing: FutureBuilder(
                  future: DatabaseHelper.instance.fetchDebtTotal(debtId: debt.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text('${(snapshot.data as double).toStringAsFixed(2)} PLN');
                    }
                    
                    return const Text('Loading...');
                  },
                ),
                onTap: () {
                  // navigate to debt page
                },
            )
          ],
        )
      );
    }),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _loading ? const CircularProgressIndicator() : (_debts.isEmpty ? const Text('There are no debts') : Expanded(child: buildDebtList())),
          ],
        ),
      ),
      floatingActionButton: _isFabVisible ? FloatingActionButton(
        onPressed: onFabClick,
        tooltip: 'Record debt',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
