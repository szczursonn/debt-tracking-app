import 'package:debt_tracking_app/pages/user_create_page.dart';
import 'package:debt_tracking_app/providers/user_provider.dart';
import 'package:debt_tracking_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../models.dart';

class UsersSelectorPage extends StatefulWidget {
  const UsersSelectorPage({Key? key, required this.previouslySelectedUsersIds}) : super(key: key);

  final List<int> previouslySelectedUsersIds;

  @override
  State<UsersSelectorPage> createState() => _UsersSelectorPageState();
}

class _UsersSelectorPageState extends State<UsersSelectorPage> {
  final Map<int, bool> _selections = {};
  
  bool isFabVisible = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      for (var prevSel in widget.previouslySelectedUsersIds) {
        _selections[prevSel] = true;
      }
    });
  }

  void onFabClick() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserCreatePage()));
  }

  void onDoneClick() async {
    var selectedUsersIds = _selections.entries.where((e) => e.value==true).map((e) => e.key).toList();
    Navigator.pop(context, selectedUsersIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!isFabVisible) setState(() => isFabVisible = true);
          } else if (notification.direction == ScrollDirection.reverse) {
            if (isFabVisible) setState(() => isFabVisible = false);
          }
          return true;
        },
        child: Center(
          child: Selector<UserProvider, List<int>>(
            selector: (context, provider)=>provider.getUserIds(),
            builder: (context, userIds, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                userIds.isEmpty
                ? const Text('There are no users')
                : Expanded(
                  child: ListView.builder(
                    itemCount: userIds.length,
                    itemBuilder: (context, index) {
                      int userId = userIds[index];
                      return UserListItem(
                        userId: userId,
                        isSelected: _selections[userId] ?? false,
                        onTap: () {
                          setState(() {
                            _selections[userId] = !(_selections[userId] ?? false);
                          });
                        },
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Select users'),
        actions: [
          IconButton(
            onPressed: onDoneClick, 
            icon: const Icon(Icons.done)
          )
        ],
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
  const UserListItem({Key? key, required this.userId, required this.isSelected, required this.onTap}) : super(key: key);

  final int userId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Selector<UserProvider, User>(
    selector: (context, provider) => provider.getUser(userId)!,
    builder: (context, user, _) => Card(
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
              onTap: onTap,
          )
        ],
      )
    ),
  );
}