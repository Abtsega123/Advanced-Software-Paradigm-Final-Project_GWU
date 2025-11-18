import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_app/auth/screen/user_login_screen.dart';
import 'package:flutter_firebase_chat_app/chat/provider/provider.dart';
import 'package:flutter_firebase_chat_app/core/secret/secret.dart';
import 'package:flutter_firebase_chat_app/core/wrapper%20state/authentication_wrapper.dart';
import 'package:flutter_firebase_chat_app/firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request permissions before initializing Zego
  await requestPermissions();
  final user = FirebaseAuth.instance.currentUser;
  final String userID = user?.uid ?? "0123";
  final String userName = user?.displayName ?? "Guest";

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  // Initialize Zego invitation service
  await ZegoUIKitPrebuiltCallInvitationService()
      .init(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        ),
      )
      .catchError((error) {
        print("Zego initialization error: $error");
      });
      
  runApp(ProviderScope(child: MyApp(navigatorKey: navigatorKey)));
}

// 🔔 Request camera, mic, and notification permissions
Future<void> requestPermissions() async {
  await [
    Permission.camera,
    Permission.microphone,
    Permission.notification, // Needed for Android 13+
  ].request();
}

class MyApp extends ConsumerStatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({super.key, required this.navigatorKey});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
        // Watching authStateProvider -> listens to Firebase auth changes
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
            // authState.when() handles auth state changes
      home: authState.when(
        data: (user) {
          // If user is logged in, go to AuthenticatedWrapper
          if (user != null) {
            return const AuthenticatedWrapper();
          } else {
              // If not logged in, go to Login screen
            return const UserLoginScreen();
          }
        },
        // While checking login state -> show loader
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                   // Retry by refreshing the provider
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
