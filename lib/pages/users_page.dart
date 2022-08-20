import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/pages/user_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models.dart';

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

  void onFabClick() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserCreatePage()))
      .then((value) {
        if (!mounted) return;
        if (value is User) {
          setState(() {
            users.add(value);
          });
        }
      });
  }

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
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Text('XD')
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: FutureBuilder<int>(future: DatabaseHelper.instance.fetchUserBalance(user.id), builder: (context, snapshot) {
                if (snapshot.hasData) {
                  int data = snapshot.data!;
                  return Text('Balance: ${(data/100).toStringAsFixed(2)} PLN');
                }
                return const Text('loading...');
              }),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserPage(user: user)));
              },
            )
          ],
        )
      );
    }),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            loading ? const CircularProgressIndicator() : (users.isEmpty ? const Text('There are no users') : Expanded(child: buildUserList())),
          ],
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
