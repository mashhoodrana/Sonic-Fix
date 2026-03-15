import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current user data
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _usernameController.text = user.displayName ?? "";
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePhoto() async {
     try {
       final ImagePicker picker = ImagePicker();
       final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
       
       if (image == null) return;

       setState(() => _isLoading = true);

       final user = FirebaseAuth.instance.currentUser;
       if (user == null) return;

       // 1. Upload to Firebase Storage
       final storageRef = FirebaseStorage.instance
           .ref()
           .child('users/${user.uid}/profile_photo.jpg');
       
       await storageRef.putFile(File(image.path));
       
       // 2. Get Download URL
       final downloadUrl = await storageRef.getDownloadURL();

       // 3. Update User Profile
       await user.updatePhotoURL(downloadUrl);
       await user.reload();
       ref.refresh(currentUserProvider);

       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Profile photo updated!"))
           );
       }
     } catch (e) {
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Error: $e")));
       }
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  Future<void> _saveProfile() async {
      setState(() => _isLoading = true);
      try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
              await user.updateDisplayName(_usernameController.text.trim());
              await user.reload(); // Refresh user data
              ref.refresh(currentUserProvider); // Refresh provider
              if (mounted) {
                  setState(() => _isEditing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile updated successfully"))
                  );
              }
          }
      } catch (e) {
          if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          }
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    // Update controller if not editing and value changed (e.g. initial load)
    if (!_isEditing && _usernameController.text != (user.displayName ?? "")) {
         _usernameController.text = user.displayName ?? "";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
            if (!_isEditing)
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
                child: Stack(
                    children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? Icon(Icons.person, size: 60, color: theme.colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                radius: 20,
                                child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                    onPressed: _updateProfilePhoto,
                                ),
                            ),
                        )
                    ],
                )
            ),
            const SizedBox(height: 32),
            
            // Username Field
            TextFormField(
                controller: _usernameController,
                enabled: _isEditing,
                decoration: InputDecoration(
                    labelText: "Username",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
            ),
            const SizedBox(height: 16),
            
            // Email Field (Read-only)
            TextFormField(
                initialValue: user.email,
                enabled: false,
                decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
            ),
            
            const SizedBox(height: 32),
            
            if (_isEditing)
                if (_isLoading)
                    const CircularProgressIndicator()
                else
                    Row(
                        children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () {
                                        setState(() {
                                            _isEditing = false;
                                            _usernameController.text = user.displayName ?? "";
                                        });
                                    },
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                    child: const Text("Cancel"),
                                ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: FilledButton(
                                    onPressed: _saveProfile,
                                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                    child: const Text("Save Changes"),
                                ),
                            ),
                        ],
                    ),
          ],
        ),
      ),
    );
  }
}
