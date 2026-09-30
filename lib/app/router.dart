import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/providers.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/apartment/presentation/apartment_setup_screen.dart';
import '../features/apartment/presentation/create_apartment_screen.dart';
import '../features/apartment/presentation/join_apartment_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/laundry/presentation/laundry_screen.dart';
import '../features/laundry/presentation/book_laundry_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/updates/presentation/updates_screen.dart';
import '../features/updates/presentation/create_update_screen.dart';
import '../features/roommates/presentation/roommates_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/account_details_screen.dart';
import '../features/settings/presentation/notifications_settings_screen.dart';
import '../features/settings/presentation/apartment_settings_screen.dart';
import '../features/settings/presentation/privacy_screen.dart';
import '../features/settings/presentation/help_support_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      // Check auth state
      final currentUser = Supabase.instance.client.auth.currentUser;
      final isAuthenticated = currentUser != null;

      // Public routes that don't need auth
      final publicRoutes = ['/welcome', '/login', '/register', '/forgot-password', '/'];
      final isPublicRoute = publicRoutes.contains(location);

      if (!isAuthenticated && !isPublicRoute) {
        return '/welcome';
      }

      if (isAuthenticated && isPublicRoute && location != '/') {
        // Check apartment membership
        final membership = await ref
            .read(apartmentRepositoryProvider)
            .fetchCurrentMembership(currentUser.id);

        if (membership != null) {
          return '/home';
        } else {
          return '/apartment/setup';
        }
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Apartment setup
      GoRoute(
        path: '/apartment/setup',
        builder: (context, state) => const ApartmentSetupScreen(),
      ),
      GoRoute(
        path: '/apartment/create',
        builder: (context, state) => const CreateApartmentScreen(),
      ),
      GoRoute(
        path: '/apartment/join',
        builder: (context, state) => const JoinApartmentScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/laundry',
            builder: (context, state) => const LaundryScreen(),
            routes: [
              GoRoute(
                path: 'book',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const BookLaundryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/updates',
            builder: (context, state) => const UpdatesScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateUpdateScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Roommates (outside shell - accessed from home)
      GoRoute(
        path: '/roommates',
        builder: (context, state) => const RoommatesScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'account',
            builder: (context, state) => const AccountDetailsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsSettingsScreen(),
          ),
          GoRoute(
            path: 'apartment',
            builder: (context, state) => const ApartmentSettingsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpSupportScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
