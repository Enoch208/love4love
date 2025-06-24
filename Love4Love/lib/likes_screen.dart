import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; // Import chat screen

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  String selectedSort = 'Most Recent';

  List<Map<String, dynamic>> likedByUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchLikesData();
  }

  // Fetching likes from Firestore
  void _fetchLikesData() async {
    final query = await FirebaseFirestore.instance
        .collection('likes')
        .where('to', isEqualTo: 'current_user_id') // Replace with current user ID
        .get();

    List<Map<String, dynamic>> users = [];
    for (var doc in query.docs) {
      final user = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc['from'])
          .get();
      final userData = user.data();
      users.add({
        'name': userData?['name'],
        'time': 'Just Now', // You can use DateTime to format time
        'mutual': false, // This will be updated when checking mutual likes
        'id': user.id,
        'image': userData?['image'] ?? 'default_image_url', // Placeholder image
      });
    }

    setState(() {
      likedByUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Likes', style: TextStyle(color: Colors.pink)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: selectedSort,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: ['Most Recent', 'Top Profiles']
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedSort = value!);
                // Implement sorting logic here if needed
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: likedByUsers.length,
              itemBuilder: (context, index) {
                final user = likedByUsers[index];
                return Dismissible(
                  key: Key(user['name']),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.thumb_up, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.remove_circle, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() => likedByUsers.removeAt(index));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(direction == DismissDirection.startToEnd
                          ? 'You liked back ${user['name']}'
                          : 'You removed ${user['name']}'),
                    ));
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink,
                      child: Icon(Icons.favorite, color: Colors.white),
                    ),
                    title: Text(user['name']),
                    subtitle: Text('liked you • ${user['time']}'),
                    trailing: Icon(
                      user['mutual'] ? Icons.favorite : Icons.favorite_border,
                      color: user['mutual'] ? Colors.red : Colors.grey,
                    ),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => Container(
                        padding: const EdgeInsets.all(16),
                        height: 280,
                        child: Column(
                          children: [
                            const Icon(Icons.person, size: 80, color: Colors.pink),
                            const SizedBox(height: 8),
                            Text('${user['name']}, 25', style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            const Text('Loves hiking and dogs 🐶'),
                            const Spacer(),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text("Say Hi"),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(userId: user['id']),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
