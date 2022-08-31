import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/widgets/UserAvatar.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({Key? key, required this.debt}) : super(key: key);

  final Debt debt;

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  late List<DebtorUser> _debtors;
  bool _loading = false;

  void loadDebts() async {
    setState(() => _loading = true);

    _debtors = await DatabaseHelper.instance.fetchDebtors(widget.debt.id);

    setState(() => _loading = false);
  }

  void onEditClick() async {
    
  }

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  Widget buildDebtorList() => ListView.builder(itemCount: _debtors.length, itemBuilder: (builder, i) {
    var debtor = _debtors[i];
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              debtor.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            leading: UserAvatar(user: debtor.user),
            trailing: Text('${(debtor.amount/100).toStringAsFixed(2)} PLN')
          ),
        ],
      )
    );
  });

  int getTotal() {
    return _debtors.map((e) => e.amount).reduce((value, element) => value+=element);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.debt.title),
          actions: [
            IconButton(
              onPressed: onEditClick, 
              icon: const Icon(Icons.edit)
            )
          ],
        ),
        body: Container(
          margin: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.debt.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Container(margin: const EdgeInsets.only(left: 10, right: 10), child: Text(widget.debt.description ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(height: 8),
                _loading ? const Text('loading...') : Text('Total: ${(getTotal()/100).toStringAsFixed(2)} PLN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const Divider(color: Colors.black),
                _loading ? const CircularProgressIndicator() : Expanded(child: buildDebtorList())
              ],
            ),
          ),
        ),
      ),
    );
  }
}
