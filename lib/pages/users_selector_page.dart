import 'package:debt_tracking_app/DatabaseHelper.dart';
import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/widgets/UserAvatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models.dart';

class UsersSelectorPage extends StatefulWidget {
  const UsersSelectorPage({Key? key, required this.previouslySelectedUsers}) : super(key: key);

  final List<User> previouslySelectedUsers;

  @override
  State<UsersSelectorPage> createState() => _UsersSelectorPageState();
}

class _UsersSelectorPageState extends State<UsersSelectorPage> {
  late List<User> _users;
  late Map<int, bool> _selections;
  bool _loading = false;
  
  bool isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);

    _users = await DatabaseHelper.instance.fetchAllUsers();

    _selections = {};
    for (var user in _users) {
      _selections[user.id] = false;
    }
    for (var user in widget.previouslySelectedUsers) {
      _selections[user.id] = true;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void onFabClick() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserCreatePage()))
      .then((value) {
        if (!mounted) return;
        if (value is User) {
          setState(() {
            _users.add(value);
            _selections[value.id]=false;
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
    child: ListView.builder(itemCount: _users.length, itemBuilder: (context, index) {
      User user = _users[index];
      bool isSelected = _selections[user.id] ?? false;
      return Card(
        elevation: 2,
        color: isSelected ? Theme.of(context).colorScheme.surfaceTint : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: UserAvatar(user: user),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  setState(() {
                    _selections[user.id] = !(_selections[user.id] ?? false);
                  });
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
          children: [
            _loading ? const CircularProgressIndicator() : (_users.isEmpty ? const Text('There are no users') : Expanded(child: buildUserList())),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Select users'),
        actions: [
          IconButton(
            onPressed: !_loading ? () {
              var selectedUsers = _users.where((u) => _selections[u.id]??false).toList();
              Navigator.pop(context, selectedUsers);
            } : null, 
            icon: const Icon(Icons.done)
          )
        ],
      ),
      floatingActionButton: (isFabVisible && !_loading) ? FloatingActionButton(
        onPressed: onFabClick,
        tooltip: 'Create user',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
