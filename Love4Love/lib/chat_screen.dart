import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    _currentUserId = 'current_user_id'; // Replace with the actual user ID
    chatRoomId = _getChatRoomId(_currentUserId, widget.userId);
  }

  String _getChatRoomId(String user1, String user2) {
    // Sort user IDs to generate a consistent chat room ID
    return user1.hashCode <= user2.hashCode ? '${user1}_$user2' : '${user2}_$user1';
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add message to Firestore in the specific chat room
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'from': _currentUserId,
      'to': widget.userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Clear the text field and scroll to bottom
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isCurrentUser = message['from'] == _currentUserId;

                    return ListTile(
                      title: Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Text(
                            message['message'],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      subtitle: Text(message['timestamp'].toDate().toString()),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
