import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class PaymentCreatePage extends StatefulWidget {
  const PaymentCreatePage({Key? key, required this.user}) : super(key: key);

  final User user;

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

      var payment = await DatabaseHelper.instance.createPayment(
        userId: widget.user.id, 
        amount: double.parse(_amountTextController.text),
        date: _date, 
        description: (_description.isEmpty) ? null : _description
      );

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
        _dateTextController.text = '${_date.year}/${_date.month}/${_date.day}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _dateTextController.text = '${_date.year}/${_date.month}/${_date.day}';
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
          title: const Text('Register payment'),
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
                      child: const Text('Create'),
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
