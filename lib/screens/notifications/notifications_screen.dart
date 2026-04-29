import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/services/notification_service.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/widgets/claim_detail_sheet.dart';
import 'package:lost_and_found/widgets/doodle_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: DoodleAppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear read',
            onPressed: uid.isEmpty ? null : () => NotificationService().deleteReadNotifications(uid),
          ),
          TextButton(
            onPressed: uid.isEmpty ? null : () => NotificationService().markAllAsRead(uid),
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Not signed in',
              message: 'Sign in to see your notifications.',
            )
          : StreamBuilder<List<AppNotification>>(
              stream: NotificationService().notificationsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Error',
                    message: snapshot.error.toString(),
                  );
                }
                final notifs = snapshot.data ?? [];
                if (notifs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'No Notifications',
                    message:
                        'You will be notified when someone claims your item or your claim is reviewed.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifs.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) => _NotifTile(notif: notifs[i], uid: uid),
                );
              },
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final String uid;
  const _NotifTile({required this.notif, required this.uid});

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.claimReceived:
        return Icons.inbox;
      case NotificationType.claimApproved:
        return Icons.check_circle;
      case NotificationType.claimRejected:
        return Icons.cancel;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color get _iconColor {
    switch (notif.type) {
      case NotificationType.claimReceived:
        return AppTheme.info;
      case NotificationType.claimApproved:
        return AppTheme.success;
      case NotificationType.claimRejected:
        return AppTheme.error;
      case NotificationType.general:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (!notif.isRead) NotificationService().markAsRead(uid, notif.id);
        
        if (notif.claimId != null) {
          showDialog(
            context: context, 
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator())
          );
          
          final claim = await context.read<ItemProvider>().getClaim(notif.claimId!);
          
          if (context.mounted) {
            Navigator.pop(context); // close dialog
            if (claim != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ClaimDetailSheet(
                  claim: claim, 
                  // It's incoming if the current user is the reporter, i.e., not the claimant.
                  showActions: claim.claimantUid != uid,
                ),
              );
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Claim not found or deleted')),
              );
            }
          }
        }
        
        if (notif.itemId != null && context.mounted) context.push('/item/${notif.itemId}');
      },
      child: Container(
        color: notif.isRead ? null : AppTheme.primaryGreen.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!notif.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(
                notif.body,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(timeago.format(notif.createdAt),
                  style: Theme.of(context).textTheme.labelSmall),
            ]),
          ),
        ]),
      ),
    );
  }
}
