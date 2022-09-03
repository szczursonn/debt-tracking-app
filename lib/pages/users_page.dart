import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/pages/user_page.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../widgets/user_avatar.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late List<User> users;
  bool loading = false;

  bool isFabVisible = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);

    users = await DatabaseHelper.instance.fetchAllUsers();

    if (mounted) setState(() => loading = false);
  }

  Future<void> onFabClick() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserCreatePage()));
    if (!mounted) return;

    if (res is User) {
      setState(() {
        users.add(res);
      });
    }
  }

  VoidCallback onUserClick(User user) => () async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(user: user)));
    if (res is User) {
      var i = users.indexWhere((element) => element.id==res.id);
      if (i != -1) {
        setState(() {
          users[i] = res;
        });
      }
    }
  };

  Widget buildUserList() => NotificationListener<UserScrollNotification>(
    onNotification: (notification) {
      if (notification.direction == ScrollDirection.forward) {
        if (!isFabVisible) setState(() => isFabVisible = true);
      } else if (notification.direction == ScrollDirection.reverse) {
        if (isFabVisible) setState(() => isFabVisible = false);
      }
      return true;
    },
    child: ListView.builder(itemCount: users.length, itemBuilder: (context, index) {
      User user = users[index];
      return Card(
        elevation: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: UserAvatar(user: user),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: FutureBuilder<UserBalance>(
                future: DatabaseHelper.instance.fetchUserBalance(user.id), 
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    UserBalance data = snapshot.data!;
                    int bal = data.paid-data.owed;
                    return Consumer<SettingsProvider>(
                      builder: (context, value, _) => Text('${(bal/100).toStringAsFixed(2)} ${value.currency}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: (bal >= 0) ? Colors.green : Colors.redAccent)),
                    );
                  }
                  return const Text('loading...');
                }
              ),
              onTap: onUserClick(user),
            )
          ],
        )
      );
    }),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loading ? const CircularProgressIndicator() : (users.isEmpty ? const Text('There are no users') : Expanded(child: buildUserList())),
            ],
          ),
        ),
      ),
      floatingActionButton: (isFabVisible && !loading) ? FloatingActionButton(
        onPressed: onFabClick,
        tooltip: 'Create user',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
