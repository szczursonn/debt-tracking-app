import 'package:debt_tracking_app/models.dart';
import 'package:debt_tracking_app/pages/debts_page.dart';
import 'package:debt_tracking_app/pages/settings_page.dart';
import 'package:debt_tracking_app/pages/statistics_page.dart';
import 'package:debt_tracking_app/pages/users_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/providers/payment_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            var provider = SettingsProvider();
            provider.load();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            var provider = UserProvider();
            provider.load();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            var provider = PaymentProvider();
            provider.load();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            var provider = DebtProvider();
            provider.load();
            return provider;
          },
        )
      ],
      
      builder: (context, _) {
        final settingsProvider = Provider.of<SettingsProvider>(context);
        return MaterialApp(
          title: 'debt tracking app',
          // Light theme
          theme: ThemeData(
            primarySwatch: Colors.blue,
            cardColor: Colors.white70
          ),
          // Dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark
          ),
          themeMode: settingsProvider.themeMode,
          home: Selector4<SettingsProvider, UserProvider, PaymentProvider, DebtProvider, bool>(
            selector: (context, settingsProvider, userProvider, paymentProvider, debtProvider) => settingsProvider.loading||userProvider.loading||paymentProvider.loading||debtProvider.loading,
            builder: (context, loading, _) => loading ? 
              Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading database', style: TextStyle(fontWeight: FontWeight.w500))
                    ],
                  ),
                ),
              )
              : 
              DefaultTabController(
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
                      StatisticsPage()
                    ],
                  )
                )
              ),
          ),
        );
      },
    );
  }
}

