import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillswap/features/auth/screens/login_screen.dart';
import 'package:skillswap/features/auth/screens/register_screen.dart';
import 'package:skillswap/features/auth/screens/forgot_password_screen.dart';
import 'package:skillswap/features/skills/screens/home_screen.dart';
import 'package:skillswap/features/splash/splash_screen.dart';

import '../features/auth/screens/onboarding_screen.dart';


class AppRouter {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
  path: '/onboarding',
  name: 'onboarding',
  builder: (context, state) => const OnboardingScreen(),
),
      // Main App
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = _auth.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') || 
                         state.matchedLocation.startsWith('/register') ||
                         state.matchedLocation.startsWith('/forgot-password');

      // Don't redirect splash screen
      if (state.matchedLocation == '/splash') return null;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Redirect to home if logged in and trying to access auth
      if (isLoggedIn && isAuthRoute) return '/home';

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}