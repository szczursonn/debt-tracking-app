import 'package:debt_tracking_app/providers/payment_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class PaymentCreatePage extends StatefulWidget {
  const PaymentCreatePage({Key? key, required this.userId, this.editedPaymentId}) : super(key: key);

  final int userId;
  final int? editedPaymentId;

  @override
  State<PaymentCreatePage> createState() => _PaymentCreatePageState();
}

class _PaymentCreatePageState extends State<PaymentCreatePage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionTextController = TextEditingController(text: '');
  final TextEditingController _amountTextController = TextEditingController(text: '0');
  final TextEditingController _dateTextController = TextEditingController(text: '');
  
  bool _saving = false;
  DateTime _date = DateTime.now();

  void onSubmitClick() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);

      var description = (_descriptionTextController.text.isEmpty) ? null : _descriptionTextController.text;
      var provider = Provider.of<PaymentProvider>(context, listen: false);

      if (widget.editedPaymentId == null) {
        await provider.createPayment(
          userId: widget.userId, 
          amount: double.parse(_amountTextController.text).round()*100,
          date: _date, 
          description: description
        );
      } else {
        await provider.updatePayment(Payment(
          id: widget.editedPaymentId!,
          userId: widget.userId,
          amount: double.parse(_amountTextController.text).round()*100,
          date: _date, 
          description: description
        ));
      }

      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  void onPickDateClick() async {
    var date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2100));
    if (mounted && date != null) {
      setState(() {
        _date = date;
        _dateTextController.text = Utils.formatDate(_date);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.editedPaymentId != null) {
      var payment = Provider.of<PaymentProvider>(context, listen: false).getPayment(widget.userId, widget.editedPaymentId!);
        if (payment != null) {
          _date = payment.date;
          _amountTextController.text = (payment.amount/100).toStringAsFixed(2);
        if (payment.description != null) {
          _descriptionTextController.text = payment.description!;
        }
      }
    }
    _dateTextController.text = Utils.formatDate(_date);
  }

  @override
  void dispose() {
    super.dispose();
    _amountTextController.dispose();
    _dateTextController.dispose();
    _descriptionTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_saving) Navigator.pop(context, null);

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editedPaymentId == null ? 'Register payment' : 'Edit payment'),
        ),
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  readOnly: _saving,
                  controller: _amountTextController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: UnderlineInputBorder()
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    var number = double.tryParse(value!);
                    if (number == null) {
                      return 'Invalid number';
                    }
                    if (number <= 0) {
                      return 'Must be greater than 0';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: UnderlineInputBorder()
                  ),
                  readOnly: _saving,
                  controller: _descriptionTextController,
                ),
                TextFormField(
                  controller: _dateTextController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: UnderlineInputBorder()
                  ),
                  readOnly: true,
                  onTap: onPickDateClick,
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 4.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: _saving ? null : onSubmitClick,
                      child: Text(widget.editedPaymentId == null ? 'Create' : 'Edit'),
                    ),
                  ),
                ),
              ],
            )
          ),
        ),
      ),
    );
  }
}
