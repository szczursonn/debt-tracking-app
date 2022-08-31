import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final _formKey = GlobalKey<FormState>();
  
  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onCurrencyChange(String? sel) {
    
  }

  final List<String> currencies = ['zł', '\$', 'eur'];

  List<DropdownMenuItem<String>> buildCurrencyDropdownItems() => currencies.map((e) => DropdownMenuItem(
    value: e,
    child: Text(e)
  )).toList();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_saving) Navigator.pop(context, null);

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('App settings'),
        ),
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text('Currency'),
                DropdownButton(
                  items: buildCurrencyDropdownItems(), 
                  onChanged: onCurrencyChange
                )
              ],
            )
          ),
        ),
      ),
    );
  }
}
