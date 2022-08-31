import 'package:debt_tracking_app/pages/debts_page.dart';
import 'package:debt_tracking_app/pages/settings_page.dart';
import 'package:debt_tracking_app/pages/users_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(builder: (builder) => const SettingsPage()));
    }, 
    icon: const Icon(Icons.settings)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'debt tracking app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark
      ),
      themeMode: ThemeMode.system,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            actions: const [
              SettingsButton()
            ],
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.person)),
                Tab(icon: Icon(Icons.euro)),
                Tab(icon: Icon(Icons.show_chart))
              ],
            ),
            title: const Text('debt-tracking-app'),
          ),
          body: const TabBarView(
            children: [
              UsersPage(),
              DebtsPage(),
              Icon(Icons.abc_rounded)
            ],
          )
        )
      ),//
    );
  }
}

