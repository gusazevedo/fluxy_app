// lib/app/placeholder_screens.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(title, style: AppText.titleScreen));
}

class LoginPlaceholder extends StatelessWidget {
  const LoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: PlaceholderScreen('Login (spec 02)'));
}
