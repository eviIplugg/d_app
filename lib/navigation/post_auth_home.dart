import 'package:flutter/material.dart';

import '../screens/feed/main_app_shell.dart';

/// Куда вести пользователя после входа / онбординга.
class PostAuthHome {
  PostAuthHome._();

  static const Widget shell = MainAppShell();

  static void replaceWithShell(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => shell),
    );
  }
}
