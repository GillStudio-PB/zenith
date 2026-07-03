// This file defines the MainLayout widget, which serves as the main layout for the application. It includes a bottom navigation bar that allows users to navigate between different sections of the app, such as Home, Attendance/Trips, Ledger, and More. The layout adapts its content based on whether the user is a heavy vehicle driver or not, providing appropriate icons and labels for each case. The widget uses Riverpod to access user data from the database and determine the user's role.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart'; // import db

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = db.getUsers();
    final isHeavy = users.isNotEmpty ? users.first.isHeavyVehicleDriver : false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (int index) => _onItemTapped(index, context),
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          indicatorColor: Colors.white.withValues(alpha: 0.15),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Colors.white),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(isHeavy
                    ? Icons.local_shipping_outlined
                    : Icons.calendar_month_outlined),
                selectedIcon: Icon(
                    isHeavy ? Icons.local_shipping : Icons.calendar_month,
                    color: Colors.white),
                label: isHeavy ? 'Trips' : 'Attendance'),
            const NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon:
                    Icon(Icons.account_balance_wallet, color: Colors.white),
                label: 'Ledger'),
            const NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu, color: Colors.white),
                label: 'More'),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/attendance')) return 1;
    if (location.startsWith('/finance')) return 2;
    if (location.startsWith('/more')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/attendance');
        break;
      case 2:
        context.go('/finance');
        break;
      case 3:
        context.go('/more');
        break;
    }
  }
}
