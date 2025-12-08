import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/data/user_info.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedImage;
  bool _isUploadingAvatar = false;
  bool _isEditingUsername = false;
  bool _isUpdatingUsername = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = currentUser?.username ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Profile Picture Section
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (currentUser?.profilePicUrl != null && currentUser!.profilePicUrl!.isNotEmpty
                          ? NetworkImage(currentUser!.profilePicUrl!)
                          : null),
                  child: _selectedImage == null && (currentUser?.profilePicUrl == null || currentUser!.profilePicUrl!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.primary.withOpacity(0.5),
                        )
                      : null,
                ),
                if (_isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _isUploadingAvatar ? null : _pickAndUploadImage,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Username Edit Field
            _buildUsernameField(),

            const SizedBox(height: 16),

            // Note about backend limitations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Available Features',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('✓', 'Upload & manage profile picture'),
                  _buildFeatureItem('✓', 'View your username & role'),
                  _buildFeatureItem('✓', 'View & manage your surveys'),
                  _buildFeatureItem('✓', 'Secure logout'),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Additional profile fields (name, email, phone, bio, etc.) will be available in future updates as backend support is added.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              if (!_isEditingUsername && !_isUpdatingUsername)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    setState(() {
                      _isEditingUsername = true;
                    });
                  },
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditingUsername)
            Column(
              children: [
                TextField(
                  controller: _usernameController,
                  enabled: !_isUpdatingUsername,
                  decoration: InputDecoration(
                    hintText: 'Enter new username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '4-36 characters, no spaces',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUpdatingUsername
                            ? null
                            : () {
                                setState(() {
                                  _isEditingUsername = false;
                                  _usernameController.text =
                                      currentUser?.username ?? '';
                                });
                              },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdatingUsername
                            ? null
                            : _updateUsername,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isUpdatingUsername
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              currentUser?.username ?? 'Not set',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newUsername == currentUser?.username) {
      setState(() {
        _isEditingUsername = false;
      });
      return;
    }

    setState(() {
      _isUpdatingUsername = true;
    });

    try {
      final response = await AuthAPI.updateUsername(newUsername);
      
      if (mounted) {
        if (response['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditingUsername = false;
          });
          // Return true to indicate profile was updated
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update username'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingUsername = false;
        });
      }
    }
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUploadingAvatar = true;
        });
        
        // Upload the avatar
        final response = await AuthAPI.uploadAvatar(_selectedImage!);
        
        if (mounted) {
          if (response['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Return true to indicate success
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Failed to upload avatar'),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() {
              _selectedImage = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _selectedImage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }
}
