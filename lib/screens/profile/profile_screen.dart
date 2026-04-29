import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/routes.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/widgets/doodle_app_bar.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final auth = context.read<AuthProvider>();
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final success = await auth.updateProfile(profileImage: File(image.path));
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to upload image')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showProfileImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: const DoodleAppBar(title: Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                    ? () => _showProfileImagePreview(user.profileImageUrl!)
                    : null,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                      ? Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                        )
                      : null,
                ),
              ),
              if (_isUploadingImage)
                const CircularProgressIndicator(color: AppTheme.primaryGreen),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user.fullName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(user.department, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          if (user.isAdmin)
            Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text('Admin', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),

          // Stats
          FutureBuilder<Map<String, int>>(
            future: context.read<ItemProvider>().getUserStats(user.uid),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {'totalReported': 0, 'resolved': 0};
              return Row(children: [
                _StatCard(label: 'Items Reported', value: '${stats['totalReported']}', icon: Icons.description_outlined),
                const SizedBox(width: 12),
                _StatCard(label: 'Items Resolved', value: '${stats['resolved']}', icon: Icons.check_circle_outline),
              ]);
            },
          ),
          const SizedBox(height: 24),

          // Info card
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Account Information', style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 20),
            _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
            _InfoTile(icon: Icons.badge_outlined, label: 'Matric No.', value: user.matricNumber),
            _InfoTile(icon: Icons.school_outlined, label: 'Faculty', value: user.faculty),
            _InfoTile(icon: Icons.account_balance_outlined, label: 'Department', value: user.department),
            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phoneNumber),
          ]))),
          const SizedBox(height: 16),

          // Actions
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.claims),
            icon: const Icon(Icons.receipt_long_outlined), label: const Text('My Claims'),
          )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async { 
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await auth.logout(); 
                if (context.mounted) context.go(AppRoutes.login); 
              }
            },
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label; final String value; final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Icon(icon, size: 28, color: AppTheme.primaryGreen),
      const SizedBox(height: 8),
      Text(value, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
    ]))));
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
    ]));
  }
}
