import 'package:debt_tracking_app/models.dart';
import 'package:debt_tracking_app/pages/user_page.dart';
import 'package:debt_tracking_app/providers/debt_provider.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:debt_tracking_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              children: [
                Card(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total amount of money lent ever', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Selector<SettingsProvider, String>(
                          selector: (context, provider) => provider.currency,
                          builder: (context, currency, _) => Selector<DebtProvider, int>(
                            selector: (context, provider) => provider.getTotalOwedAmount(),
                            builder: (context, amount, _) => Text('${(amount/100).toStringAsFixed(2)} $currency'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const Text('Total amount lent by user', style: TextStyle(fontWeight: FontWeight.bold)),
                Selector2<DebtProvider, UserProvider, List<_UserWithAmount>>(
                  selector: (context, debtProvider, userProvider) {
                    var lst = userProvider.getUserIds().map((e) => _UserWithAmount(userId: e, amount: debtProvider.getUserTotalOwedAmount(e))).toList();
                    lst.sort((a, b) => a.amount>b.amount ? -1 : 1);
                    return lst;
                  },
                  builder: (context, value, _) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      var item = value[index];
                      return Selector<UserProvider, User?>(
                        selector: (context, provider) => provider.getUser(item.userId),
                        builder: (context, user, _) => user == null ? Container() : Card(
                          elevation: 2,
                          child: Column(
                            children: [
                              ListTile(
                                leading: UserAvatar(user: user),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: Selector<SettingsProvider, String>(
                                  selector: (context, provider) => provider.currency,
                                  builder: (context, currency, _) => Text(
                                    '${(item.amount/100).toStringAsFixed(2)} $currency',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)
                                  ),
                                ),
                                onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>UserPage(userId: user.id))),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserWithAmount {
  _UserWithAmount({required this.userId, required this.amount});

  final int userId;
  final int amount;
}