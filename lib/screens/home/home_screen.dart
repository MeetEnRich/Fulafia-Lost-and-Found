import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/config/routes.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/services/notification_service.dart';
import 'package:lost_and_found/widgets/item_card.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 110.0,
              floating: true,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                title: Text(
                  'Hello, ${auth.user?.fullName.split(' ').first ?? 'Student'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryGreenLight, AppTheme.primaryGreen],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(Icons.lens_blur, size: 160, color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(Icons.lens_blur, size: 120, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push(AppRoutes.search),
                ),
                // Notification bell with unread badge
                if (uid.isNotEmpty)
                  StreamBuilder<int>(
                    stream: NotificationService().unreadCountStream(uid),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => context.push(AppRoutes.notifications),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                if (auth.isAdmin)
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () => context.push(AppRoutes.admin),
                  ),
              ],
            ),
          ];
        },
        body: IndexedStack(
          index: _currentTab,
          children: [
            _ItemFeed(
              stream: context.watch<ItemProvider>().lostItemsStream,
              emptyIcon: Icons.search_off,
              emptyTitle: 'No Lost Items',
              emptyMsg: 'No one has reported a lost item yet.',
            ),
            _ItemFeed(
              stream: context.watch<ItemProvider>().foundItemsStream,
              emptyIcon: Icons.inventory_2_outlined,
              emptyTitle: 'No Found Items',
              emptyMsg: 'No found items have been reported yet.',
            ),
            _UserItemsFeed(uid: uid),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_off_outlined),
            activeIcon: Icon(Icons.search_off),
            label: 'Lost',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Found',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'My Posts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.reportItem),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      drawer: _buildDrawer(context, auth),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        auth.user?.fullName.isNotEmpty == true
                            ? auth.user!.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(auth.user?.fullName ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(auth.user?.department ?? '',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.search);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.notifications);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('My Claims'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.claims);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.profile);
            },
          ),
          if (auth.isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.admin);
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              Navigator.pop(context); // close drawer first
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
          ),
        ],
      ),
    );
  }
}

class _ItemFeed extends StatelessWidget {
  final Stream<List<ItemModel>> stream;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMsg;

  const _ItemFeed({
    required this.stream,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ItemModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
              itemCount: 5, itemBuilder: (_, _) => const ItemCardShimmer());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            message: snapshot.error.toString(),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return EmptyState(icon: emptyIcon, title: emptyTitle, message: emptyMsg);
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, index) => ItemCard(
            item: items[index],
            onTap: () => context.push('/item/${items[index].id}'),
          ),
        );
      },
    );
  }
}

class _UserItemsFeed extends StatelessWidget {
  final String uid;
  const _UserItemsFeed({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const EmptyState(
          icon: Icons.person_off,
          title: 'Not Signed In',
          message: 'Please sign in to view your posts.');
    }
    return _ItemFeed(
      stream: context.read<ItemProvider>().userItemsStream(uid),
      emptyIcon: Icons.post_add,
      emptyTitle: 'No Posts Yet',
      emptyMsg:
          "You haven't reported any lost or found items yet.\nTap the + button to get started!",
    );
  }
}
