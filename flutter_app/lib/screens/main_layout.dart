import 'package:flutter/material.dart';
import '../widgets/header.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShopHeader(),
      backgroundColor: const Color(0xFFF9FAFB), // light gray background simulating web
      body: child,
    );
  }
}
