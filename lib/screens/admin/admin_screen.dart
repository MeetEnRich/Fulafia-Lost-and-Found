import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/models/user_model.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/widgets/item_card.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(tabs: [Tab(text: 'Dashboard'), Tab(text: 'All Items'), Tab(text: 'Users')]),
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
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
              children: [
                _StatTile(label: 'Total Items', value: '${stats['totalItems'] ?? 0}', icon: Icons.description, color: AppTheme.primaryGreen),
                _StatTile(label: 'Lost Items', value: '${stats['lostItems'] ?? 0}', icon: Icons.search_off, color: AppTheme.lostColor),
                _StatTile(label: 'Found Items', value: '${stats['foundItems'] ?? 0}', icon: Icons.inventory_2, color: AppTheme.foundColor),
                _StatTile(label: 'Active', value: '${stats['activeItems'] ?? 0}', icon: Icons.pending_actions, color: AppTheme.activeStatus),
                _StatTile(label: 'Resolved', value: '${stats['resolvedItems'] ?? 0}', icon: Icons.check_circle, color: AppTheme.resolvedStatus),
              ],
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
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 8),
      Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
    ])));
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
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600))),
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
            );
          },
        );
      },
    );
  }
}
