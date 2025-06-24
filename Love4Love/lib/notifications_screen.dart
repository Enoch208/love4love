import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Fetch all notifications for the current user
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
        _showSnackBar('Error', 'User not logged in.', isError: true);
        return;
      }

      // Get notifications from Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> notifications = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        notifications.add({
          'id': doc.id,
          ...data,
        });
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      // Mark all unread notifications as read
      _markAllAsRead(snapshot.docs);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error', 'Failed to load notifications: $e', isError: true);
    }
  }

  // Mark all notifications as read
  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    for (final doc in docs) {
      if (!(doc.data() as Map<String, dynamic>)['read']) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'read': true});
      }
    }
  }

  // Format timestamp to a readable date
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Show snackbar for messages
  void _showSnackBar(String title, String message, {bool isSuccess = false, bool isError = false}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        'No notifications yet.\nYou\'ll be notified when someone likes your profile!',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final bool isRead = notification['read'] ?? false;
                    final String type = notification['type'] ?? 'like';
                    
                    return Dismissible(
                      key: Key(notification['id']),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        // Remove from UI
                        setState(() {
                          _notifications.removeAt(index);
                        });
                        
                        // Delete from Firestore
                        try {
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(notification['id'])
                              .delete();
                          _showSnackBar('Success', 'Notification deleted', isSuccess: true);
                        } catch (e) {
                          _showSnackBar('Error', 'Failed to delete notification', isError: true);
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: type == 'match' ? Colors.pink : Colors.pinkAccent.withOpacity(0.7),
                          child: Icon(
                            type == 'match' ? Icons.favorite : Icons.thumb_up,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notification['title'] ?? 'New Notification',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notification['body'] ?? ''),
                        trailing: Text(
                          _formatTimestamp(notification['timestamp']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        tileColor: isRead ? null : Colors.pink.withOpacity(0.05),
                        onTap: () {
                          // Handle notification tap - could navigate to profile or chat
                          if (type == 'match') {
                            // Navigate to chat with the matched user
                            _showSnackBar('Match', 'Opening chat...', isSuccess: true);
                            // Get.toNamed('/chat_screen', arguments: {'userId': notification['fromUserId']});
                          } else if (type == 'like') {
                            // Navigate to the user's profile
                            _showSnackBar('Like', 'Opening profile...', isSuccess: true);
                            // Get.toNamed('/profile_view', arguments: {'userId': notification['fromUserId']});
                          }
                          
                          // Mark as read if not already
                          if (!isRead) {
                            FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(notification['id'])
                                .update({'read': true});
                            
                            setState(() {
                              _notifications[index]['read'] = true;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 