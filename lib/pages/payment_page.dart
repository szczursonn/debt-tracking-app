import 'package:debt_tracking_app/pages/payment_create_page.dart';
import 'package:debt_tracking_app/providers/payment_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/utils.dart';
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

class _PaymentPageState extends State<PaymentPage> {

  void onEditClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentCreatePage(userId: widget.userId, editedPaymentId: widget.paymentId)));
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PaymentProvider, Payment>(
      selector: (context, provider) => provider.getPayment(widget.userId, widget.paymentId)!,
      builder: (context, payment, _) => Scaffold(
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
    );
  }
}