import 'package:debt_tracking_app/pages/payment_create_page.dart';
import 'package:debt_tracking_app/providers/payment_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:debt_tracking_app/widgets/are_you_sure_dialog.dart';
import 'package:debt_tracking_app/widgets/payment_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key, required this.userId, required this.paymentId}) : super(key: key);

  final int userId;
  final int paymentId;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum _Menu {edit, remove}

class _PaymentPageState extends State<PaymentPage> {

  bool _removing = false;

  void _removePayment() async {
    setState(() => _removing=true);

    var provider = Provider.of<PaymentProvider>(context, listen: false);
    await provider.removePayment(userId: widget.userId, paymentId: widget.paymentId);
    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> _openRemoveDialog() {
    return showDialog(context: context, builder: (context) => AreYouSureDialog(
      title: 'Are you sure?',
      content: const Text('Are you sure you want to delete this user?'),
      onYes: _removePayment
    ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_removing) Navigator.pop(context);

        return false;
      },
      child: Selector<PaymentProvider, Payment?>(
        selector: (context, provider) => provider.getPayment(widget.userId, widget.paymentId),
        builder: (context, payment, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Payment'),
            actions: [
              PopupMenuButton(
                enabled: (!_removing && payment != null),
                onSelected: (_Menu item) {
                    switch (item) {
                      case _Menu.edit:
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentCreatePage(userId: widget.userId, editedPaymentId: widget.paymentId)));
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
          body: payment == null ? Text('Error: no payment with id ${widget.paymentId} on user id ${widget.userId}', style: TextStyle(color: Theme.of(context).errorColor)) : Container(
            margin: const EdgeInsets.all(12),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const PaymentIcon(radius: 56),
                  const SizedBox(height: 12),
                  const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                  const SizedBox(height: 8),
                  payment.description == null ? Container() : Text(payment.description!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Consumer<SettingsProvider>(
                    builder: (context, value, _) => Text('${(payment.amount/100).toStringAsFixed(2)} ${value.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                  ),
                  const SizedBox(height: 8),
                  Text(Utils.formatDate(payment.date), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}