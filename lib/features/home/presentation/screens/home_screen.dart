import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});
  final Widget child;

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home'))        return 0;
    if (location.startsWith('/messages'))    return 1;
    if (location.startsWith('/add'))         return 2;
    if (location.startsWith('/special'))     return 3;
    if (location.startsWith('/profile-tab')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      extendBody: true,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _getCurrentIndex(context),
      ),
    );
  }
}