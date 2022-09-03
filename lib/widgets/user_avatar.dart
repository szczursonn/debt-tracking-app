import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({Key? key, required this.user, this.radius}): super(key: key);

  static const List<Color> colors = [];

  final User user;
  final double? radius;

  // https://stackoverflow.com/questions/61289182/how-to-get-first-character-from-words-in-flutter-dart
  String getInitials(String username) => username.isNotEmpty
    ? username.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join().toUpperCase()
    : '';

  @override
  Widget build(BuildContext context) {
    
    bool hasAvatar = user.avatar != null;

    return Hero(
      tag: 'useravatar-${user.name}',
      child: CircleAvatar(
        radius: radius,
        backgroundImage: hasAvatar ? MemoryImage(user.avatar!) : null,
        backgroundColor: !hasAvatar ? Colors.accents[Random(user.id).nextInt(Colors.accents.length)] : null,
        child: !hasAvatar ? Text(getInitials(user.name), style: TextStyle(fontSize: radius)) : null,
      )
    );
  }
}