// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get current user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to potentially fetch user data

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for editable fields
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // List of interests for the user's profile
  List<String> _interests = [];

  // List of profile image paths. Will be loaded dynamically or use placeholders.
  List<String> _profileImages = [];
  bool _isLoading = true; // State for loading user data

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user data when screen initializes
  }

  // Fetch user profile data from Firestore
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Error', 'User not logged in.', isError: true);
      setState(() {
        _isLoading = false;
        // Provide default empty values if no user or data
        _nameController.text = 'Guest';
        _locationController.text = 'N/A';
        _ageController.text = '0';
        _bioController.text = 'Please log in to view your profile.';
        _profileImages = ['assets/placeholder_image.jpg']; // Fallback image
      });
      return;
    }

    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        _nameController.text = (userData['name'] as String?) ?? 'Your Name';
        _ageController.text = (userData['age'] as int?)?.toString() ?? '25';
        _locationController.text = (userData['location'] as String?) ?? 'City, State';
        _bioController.text = (userData['bio'] as String?) ?? 'Tell us about yourself...';
        
        // Handle images: Expecting a List<String> of image URLs
        final List<dynamic>? imagesData = userData['images'] as List<dynamic>?;
        if (imagesData != null && imagesData.isNotEmpty) {
          _profileImages = imagesData.map((e) => e.toString()).toList();
        } else {
          _profileImages = ['assets/placeholder_image.jpg']; // Default placeholder
        }

        // Handle interests: Expecting a List<String>
        final List<dynamic>? interestsData = userData['interests'] as List<dynamic>?;
        if (interestsData != null && interestsData.isNotEmpty) {
          _interests = interestsData.map((e) => e.toString()).toList();
        } else {
          _interests = []; // Default empty list
        }

      } else {
        // Document doesn't exist, create a basic profile or show defaults
        _showSnackBar('Profile Not Found', 'Creating a default profile for you...');
        _nameController.text = 'New User';
        _ageController.text = '20';
        _locationController.text = 'Unknown';
        _bioController.text = 'Welcome to Love4Love!';
        _profileImages = ['assets/placeholder_image.jpg']; // Default placeholder
        _interests = [];
        // Optionally, save this default profile to Firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'name': 'New User',
          'age': 20,
          'location': 'Unknown',
          'bio': 'Welcome to Love4Love!',
          'images': ['assets/placeholder_image.jpg'],
          'interests': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _showSnackBar('Error', 'Failed to load profile: $e', isError: true);
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      // Fallback to default placeholders on error
      _nameController.text = 'Error Loading';
      _locationController.text = 'N/A';
      _ageController.text = '0';
      _bioController.text = 'Could not load profile data.';
      _profileImages = ['assets/placeholder_image.jpg']; // Fallback image
      _interests = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to simulate adding a new photo
  void _addNewPhoto() {
    // In a real app, this would open an image picker and upload to storage (e.g., Firebase Storage).
    // For demonstration, we add a new placeholder image URL.
    setState(() {
      if (_profileImages.length < 10) { // Limit to 10 photos for demo
        _profileImages.add('https://placehold.co/600x400/FF69B4/FFFFFF?text=New+Photo+${_profileImages.length + 1}');
        _showSnackBar('Photo Added!', 'A new photo has been added to your profile.');
      } else {
        _showSnackBar('Limit Reached', 'You can add up to 10 photos.', isError: true);
      }
    });
  }

  // Function to save the profile (simulated)
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true; // Show loading
    });
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Error', 'Cannot save: User not logged in.', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': _interests,
        'images': _profileImages, // Save image URLs
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Profile Saved!', 'Your profile has been updated successfully.', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error', 'Failed to save profile: $e', isError: true);
      if (kDebugMode) {
        print('Error saving profile: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to show a SnackBar (consistent with other screens)
  void _showSnackBar(String title, String message, {bool isSuccess = false, bool isError = false}) {
    Color backgroundColor = Colors.black87;
    if (isSuccess) {
      backgroundColor = Colors.green.withOpacity(0.8);
    } else if (isError) {
      backgroundColor = Colors.red.withOpacity(0.8);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // Extends body behind app bar for full image effect
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _saveProfile, // Use edit icon to save profile
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              _showSnackBar('Share Profile', 'Share functionality coming soon!');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Profile Images Swiper Section ---
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: const BoxDecoration(
                    color: Colors.black, // Background for swiper area
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Swiper(
                    itemBuilder: (context, index) {
                      final imageUrl = _profileImages[index];
                      // Use Image.network for external URLs, Image.asset for local
                      return ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: imageUrl.startsWith('assets/')
                            ? Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                    ),
                                  );
                                },
                              )
                            : Image.network( // For network images
                                imageUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  if (kDebugMode) {
                                    print('Error loading network image: $error');
                                  }
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                    itemCount: _profileImages.length,
                    pagination: SwiperPagination(
                      alignment: Alignment.bottomCenter,
                      builder: DotSwiperPaginationBuilder(
                        color: Colors.white.withOpacity(0.5),
                        activeColor: Colors.pink,
                        size: 8.0,
                        activeSize: 10.0,
                        space: 4.0,
                      ),
                    ),
                    autoplay: false, // Set to true if you want auto-slide
                    duration: 800,
                    autoplayDelay: 4000,
                    loop: false, // Changed to false for profile view
                  ),
                ),
                // Main Profile Avatar (overlaps with content below)
                Positioned(
                  bottom: -60,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 75,
                        // Use the first image for the main avatar
                        backgroundImage: _profileImages.isNotEmpty
                            ? (_profileImages[0].startsWith('assets/') ? AssetImage(_profileImages[0]) : NetworkImage(_profileImages[0]) as ImageProvider)
                            : const AssetImage('assets/placeholder_image.jpg'), // Fallback
                        onBackgroundImageError: (exception, stackTrace) {
                          if (kDebugMode) {
                            print('Error loading main avatar image: $exception');
                          }
                        },
                      ),
                    ),
                  ),
                ),
                // Add Photo Button positioned within the image section
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 15,
                  child: FloatingActionButton(
                    heroTag: 'addPhotoBtn',
                    mini: true,
                    backgroundColor: Colors.pink.withOpacity(0.9),
                    onPressed: _addNewPhoto,
                    child: const Icon(Icons.add_a_photo, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80), // Space for the overlapping avatar

            // --- User Name, Age, Location Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Your Name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50, // Fixed width for age to prevent layout shift
                    child: TextField(
                      controller: _ageController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Age',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _locationController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'City, State',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),

            // --- Bio Section (About Me) ---
            _buildInfoSection('About Me', _bioController, Icons.person_outline),

            const SizedBox(height: 20),

            // --- Interests Section ---
            _buildInterests(Icons.favorite_border),

            const SizedBox(height: 30),

            // --- Action Buttons ---
            _buildActionButton('Add New Interest', Icons.add_circle_outline, _addNewInterest, isPrimary: false),
            const SizedBox(height: 15),
            _buildActionButton('Save Profile', Icons.check_circle_outline, _saveProfile, isPrimary: true),
            const SizedBox(height: 40),

            // --- Settings, Privacy, Help & Support, Logout Section ---
            _buildOptionSection(),

            const SizedBox(height: 40), // Additional spacing at the bottom
          ],
        ),
      ),
    );
  }

  // Widget to build information sections (like About Me)
  Widget _buildInfoSection(String title, TextEditingController controller, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.pink, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build the interests section
  Widget _buildInterests(IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.pink, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'My Interests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _interests.isEmpty
                ? const Text('No interests added yet.', style: TextStyle(color: Colors.grey))
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _interests
                        .map((interest) => Chip(
                              label: Text(
                                interest,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: Colors.pink.withOpacity(0.8),
                              deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _interests.remove(interest);
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide.none,
                              ),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // Widget to build action buttons
  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, {bool isPrimary = false}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Colors.pinkAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(30),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : Colors.grey[200],
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        icon: Icon(icon, size: 24),
        label: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // New section for settings, privacy, help & support, logout
  Widget _buildOptionSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildOptionTile(Icons.settings, 'Settings', () => _showSnackBar('Settings', 'Settings Tapped!')),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildOptionTile(Icons.lock_outline, 'Privacy', () => _showSnackBar('Privacy', 'Privacy Tapped!')),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildOptionTile(Icons.help_outline, 'Help & Support', () => _showSnackBar('Help & Support', 'Help & Support Tapped!')),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildOptionTile(Icons.logout, 'Logout', () => _showLogoutConfirmation(), isDestructive: true),
        ],
      ),
    );
  }

  // Helper for building individual option tiles
  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          color: isDestructive ? Colors.redAccent : Colors.black87,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }

  // Function to add a new interest
  void _addNewInterest() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController interestController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Add New Interest', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: interestController,
            decoration: InputDecoration(
              hintText: 'e.g., Photography',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (interestController.text.isNotEmpty) {
                  setState(() => _interests.add(interestController.text.trim()));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                // Navigate to the login screen after logout
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); // Assuming '/login' is your login route
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
