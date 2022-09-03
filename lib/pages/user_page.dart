import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/pages/debt_create_page.dart';
import 'package:debt_tracking_app/pages/debt_page.dart';
import 'package:debt_tracking_app/pages/payment_create_page.dart';
import 'package:debt_tracking_app/pages/payment_page.dart';
import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/utils.dart';
import 'package:debt_tracking_app/widgets/debt_icon.dart';
import 'package:debt_tracking_app/widgets/payment_icon.dart';
import 'package:debt_tracking_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper_models.dart';
import '../models.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late List<dynamic> _history;  // List<Payment|Debt>
  bool _loading = false;
  late User _user;

  void loadHistory() async {
    setState(() => _loading = true);

    _history = await DatabaseHelper.instance.fetchUserHistory(_user.id);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _user = widget.user;
      loadHistory();
    });
  }

  void onEditClick() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => UserCreatePage(editedUser: _user)));
    if (res is User) {
      setState(() {
        _user = res;
      });
    }
  }

  void onAddDebtClick() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => DebtCreatePage(initialUser: _user)));
    if (res is Debt) {
      setState(() {
        _history.add(res);
        sortHistory();
      });
    }
  }

  void onAddPaymentClick() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentCreatePage(userId: _user.id)));
    if (res is Payment) {
      setState(() {
        _history.add(res);
        sortHistory();
      });
    }
  }

  void sortHistory() {
    _history.sort((a,b) => a.date.compareTo(b.date));
  }

  Widget buildHistory() {
    List<List<dynamic>> groups = [];

    DateTime? prevDate;
    int index = -1;

    for (var item in _history) {
      if (prevDate != null && item.date.day == prevDate.day && item.date.month == prevDate.month && item.date.year == prevDate.year) {
        groups[index].add(item);
      } else {
        index+=1;
        groups.add([item]);
      }
      prevDate = item.date;
    }

    groups = groups.reversed.toList();
    
    return ListView.builder(
      itemCount: groups.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (builder, i) {
        var group = groups[i];
        DateTime date = group.first.date;
    
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, left: 12, bottom: 4),
                child: Text(
                  Utils.formatDate(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17
                  )
                ),
              ),
              const Divider(thickness: 3),
              Column(
                children: group.map(buildItem).toList(),
              )
            ],
          ),
        );
      }
    );
  }

  Widget buildItem(dynamic item) {
    late String title;
    late String? description;
    late Widget trailingWidget;
    late VoidCallback tapCb;
    late Widget avatarWidget;

    String currency = Provider.of<SettingsProvider>(context).currency;

    if (item is Debt) {
      title = item.title;
      description = item.description;
      trailingWidget = FutureBuilder<double>(
        future: DatabaseHelper.instance.fetchUserDebtTotal(userId: _user.id, debtId: item.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text('-${snapshot.data!.toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red));
          } else {
            return const Text('loading...');
          }
        }
      );
      tapCb = () async {
        var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => DebtPage(debt: item)));
        if (res is Debt) {
          setState(() {
            _history.add(res);
            sortHistory();
          });
        }
      };
      avatarWidget = const DebtIcon();

    } else if (item is Payment) {
      title = 'Payment';
      description = item.description;
      trailingWidget = Text('+${(item.amount/100).toStringAsFixed(2)} $currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green));
      tapCb = () async {
        var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(payment: item)));
        if (res is Payment) {
          setState(() {
            _history.add(res);
            sortHistory();
          });
        }
      };
      avatarWidget = const PaymentIcon();

    } else {
      throw Error();
    }

    return InkWell(
      onTap: tapCb,
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: description == null ? null : Text(description, overflow: TextOverflow.ellipsis, maxLines: 2),
            leading: avatarWidget,
            trailing: trailingWidget,
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _user);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_user.name),
          actions: [
            IconButton(
              onPressed: onEditClick, 
              icon: const Icon(Icons.edit)
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UserAvatar(user: _user, radius: 56),
                Text(_user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                FutureBuilder(
                  future: DatabaseHelper.instance.fetchUserBalance(_user.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      UserBalance x = snapshot.data as UserBalance;
                      int bal = x.paid-x.owed;
                      return Consumer<SettingsProvider>(
                        builder: (context, value, _) => Text('${(bal/100).toStringAsFixed(2)} ${value.currency}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: (bal >= 0 ? Colors.green : Colors.red)))
                      );
                    }
                    return const CircularProgressIndicator();
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: onAddDebtClick, child: const Text('Add debt')),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: onAddPaymentClick, child: const Text('Register payment')),
                  ],
                ),
                const Divider(color: Colors.black),
                const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _loading ? const CircularProgressIndicator() : buildHistory()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
