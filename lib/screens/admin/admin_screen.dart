import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/models/user_model.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lost_and_found/widgets/doodle_app_bar.dart';
import 'package:lost_and_found/widgets/item_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const DoodleAppBar(
          title: Text('Admin Panel'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [Tab(text: 'Dashboard'), Tab(text: 'All Items'), Tab(text: 'Users')],
          ),
        ),
        body: TabBarView(children: [
          _DashboardTab(),
          _AllItemsTab(),
          _UsersTab(),
        ]),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: context.read<ItemProvider>().getPlatformStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Platform Overview', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _StatTile(label: 'Total Items', value: '${stats['totalItems'] ?? 0}', icon: Icons.description, color: AppTheme.primaryGreen)),
              const SizedBox(width: 4),
              Expanded(child: _StatTile(label: 'Lost Items', value: '${stats['lostItems'] ?? 0}', icon: Icons.search_off, color: AppTheme.lostColor)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: _StatTile(label: 'Found Items', value: '${stats['foundItems'] ?? 0}', icon: Icons.inventory_2, color: AppTheme.foundColor)),
              const SizedBox(width: 4),
              Expanded(child: _StatTile(label: 'Active', value: '${stats['activeItems'] ?? 0}', icon: Icons.pending_actions, color: AppTheme.activeStatus)),
              const SizedBox(width: 4),
              Expanded(child: _StatTile(label: 'Resolved', value: '${stats['resolvedItems'] ?? 0}', icon: Icons.check_circle, color: AppTheme.resolvedStatus)),
            ]),
            const SizedBox(height: 24),
            Text('Recent Unresolved Items', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            StreamBuilder<List<ItemModel>>(
              stream: context.read<ItemProvider>().allItemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final items = (snapshot.data ?? [])
                    .where((i) => i.status == ItemStatus.active)
                    .take(5)
                    .toList();
                if (items.isEmpty) return const Text('No recent unresolved items.', style: TextStyle(color: AppTheme.textSecondary));
                return Column(
                  children: items.map((item) => ItemCard(
                    item: item, 
                    onTap: () => context.push('/item/${item.id}')
                  )).toList(),
                );
              },
            ),
          ]),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ]))
    );
  }
}

class _AllItemsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ItemModel>>(
      stream: context.read<ItemProvider>().allItemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return ListView.builder(itemCount: 5, itemBuilder: (_, _) => const ItemCardShimmer());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const EmptyState(icon: Icons.inbox, title: 'No Items', message: 'No items have been reported yet.');
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return Dismissible(
              key: Key(item.id), direction: DismissDirection.endToStart,
              background: Container(color: AppTheme.error, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white)),
              confirmDismiss: (_) => showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: const Text('Delete Item?'), content: Text('Delete "${item.title}"? This cannot be undone.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: const Text('Delete'))],
              )),
              onDismissed: (_) => context.read<ItemProvider>().deleteItem(item.id),
              child: ItemCard(item: item, onTap: () => context.push('/item/${item.id}')),
            );
          },
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: context.read<AuthProvider>().getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data ?? [];
        if (users.isEmpty) return const EmptyState(icon: Icons.people_outline, title: 'No Users', message: 'No users registered yet.');
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final user = users[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _showUserDetailSheet(context, user),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                        ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600))
                        : null,
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${user.department}\n${user.matricNumber}', style: const TextStyle(fontSize: 12)),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (role) => context.read<AuthProvider>().updateUserRole(user.uid, role),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'student', child: Text('Set Student')),
                      const PopupMenuItem(value: 'staff', child: Text('Set Staff')),
                      const PopupMenuItem(value: 'admin', child: Text('Set Admin')),
                    ],
                    child: StatusBadge(label: user.role.toUpperCase(), color: user.isAdmin ? AppTheme.primaryGreen : AppTheme.info),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetailSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final UserModel user;
  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                ? () => showDialog(context: context, builder: (_) => ImagePreviewDialog(imageUrl: user.profileImageUrl!))
                : null,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                  ? Text(user.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          StatusBadge(label: user.role.toUpperCase(), color: user.isAdmin ? AppTheme.primaryGreen : AppTheme.info),
          const SizedBox(height: 24),
          _UserDetailRow(icon: Icons.badge_outlined, label: 'Matric Number', value: user.matricNumber),
          _UserDetailRow(icon: Icons.business_outlined, label: 'Faculty', value: user.faculty),
          _UserDetailRow(icon: Icons.school_outlined, label: 'Department', value: user.department),
          _UserDetailRow(icon: Icons.email_outlined, label: 'Email Address', value: user.email),
          _UserDetailRow(icon: Icons.phone_outlined, label: 'Phone Number', value: user.phoneNumber),
          _UserDetailRow(icon: Icons.calendar_today_outlined, label: 'Joined On', value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _UserDetailRow extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _UserDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}
