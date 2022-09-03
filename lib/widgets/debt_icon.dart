import 'package:flutter/material.dart';

class DebtIcon extends StatelessWidget {
  const DebtIcon({Key? key, this.radius}) : super(key: key);

  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.amber,
      child: Icon(Icons.paid, size: radius)
    );
  }
}