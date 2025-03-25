import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:skillswap/core/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  
  final AppRouter _appRouter = AppRouter(); // Create single instance

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter.router, // Use the router instance
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}