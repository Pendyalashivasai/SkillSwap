import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/features/auth/controllers/auth_controller.dart';
import 'package:skillswap/features/auth/screens/login_screen.dart';

import 'package:skillswap/features/skills/screens/home_screen.dart';

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}