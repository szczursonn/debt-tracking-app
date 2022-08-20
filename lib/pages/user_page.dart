import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:debt_tracking_app/pages/debt_create_page.dart';
import 'package:debt_tracking_app/pages/payment_create_page.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late List<Debt> _debts;
  bool _loading = false;

  void loadDebts() async {
    setState(() => _loading = true);

    var debts = await DatabaseHelper.instance.fetchUserDebts(widget.user.id);
    _debts = debts;

    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  void onAddDebtClick() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => DebtCreatePage(initialUser: widget.user,)));
    if (res is Debt) {
      _debts.add(res);
    }
  }

  void onAddPaymentClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentCreatePage(user: widget.user)));
  }

  Widget buildHistory() => ListView.builder(itemCount: _debts.length, itemBuilder: (builder, i) {
    var debt = _debts[i];
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              debt.title,
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.paid)
            ),
            trailing: FutureBuilder(
              future: DatabaseHelper.instance.fetchUserDebtTotal(userId: widget.user.id, debtId: debt.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Total: ${(snapshot.data as double).toStringAsFixed(2)}');
                } else {
                  return const Text('loading...');
                }
              },
            ),
          ),
        ],
      )
    );
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {

        Navigator.pop(context, true);

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user.name),
        ),
        body: Container(
          margin: const EdgeInsets.only(
            top: 24
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 48,
                    child: Text('XD')
                ),
                const SizedBox(height: 4),
                Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: onAddDebtClick, child: const Text('Add debt')),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: onAddPaymentClick, child: const Text('Register payment')),
                  ],
                ),
                const Divider(color: Colors.black),
                const Text('History'),
                _loading ? const CircularProgressIndicator() : Expanded(child: buildHistory())
              ],
            ),
          ),
        ),
      ),
    );
  }
}
