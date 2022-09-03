import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/helper_models.dart';
import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/pages/user_page.dart';
import 'package:debt_tracking_app/providers/settings_provider.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
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

  bool isFabVisible = true;

  Future<void> onFabClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserCreatePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Selector<UserProvider, List<int>>(
                selector: (context, provider) => provider.getUserIds(),
                builder: (context, userIds, _) => NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.forward) {
                      if (!isFabVisible) setState(() => isFabVisible = true);
                    } else if (notification.direction == ScrollDirection.reverse) {
                      if (isFabVisible) setState(() => isFabVisible = false);
                    }
                    return true;
                  },
                  child: Expanded(
                    child: ListView.builder(
                      itemCount: userIds.length,
                      itemBuilder: (context, index) => UserListItem(userId: userIds[index]),
                    ),
                  )
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isFabVisible ? FloatingActionButton(
        onPressed: onFabClick,
        tooltip: 'Create user',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}

class UserListItem extends StatelessWidget {
  const UserListItem({Key? key, required this.userId}) : super(key: key);

  final int userId;

  VoidCallback onUserClick(BuildContext context, User user) => () async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(userId: user.id)));
  };

  @override
  Widget build(BuildContext context) => Selector<UserProvider, User>(
    selector: (context, provider) => provider.getUser(userId)!,
    builder: (context, user, _) => Card(
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
            onTap: onUserClick(context, user),
          )
        ],
      )
    ),
  );
}