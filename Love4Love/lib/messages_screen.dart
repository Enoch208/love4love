// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import for notifications
import 'package:intl/intl.dart'; // For date formatting for like reset, add to pubspec.yaml if not present

// For local notifications, ensure this plugin is initialized globally in main.dart.
// The local instance here is a fallback for demonstration if main.dart's isn't accessible.
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 0;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true; // To show loading indicator initially

  // --- Limited Likes Algorithm Variables ---
  static const int _maxLikesPerDay =
      15; // User can like up to 15 profiles per day
  int _likesRemaining = _maxLikesPerDay;
  DateTime? _lastLikeResetDate; // Stores the last date when likes were reset

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
    _initializeNotificationsLocal(); // Initialize local notifications
    // _resetLikesIfNeeded() is called in didChangeDependencies() to ensure BuildContext is available.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely call _resetLikesIfNeeded here to use BuildContext for SnackBar
    _resetLikesIfNeeded();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  // Local initialization for notifications (if not done globally in main.dart)
  Future<void> _initializeNotificationsLocal() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Use your app's launcher icon
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  // Fetch profiles from Firestore
  // Added a boolean parameter to determine if it's a 'latest profiles' fetch
  void _fetchProfiles({bool fetchLatest = false}) async {
    setState(() {
      _isLoadingProfiles = true; // Start loading
    });
    try {
      Query query = FirebaseFirestore.instance.collection('users');

      if (fetchLatest) {
        // Order by creation timestamp for 'latest' profiles
        query = query.orderBy('createdAt', descending: true);
      }
      query = query.limit(10); // Limit number of profiles fetched

      final querySnapshot = await query.get();

      setState(() {
        _profiles = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Store the Firestore document ID
          return data;
        }).toList();
        _isLoadingProfiles = false; // Finished loading
        if (_profiles.isEmpty) {
          _showSnackBar('No Profiles Found',
              'No profiles available to discover right now.',
              isError: true);
        } else {
          // Reset swiper to the first profile if new profiles are fetched
          _currentIndex = 0;
          _swiperController.move(_currentIndex);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingProfiles = false; // Finished loading (with error)
        _profiles = []; // Clear profiles on error
      });
      _showSnackBar('Error', 'Failed to fetch profiles: $e', isError: true);
      if (kDebugMode) {
        print(
            'Error fetching profiles: $e'); // Print error to console for debugging
      }
    }
  }

  // Show Get.snackbar message
  void _showSnackBar(String title, String message,
      {bool isSuccess = false, bool isError = false}) {
    Color backgroundColor = Colors.black87;
    if (isSuccess) {
      backgroundColor = Colors.green.withOpacity(0.8);
    } else if (isError) {
      backgroundColor = Colors.red.withOpacity(0.8);
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
    );
  }

  // Helper for showing local notifications
  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dating_app_channel', // ID for the notification channel
      'Dating App Notifications', // Name of the channel
      channelDescription: 'Notifications for dating app matches and messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x', // Optional payload
    );
  }

  // --- Limited Likes Logic ---
  void _resetLikesIfNeeded() {
    final now = DateTime.now();
    // Check if _lastLikeResetDate is null or if it's a new day
    if (_lastLikeResetDate == null ||
        _lastLikeResetDate!.day != now.day ||
        _lastLikeResetDate!.month != now.month ||
        _lastLikeResetDate!.year != now.year) {
      setState(() {
        _likesRemaining = _maxLikesPerDay; // Reset likes
        _lastLikeResetDate =
            DateTime(now.year, now.month, now.day); // Store today's date
        // In a real app, you would save _lastLikeResetDate and _likesRemaining to persistent storage
        // (e.g., SharedPreferences, Firestore) here.
        _showSnackBar(
            'Daily likes reset!', 'You have $_likesRemaining likes remaining.',
            isSuccess: true);
      });
    }
  }

  // Handle like action
  Future<void> _likeCurrentProfile() async {
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      _showSnackBar('No Profiles', 'No more profiles to like.');
      return;
    }

    // Check if like limit is reached
    if (_likesRemaining <= 0) {
      _showSnackBar('Limit Reached',
          'You have reached your daily like limit. Try again tomorrow!',
          isError: true);
      return;
    }

    final profile = _profiles[_currentIndex];
    final profileId = profile['id'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (profileId == null || currentUserId == null) {
      _showSnackBar('Error', 'Invalid profile or user ID for like operation.',
          isError: true);
      return;
    }

    setState(() {
      _likesRemaining--; // Decrement likes remaining
    });

    // Record the like in Firestore
    await FirebaseFirestore.instance.collection('likes').add({
      'from': currentUserId,
      'to': profileId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'like', // Explicitly mark as a like
    });

    // Check if it's a match (i.e., the other user also liked the current user)
    final matchQuery = await FirebaseFirestore.instance
        .collection('likes')
        .where('from', isEqualTo: profileId) // Other user liked current user
        .where('to', isEqualTo: currentUserId) // current user is the target
        .where('type', isEqualTo: 'like') // Ensure it's a 'like'
        .get();

    if (matchQuery.docs.isNotEmpty) {
      _showSnackBar(
          'It’s a Match!', 'You and ${profile['name']} liked each other!',
          isSuccess: true);
      await _showLocalNotification(
          '💘 It’s a Match!', 'You and ${profile['name']} liked each other!');

      // Store the match in a 'matches' collection to enable messaging
      // Create a unique chat ID using both user IDs, sorted for consistency
      final chatDocId = _getChatId(currentUserId, profileId);
      await FirebaseFirestore.instance.collection('chats').doc(chatDocId).set(
          {
            'user1': currentUserId,
            'user2': profileId,
            'participants': [
              currentUserId,
              profileId
            ], // Array for easy querying
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': 'Say hello to your new match!', // Initial message
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
          },
          SetOptions(
              merge: true)); // Use merge to avoid overwriting if chat exists
    } else {
      _showSnackBar(
          'Liked', '${profile['name']}! Likes left: $_likesRemaining');
    }

    _advanceProfile(); // Move to the next profile
  }

  // Handle dislike action
  Future<void> _dislikeCurrentProfile() async {
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      _showSnackBar('No Profiles', 'No more profiles to dislike.');
      return;
    }

    final profile = _profiles[_currentIndex];
    final profileId = profile['id'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (profileId == null || currentUserId == null) {
      _showSnackBar(
          'Error', 'Invalid profile or user ID for dislike operation.',
          isError: true);
      return;
    }

    // Record the dislike in Firestore (optional, for analytics/history)
    await FirebaseFirestore.instance.collection('dislikes').add({
      'from': currentUserId,
      'to': profileId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showSnackBar('Passed', 'on ${profile['name']}.');
    _advanceProfile(); // Move to the next profile
  }

  // Advances to the next profile or handles end of profiles
  void _advanceProfile() {
    if (_currentIndex < _profiles.length - 1) {
      _swiperController.next(animation: true);
    } else {
      // If no more profiles, display message or fetch more
      setState(() {
        _currentIndex = _profiles.length; // Indicate end of profiles
      });
      _showSnackBar('No more profiles to discover!', 'Tap refresh for more.');
    }
  }

  // Handle message action
  void _messageCurrentProfile() {
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      _showSnackBar(
          'No Profile Selected', 'Please select a profile to message.');
      return;
    }
    final profile = _profiles[_currentIndex];
    final profileId = profile['id'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (profileId == null || currentUserId == null) {
      _showSnackBar(
          'Error', 'Cannot message: User not logged in or profile ID missing.',
          isError: true);
      return;
    }

    // Determine the chat ID
    final chatDocId = _getChatId(currentUserId, profileId);

    // Check if a match exists before allowing message (optional but recommended)
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatDocId)
        .get()
        .then((chatDoc) {
      if (chatDoc.exists) {
        // If chat exists, navigate to chat screen
        Get.toNamed('/messages/chat', arguments: {
          'chatId': chatDocId,
          'otherUserId': profileId,
          'otherUserName': profile['name'],
          'otherUserAvatar': (profile['images'] as List<dynamic>?)
                      ?.isNotEmpty ==
                  true
              ? profile['images'][0].toString()
              : 'https://placehold.co/150x150/ccc/555?text=No+Image', // Fallback
          'isOtherUserOnline': (profile['isOnline'] as bool?) ?? false,
        });
        _showSnackBar(
            'Opening Chat', 'Chat with ${profile['name']} is opening.');
      } else {
        _showSnackBar(
            'No Match Yet', 'You can only message users you have matched with.',
            isError: true);
      }
    }).catchError((e) {
      _showSnackBar('Error', 'Failed to check chat status: $e', isError: true);
      if (kDebugMode) {
        print('Error checking chat status: $e');
      }
    });
  }

  // Handle super like action (no limit for super likes in this demo)
  Future<void> _superLikeCurrentProfile() async {
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      _showSnackBar('No Profiles', 'No more profiles to super like.');
      return;
    }
    final profile = _profiles[_currentIndex];
    final profileId = profile['id'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (profileId == null || currentUserId == null) {
      _showSnackBar(
          'Error', 'Invalid profile or user ID for super like operation.',
          isError: true);
      return;
    }

    // Record the super like in Firestore
    await FirebaseFirestore.instance.collection('likes').add({
      'from': currentUserId,
      'to': profileId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'super_like', // Explicitly mark as a super like
    });

    _showSnackBar('Super Liked!', 'You super liked ${profile['name']}!',
        isSuccess: true);
    _advanceProfile(); // Move to the next profile
  }

  // Build a unique chat ID from two user IDs (sorted to be consistent)
  String _getChatId(String user1Id, String user2Id) {
    return user1Id.compareTo(user2Id) < 0
        ? '${user1Id}_$user2Id'
        : '${user2Id}_$user1Id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Display remaining likes in the AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                'Likes: $_likesRemaining',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune,
                color: Colors.black), // Added Filter icon
            onPressed: () {
              _showSnackBar('Filter', 'Filter options coming soon!');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () =>
                _fetchProfiles(fetchLatest: false), // Default refresh
          ),
          IconButton(
            icon: const Icon(Icons.access_time,
                color: Colors.black), // Icon for 'Latest' profiles
            onPressed: () =>
                _fetchProfiles(fetchLatest: true), // Fetch latest profiles
            tooltip: 'View Latest Profiles',
          ),
        ],
      ),
      body: _isLoadingProfiles
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.pink)) // Show loading indicator
          : _profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        'No profiles available.\nTry refreshing or check your internet connection.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchProfiles,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Refresh Profiles',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Swiper(
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          // Wrap with GestureDetector for swipe
                          onPanEnd: (details) {
                            // Detect horizontal swipe direction based on velocity
                            if (details.velocity.pixelsPerSecond.dx > 500) {
                              _likeCurrentProfile(); // Swipe Right = Like
                            } else if (details.velocity.pixelsPerSecond.dx <
                                -500) {
                              _dislikeCurrentProfile(); // Swipe Left = Dislike
                            }
                          },
                          child: _buildProfileCard(_profiles[index]),
                        );
                      },
                      itemCount: _profiles.length,
                      controller: _swiperController,
                      layout: SwiperLayout.STACK,
                      itemWidth: MediaQuery.of(context).size.width *
                          0.9, // Increased width for better card visibility
                      itemHeight: MediaQuery.of(context).size.height *
                          0.75, // Increased height
                      loop: false,
                      viewportFraction:
                          0.85, // Slightly larger viewport to show more of the next card
                      scale: 0.9,
                      curve: Curves.easeInOut,
                      duration: 300,
                      onIndexChanged: (index) =>
                          setState(() => _currentIndex = index),
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable Swiper's default physics to allow custom GestureDetector
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.close,
                            color: Colors.redAccent,
                            onPressed: _dislikeCurrentProfile,
                            tag: 'dislikeBtn',
                          ),
                          const SizedBox(width: 20), // Spacing between buttons
                          _buildActionButton(
                            icon: Icons.message, // Message button
                            color: Colors.blueAccent,
                            onPressed: _messageCurrentProfile,
                            tag: 'messageBtn',
                          ),
                          const SizedBox(width: 20), // Spacing between buttons
                          _buildActionButton(
                            icon: Icons.favorite,
                            color: Colors.greenAccent,
                            onPressed: _likeCurrentProfile,
                            tag: 'likeBtn',
                          ),
                          const SizedBox(width: 20), // Spacing between buttons
                          _buildActionButton(
                            icon: Icons.star,
                            color: Colors.purpleAccent, // Super Like color
                            onPressed: _superLikeCurrentProfile,
                            tag: 'superLikeBtn',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Widget for building action buttons
  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed,
      required String tag}) {
    return FloatingActionButton(
      heroTag: tag, // Unique tag for each FloatingActionButton is crucial
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: color, // Set icon color explicitly
      elevation: 8, // Add shadow for depth
      shape: const CircleBorder(), // Make buttons circular
      child: Icon(icon, size: 36), // Increased icon size for prominence
    );
  }

  // Widget for building an individual profile card
  Widget _buildProfileCard(Map<String, dynamic> profile) {
    // Safely get profile data, providing fallbacks for missing fields
    final String imageUrl = (profile['image'] as String?) ??
        'https://placehold.co/150x150/ccc/555?text=No+Image';
    final String name = (profile['name'] as String?) ?? 'Unknown';
    final int age = (profile['age'] as int?) ?? 0;
    final String distance =
        (profile['distance'] as String?) ?? 'Unknown distance';
    final String bio = (profile['bio'] as String?) ?? 'No bio provided.';
    final List<dynamic> interestsRaw =
        (profile['interests'] as List<dynamic>?) ?? [];
    final List<String> interests =
        interestsRaw.map((e) => e.toString()).toList();
    final bool isOnline =
        (profile['isOnline'] as bool?) ?? true; // Assume online by default

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // PRIMARY IMAGE WITH ERROR HANDLING
            Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) {
                  print('Error loading image for $name: $error');
                }
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.pink[100],
                      child: const Icon(Icons.person,
                          size: 60, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            // GRADIENT OVERLAY for better text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87
                  ], // Stronger gradient at bottom
                ),
              ),
            ),
            // PROFILE INFO
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // Name, Age, and Online Indicator
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$name, $age',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      // Online Indicator
                      if (isOnline)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent, // Green for online
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(distance,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 18)),
                  const SizedBox(height: 10),
                  Text(bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 16)),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: interests.map((interest) {
                      return Chip(
                        label: Text(interest,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        backgroundColor: Colors.pink.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
