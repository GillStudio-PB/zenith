// This file defines the routing configuration for the Dubai Worker application using the GoRouter package. It sets up the initial route to the splash screen and defines various routes for different screens in the app, including dashboard, attendance, finance, transfers, goals, loans, payroll, notes, vault, calendar, settings, AI assistant, Mohre news, gold accumulation, forex converter, about, trips, and fines. The MainLayout widget is used as a shell route to provide a consistent layout for the main sections of the app.
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/main_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/more_screen.dart';
import 'screens/transfers_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/payroll_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/mohre_rss_screen.dart';
import 'screens/gold_screen.dart';
import 'screens/forex_converter_screen.dart';
import 'screens/about_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/fines_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen()),
        GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen()),
        GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceScreen()),
        GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
      ],
    ),
    GoRoute(
        path: '/transfers',
        builder: (context, state) => const TransfersScreen()),
    GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
    GoRoute(path: '/loans', builder: (context, state) => const LoansScreen()),
    GoRoute(
        path: '/payroll', builder: (context, state) => const PayrollScreen()),
    GoRoute(path: '/notes', builder: (context, state) => const NotesScreen()),
    GoRoute(path: '/vault', builder: (context, state) => const VaultScreen()),
    GoRoute(
        path: '/calendar', builder: (context, state) => const CalendarScreen()),
    GoRoute(
        path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AIAssistantScreen()),
    GoRoute(
        path: '/mohre-news',
        builder: (context, state) => const MohreRssScreen()),
    GoRoute(
        path: '/gold',
        builder: (context, state) => const GoldAccumulationScreen()),
    GoRoute(
        path: '/forex',
        builder: (context, state) => const ForexConverterScreen()),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(path: '/trips', builder: (context, state) => const TripsScreen()),
    GoRoute(path: '/fines', builder: (context, state) => const FinesScreen()),
  ],
);
