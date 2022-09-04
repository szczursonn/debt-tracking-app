import 'package:flutter/material.dart';

class AreYouSureDialog extends StatelessWidget {
  const AreYouSureDialog({Key? key, required this.title, required this.content, required this.onYes}) : super(key: key);

  final String title;
  final Widget content;
  final VoidCallback onYes;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: content,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          onYes();
        },
        child: const Text('Yes'),
      ),
    ],
  );
}