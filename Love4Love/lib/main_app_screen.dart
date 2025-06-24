// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'discover_screen.dart';
import 'likes_screen.dart';
import 'notifications_screen.dart';
// Ensure MessagesScreen is correctly imported
import 'profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  final List<Widget> _screens = [
    const DiscoverScreen(),
    const LikesScreen(),
    const MessagesScreen(), // Now correctly referenced as a Widget
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications();
  }

  // Check for unread notifications
  Future<void> _checkUnreadNotifications() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Set up a listener for notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadNotifications = snapshot.docs.length;
      });
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const NotificationsScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Love4Love', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.pink),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _screens[_currentIndex], // Displays the selected screen based on current index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentIndex == 0
                  ? const Icon(Icons.home, key: ValueKey('home_filled'))
                  : const Icon(Icons.home_outlined, key: ValueKey('home_outlined')),
            ),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentIndex == 1
                  ? const Icon(Icons.favorite, key: ValueKey('favorite_filled'))
                  : const Icon(Icons.favorite_border, key: ValueKey('favorite_outlined')),
            ),
            label: 'Likes',
          ),
          BottomNavigationBarItem(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentIndex == 2
                  ? const Icon(Icons.chat, key: ValueKey('chat_filled'))
                  : const Icon(Icons.chat_bubble_outline, key: ValueKey('chat_outlined')),
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentIndex == 3
                  ? const Icon(Icons.person, key: ValueKey('person_filled'))
                  : const Icon(Icons.person_outline, key: ValueKey('person_outlined')),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Ensuring MessagesScreen is properly implemented as a StatelessWidget
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Messages Screen'),
      ),
    );
  }
}