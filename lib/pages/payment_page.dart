import 'package:debt_tracking_app/pages/payment_create_page.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:debt_tracking_app/widgets/payment_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key, required this.payment}) : super(key: key);

  final Payment payment;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  void onEditClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentCreatePage(userId: widget.payment.userId, editedPayment: widget.payment)));
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = widget.payment.date;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const PaymentIcon(radius: 56),
                const SizedBox(height: 12),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                const SizedBox(height: 8),
                widget.payment.description == null ? Container() : Text(widget.payment.description!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Consumer<SettingsProvider>(
                  builder: (context, value, _) => Text('${(widget.payment.amount/100).toStringAsFixed(2)} ${value.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                ),
                const SizedBox(height: 8),
                Text(Utils.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}