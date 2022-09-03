import 'package:flutter/material.dart';

class PaymentIcon extends StatelessWidget {
  const PaymentIcon({Key? key, this.radius}) : super(key: key);

  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.lime,
      child: Icon(Icons.credit_score, size: radius)
    );
  }
}