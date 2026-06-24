import 'package:flutter/material.dart';

class AudespSnackBar {
  const AudespSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.red);
  }
}
