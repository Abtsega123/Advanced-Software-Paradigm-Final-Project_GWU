// main_home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_app/chat/provider/provider.dart';
import 'package:flutter_firebase_chat_app/chat/screens/chat_list_screen.dart';
import 'package:flutter_firebase_chat_app/chat/screens/profile_screen.dart';
import 'package:flutter_firebase_chat_app/chat/screens/user_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainHomeScreen extends ConsumerStatefulWidget {
  const MainHomeScreen({super.key});

  @override
  ConsumerState<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends ConsumerState<MainHomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _hasInitialized = false;
  // Screens for each tab
  final List<Widget> _screens = [
    const ChatListScreen(),
    const UsersListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
        // Observe app lifecycle events (resumed, paused, etc.)
    WidgetsBinding.instance.addObserver(this);
        // Setup Firestore user doc & online status
    _initializeUserSession();
  }

  @override
  void dispose() {
        // Stop observing app lifecycle when screen is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Initialize user session and ensure user document exists in Firestore
  Future<void> _initializeUserSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Ensure user document exists in Firestore
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create user document if it doesn't exist
        await userDoc.set({
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'photoURL': user.photoURL,
          'provider': user.providerData.isNotEmpty
              ? (user.providerData.first.providerId == 'google.com'
                    ? 'google'
                    : 'email')
              : 'email',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update online status for existing user
        await userDoc.update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      // Force provider refresh after setup
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(usersProvider);
        ref.invalidate(requestsProvider);
        ref.invalidate(chatsProvider);

        setState(() {
          _hasInitialized = true; // Mark setup as complete
        });
      }
    } catch (e) {
      print('Error initializing user session: $e');
      if (mounted) {
        setState(() {
           // Still mark as complete (so app doesn’t hang)
          _hasInitialized = true;
        });
      }
    }
  }
  // ✅ Lifecycle changes: update Firestore online/offline status
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      switch (state) {
        case AppLifecycleState.resumed:
                  // App in foreground → mark user online
          _updateOnlineStatus(true);
          // Refresh providers when app resumes
          if (mounted) {
            ref.invalidate(usersProvider);
            ref.invalidate(requestsProvider);
            ref.invalidate(chatsProvider);
          }
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
                  // App in background/closed → mark user offline
          _updateOnlineStatus(false);
          break;
        default:
          break;
      }
    }
  }
  // ✅ Update user online status in Firestore
  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'isOnline': isOnline,
              'lastSeen': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        print('Error updating online status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading until initialization is complete
    if (!_hasInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up your account...'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,

        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade50,
        unselectedFontSize: 14,
        currentIndex: _currentIndex,
        // unselectedItemColor: Colors.black54,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh providers when switching tabs
          if (index == 1) {
            // Users tab
            ref.invalidate(usersProvider);
          } else if (index == 0) {
            // Chats tab
            ref.invalidate(chatsProvider);
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: 'Users',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
