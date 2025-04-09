import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/core/app_router.dart';
import 'package:skillswap/features/auth/controllers/auth_controller.dart';
import 'package:skillswap/features/auth/services/auth_service.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/state/skill_state.dart';
import 'package:skillswap/state/user_state.dart';
import 'package:skillswap/state/chat_state.dart';
import 'package:skillswap/services/mongodb_service.dart';

import 'features/profile/services/profile_service.dart';
import 'firebase_options.dart';
import 'services/swap_service.dart';
import 'state/swaprequest_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Auth
  
  final mongoDBService = await MongoDBService.initialize();
  final userState = UserState(mongoDBService);
  final profileService = ProfileService(mongoDBService, userState);
  final firestoreService = FirestoreService();
  final swapService = SwapService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SkillState(FirestoreService()),
        ),
        Provider<MongoDBService>(
          create: (_) => mongoDBService,
        ),
        Provider<ProfileService>(
          create: (_) => profileService,
        ),
        Provider<SwapService>(
          create: (_) => swapService,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService()),
        ),
        ChangeNotifierProxyProvider<AuthController, UserState>(
          create: (_) => UserState(mongoDBService),
          update: (_, authController, previousState) {
            if (authController.currentUser?.uid != null) {
              print("Main: Updating UserState with uid: ${authController.currentUser?.uid}");
              return (previousState ?? UserState(mongoDBService))
                ..setCurrentUserId(authController.currentUser!.uid);
            }
            return previousState ?? UserState(mongoDBService);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => SkillState(firestoreService)
        ),
        ChangeNotifierProvider(
          create: (context) => ChatState(
            FirestoreService(),
            context.read<UserState>().currentUserId ?? '',
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SwapRequestState(
            SwapService(),
            context.read<UserState>().currentUserId ?? '',
          ),
        ),
      ],
      child:  MyApp(),
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
