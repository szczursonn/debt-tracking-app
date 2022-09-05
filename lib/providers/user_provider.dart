import 'dart:typed_data';

import 'package:debt_tracking_app/database_helper.dart';
import 'package:debt_tracking_app/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<int, User> _usersById = {};
  bool _loading = false;

  bool get loading => _loading;

  List<int> getUserIds() => _usersById.keys.toList();

  User? getUser(int userId) => _usersById[userId];

  Future<void> createUser(String name, Uint8List? avatar) async {
    var user = await DatabaseHelper.instance.createUser(name, avatar);
    _usersById[user.id] = user;
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    var updatedUser = await DatabaseHelper.instance.updateUser(user);
    _usersById[updatedUser.id] = updatedUser;
    notifyListeners();
  }

  Future<void> removeUser(int userId) async {
    await DatabaseHelper.instance.removeUser(userId);
    _usersById.remove(userId);

    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    var users = await DatabaseHelper.instance.fetchAllUsers();
    _usersById = {};
    for (var user in users) {
      _usersById[user.id]=user;
    }
    _loading = false;

    notifyListeners();
  }
}