import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/core/app_router.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/state/skill_state.dart';
import 'package:skillswap/state/user_state.dart';
import 'package:skillswap/state/chat_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize FirestoreService (your database handler)
  final firestoreService = FirestoreService();
  
 final FirebaseAuth auth = FirebaseAuth.instance;
final String currentUserId = auth.currentUser?.uid ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SkillState(firestoreService)),
        ChangeNotifierProvider(create: (context) => UserState(firestoreService)),
        ChangeNotifierProvider(create: (context) => ChatState(firestoreService, currentUserId)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter.router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
