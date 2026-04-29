import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/screens/splash/splash_screen.dart';
import 'package:lost_and_found/screens/onboarding/onboarding_screen.dart';
import 'package:lost_and_found/screens/auth/login_screen.dart';
import 'package:lost_and_found/screens/auth/register_screen.dart';
import 'package:lost_and_found/screens/home/home_screen.dart';
import 'package:lost_and_found/screens/report/report_item_screen.dart';
import 'package:lost_and_found/screens/detail/item_detail_screen.dart';
import 'package:lost_and_found/screens/search/search_screen.dart';
import 'package:lost_and_found/screens/profile/profile_screen.dart';
import 'package:lost_and_found/screens/claims/claims_screen.dart';
import 'package:lost_and_found/screens/admin/admin_screen.dart';
import 'package:lost_and_found/screens/notifications/notifications_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String reportItem = '/report';
  static const String itemDetail = '/item/:id';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String claims = '/claims';
  static const String admin = '/admin';
  static const String notifications = '/notifications';

  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: context.read<AuthProvider>(),
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: reportItem,
          builder: (context, state) => const ReportItemScreen(),
        ),
        GoRoute(
          path: '/item/:id',
          builder: (context, state) {
            final itemId = state.pathParameters['id']!;
            return ItemDetailScreen(itemId: itemId);
          },
        ),
        GoRoute(
          path: search,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: claims,
          builder: (context, state) => const ClaimsScreen(),
        ),
        GoRoute(
          path: admin,
          builder: (context, state) => const AdminScreen(),
        ),
        GoRoute(
          path: notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isLoggedIn = authProvider.isLoggedIn;
        final currentPath = state.uri.path;

        // Allow splash and onboarding without auth
        if (currentPath == splash || currentPath == onboarding) {
          return null;
        }

        // Redirect to login if not authenticated
        if (!isLoggedIn &&
            currentPath != login &&
            currentPath != register &&
            currentPath != onboarding) {
          return login;
        }

        // Don't let logged-in users access login/register
        if (isLoggedIn &&
            (currentPath == login || currentPath == register)) {
          return home;
        }

        // Admin route protection
        if (currentPath == admin && !authProvider.isAdmin) {
          return home;
        }

        return null;
      },
    );
  }
}
