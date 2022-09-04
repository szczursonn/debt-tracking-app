import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/pages/user_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:debt_tracking_app/widgets/debt_icon.dart';
import 'package:debt_tracking_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../utils.dart';

class DebtPage extends StatefulWidget {
  const DebtPage({Key? key, required this.debtId}) : super(key: key);

  final int debtId;

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {

  void onEditClick() async {
    throw UnimplementedError();
  }

  Widget buildDebtorList(List<Debtor> debtors) => ListView.builder(itemCount: debtors.length, itemBuilder: (builder, i) {
    var debtor = debtors[i];
    return Selector<UserProvider, User>(
      selector: (context, provider) => provider.getUser(debtor.userId)!,
      builder: (context, user, _) => InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(userId: user.id))),
        child: Card(
          child: ListTile(
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            leading: UserAvatar(user: user),
            trailing: Consumer<SettingsProvider>(
              builder: (context, value, _) => Text('${(debtor.amount/100).toStringAsFixed(2)}${value.currency}')
            )
          ),
        ),
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    return Selector<DebtProvider, Debt>(
      selector: (context, provider) => provider.getDebt(widget.debtId)!,
      builder: (context, debt, _) => Scaffold(
        appBar: AppBar(
          title: Text(debt.title),
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
                const DebtIcon(radius: 56),
                const SizedBox(height: 12),
                Text(debt.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Container(margin: const EdgeInsets.only(left: 10, right: 10), child: Text(debt.description ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Text(Utils.formatDate(debt.date)),
                const SizedBox(height: 8),
                Selector<DebtProvider, List<Debtor>>(
                  selector: (context, provider) => provider.getDebtDebtors(debt.id),
                  builder: (context, debtors, _) => Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<SettingsProvider>(
                          builder: (context, value, _) => Text('Total: ${(Utils.sumDebtors(debtors)/100).toStringAsFixed(2)}${value.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                        ),
                        const Divider(color: Colors.black),
                        Expanded(child: buildDebtorList(debtors))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
