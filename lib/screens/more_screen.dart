// This file defines the MoreScreen widget, which displays a list of additional modules available in the application. The screen adapts its content based on whether the user is a heavy vehicle driver or not, providing relevant options for each case. It uses the GoRouter package for navigation to different screens within the app.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _isDriver = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() {
    final users = db.getUsers();
    if (users.isNotEmpty) {
      if (users.first.isHeavyVehicleDriver) {
        setState(() {
          _isDriver = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('More Modules',
            style: TextStyle(
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (_isDriver) ...[
                    _MenuTile(
                        icon: Icons.local_shipping,
                        color: Colors.amberAccent,
                        label: 'Trip Tracker',
                        onTap: () => context.push('/trips')),
                    Divider(
                        height: 1, color: Colors.white.withValues(alpha: 0.02)),
                    _MenuTile(
                        icon: Icons.receipt_long,
                        color: Colors.deepOrangeAccent,
                        label: 'Traffic Fines Tracker',
                        onTap: () => context.push('/fines')),
                    Divider(
                        height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  ],
                  _MenuTile(
                      icon: Icons.smart_toy,
                      color: const Color(0xFF64FFDA),
                      label: 'AI Legal & Financial Assistant',
                      onTap: () => context.push('/ai-assistant')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.cases_outlined,
                      color: const Color(0xFF536DFE),
                      label: 'Payroll Verification',
                      onTap: () => context.push('/payroll')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.newspaper,
                      color: const Color(0xFF448AFF),
                      label: 'MOHRE & UAE News',
                      onTap: () => context.push('/mohre-news')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.account_balance,
                      color: const Color(0xFF69F0AE),
                      label: 'Loans & Advances',
                      onTap: () => context.push('/loans')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.currency_rupee,
                      color: const Color(0xFF64FFDA),
                      label: 'Family Transfers',
                      onTap: () => context.push('/transfers')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.monetization_on,
                      color: Colors.white,
                      label: 'Gold Vault',
                      onTap: () => context.push('/gold')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.track_changes,
                      color: Colors.orangeAccent,
                      label: 'Financial Goals',
                      onTap: () => context.push('/goals')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.currency_exchange,
                      color: Colors.lightGreenAccent,
                      label: 'Live FX & Metals',
                      onTap: () => context.push('/forex')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.book,
                      color: Colors.white70,
                      label: 'Notes & Diary',
                      onTap: () => context.push('/notes')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.calendar_month,
                      color: Colors.pinkAccent,
                      label: 'Yearly Calendar',
                      onTap: () => context.push('/calendar')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.shield_outlined,
                      color: const Color(0xFFFF5252),
                      label: 'Documents Vault',
                      onTap: () => context.push('/vault')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.settings,
                      color: Colors.blueGrey,
                      label: 'Settings & Backup',
                      onTap: () => context.push('/settings')),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.02)),
                  _MenuTile(
                      icon: Icons.electric_bolt_rounded,
                      color: Colors.purpleAccent,
                      label: 'About Developers',
                      onTap: () => context.push('/about')),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.white)),
      trailing: Icon(Icons.chevron_right,
          color: Colors.white.withValues(alpha: 0.15)),
      onTap: onTap,
    );
  }
}
