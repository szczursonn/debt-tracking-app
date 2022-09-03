import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  static final List<String> currencies = ['zł', '\$', '€', '£', '₽', '₿', '❤'];

  List<DropdownMenuItem<String>> buildCurrencyDropdownItems() => currencies.map((e) => DropdownMenuItem(
    value: e,
    child: Text(e)
  )).toList();

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    Future Function() onThemeButtonPress(ThemeMode themeMode) => () async {
      setState(() => _saving = true);
      await settingsProvider.setThemeMode(themeMode);
      setState(() => _saving = false);
    };

    void onCurrencyChange(String? sel) async {
      if (sel == null) return;
      setState(() => _saving = true);
      await settingsProvider.setCurrency(sel);
      setState(() => _saving = false);
    }

    String getThemeButtonText(ThemeMode tm) {
      switch (tm) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'Auto';
      }
    }
    
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
            child: ListView(
              children: [
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('Currency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Cosmetic only'),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 64),
                        child: DropdownButton(
                          isExpanded: true,
                          items: buildCurrencyDropdownItems(),
                          value: settingsProvider.currency,
                          onChanged: _saving ? null : onCurrencyChange
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('App theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [ThemeMode.system, ThemeMode.light, ThemeMode.dark].map((tm) => 
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: settingsProvider.themeMode==tm ? Theme.of(context).toggleableActiveColor : Theme.of(context).disabledColor
                            ),
                            onPressed: _saving ? null : onThemeButtonPress(tm),
                            child: Text(getThemeButtonText(tm)),
                          )
                        ).toList()
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Theme.of(context).errorColor),
                        onPressed: () {},
                        child: const Text('Reset database')
                      )
                    ],
                  ),
                )
              ],
            )
          ),
        ),
      ),
    );
  }
}
