import 'package:debt_tracking_app/pages/debt_create_page.dart';
import 'package:debt_tracking_app/pages/user_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:debt_tracking_app/widgets/are_you_sure_dialog.dart';
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

enum _Menu {edit, remove}

class _DebtPageState extends State<DebtPage> {

  bool _removing = false;

  void _removeDebt() async {
    setState(() => _removing=true);

    var provider = Provider.of<DebtProvider>(context, listen: false);
    try {
      await provider.removeDebt(widget.debtId);
      if (!mounted) return;

      Navigator.pop(context);
    } catch (err) {
      setState(() => _removing=false);
    }
  }

  Future<void> _openRemoveDialog() {
    return showDialog(context: context, builder: (context) => AreYouSureDialog(
      title: 'Are you sure?',
      content: RichText(
        text: TextSpan(
          children: [
            const TextSpan(text: 'Are you sure you want to remove this debt?'),
            const TextSpan(text: '\n\n'),
            TextSpan(text: 'This will remove this debt from EVERY user.\n', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).errorColor)),
            const TextSpan(text: 'If you want to remove this debt from a specific user/users, use the edit option.')
          ]
        ),
      ),
      onYes: _removeDebt
    ));
  }

  Widget buildDebtorList(List<Debtor> debtors) => ListView.builder(
    itemCount: debtors.length,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (builder, i) {
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
                builder: (context, value, _) => Text('${(debtor.amount/100).toStringAsFixed(2)} ${value.currency}')
              )
            ),
          ),
        ),
      );
    }
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_removing) Navigator.pop(context);

        return false;
      },
      child: Selector<DebtProvider, Debt?>(
        selector: (context, provider) => provider.getDebt(widget.debtId),
        builder: (context, debt, _) => Scaffold(
          appBar: AppBar(
            title: Text(debt?.title ?? 'invalid debtId'),
            actions: [
              PopupMenuButton(
                enabled: (!_removing && debt != null),
                onSelected: (_Menu item) {
                    switch (item) {
                      case _Menu.edit:
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DebtCreatePage(editedDebtId: widget.debtId)));
                        break;
                      case _Menu.remove:
                        _openRemoveDialog();
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
                    value: _Menu.remove,
                    child: Row(
                      children: const [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Remove')
                      ],
                    ),
                  )
                ]
              )
            ],
          ),
          body: debt == null ?
          Text('Error: no debt with id ${widget.debtId}', style: TextStyle(color: Theme.of(context).errorColor))
          : SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DebtIcon(radius: 56),
                    const SizedBox(height: 12),
                    Text(debt.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                    Text(Utils.formatDate(debt.date)),
                    debt.description == null ? Container() : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Text(debt.description ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 4),
                    Selector<DebtProvider, List<Debtor>>(
                      selector: (context, provider) => provider.getDebtDebtors(debt.id),
                      builder: (context, debtors, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<SettingsProvider>(
                            builder: (context, value, _) => Text('Total: ${(Utils.sumDebtors(debtors)/100).toStringAsFixed(2)}${value.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                          ),
                          const Divider(color: Colors.black),
                          Text('Debtors (${debtors.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          buildDebtorList(debtors)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
