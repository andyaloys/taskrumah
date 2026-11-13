import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/child/child_dashboard_screen.dart';
import 'features/dashboard/admin/admin_dashboard_screen.dart';

class FamilyTaskApp extends ConsumerWidget {
  const FamilyTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      title: 'FamilyTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: Builder(
        builder: (context) {
          if (authState.status == AuthStatus.initial) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF818CF8)),
              ),
            );
          }

          if (authState.status == AuthStatus.authenticated && authState.user != null) {
            if (authState.user!.isAdmin) {
              return const AdminDashboardScreen();
            } else {
              return const ChildDashboardScreen();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
