import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class PaymentCreatePage extends StatefulWidget {
  const PaymentCreatePage({Key? key, required this.userId, this.editedPayment}) : super(key: key);

  final int userId;
  final Payment? editedPayment;

  @override
  State<PaymentCreatePage> createState() => _PaymentCreatePageState();
}

class _PaymentCreatePageState extends State<PaymentCreatePage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountTextController = TextEditingController(text: '0');
  final TextEditingController _dateTextController = TextEditingController(text: '');
  
  bool _saving = false;
  String _description = '';
  DateTime _date = DateTime.now();

  void onSubmitClick() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);

      late Payment payment;

      if (widget.editedPayment == null) {
        payment = await DatabaseHelper.instance.createPayment(
          userId: widget.userId, 
          amount: double.parse(_amountTextController.text).round()*100,
          date: _date, 
          description: (_description.isEmpty) ? null : _description
        );
      } else {
        Payment p = Payment(
          id: widget.editedPayment!.id,
          userId: widget.userId,
          amount: double.parse(_amountTextController.text).round()*100,
          date: _date, 
          description: (_description.isEmpty) ? null : _description
        );
        payment = await DatabaseHelper.instance.updatePayment(p);
      }

      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, payment);
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
    if (widget.editedPayment != null) {
      _date = widget.editedPayment!.date;
      _amountTextController.text = (widget.editedPayment!.amount/100).toStringAsFixed(2);
      if (widget.editedPayment!.description != null) {
        _description = widget.editedPayment!.description!;
      }
    }
    _dateTextController.text = Utils.formatDate(_date);
  }

  @override
  void dispose() {
    super.dispose();
    _amountTextController.dispose();
    _dateTextController.dispose();
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
          title: Text(widget.editedPayment == null ? 'Register payment' : 'Edit payment'),
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
                  initialValue: widget.editedPayment?.description,
                  onChanged: (String? value) {
                    if (value != null) setState(() => _description = value);
                  },
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
                      child: Text(widget.editedPayment == null ? 'Create' : 'Edit'),
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
