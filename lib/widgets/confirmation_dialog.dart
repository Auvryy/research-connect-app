// confirmation_dialog.dart
import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
        ElevatedButton(child: Text('Proceed'), onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );
}
