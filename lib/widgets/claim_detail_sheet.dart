import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/models/claim_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/services/auth_service.dart';
import 'package:lost_and_found/models/user_model.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';

class ClaimDetailSheet extends StatelessWidget {
  final ClaimModel claim;
  final bool showActions;
  
  const ClaimDetailSheet({
    super.key,
    required this.claim,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Claim Details', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Status Badge
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
              StatusBadge(
                label: claim.status.label, 
                color: claim.isPending ? AppTheme.warning : claim.isApproved ? AppTheme.success : AppTheme.error
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Claimant Info
          const Text('Claimant:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(claim.claimantName, style: const TextStyle(fontSize: 16)),
          Text('Submitted ${timeago.format(claim.createdAt)}', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          
          // Message
          const Text('Message:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(claim.message, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 16),
          
          // Evidence Images
          if (claim.evidenceImageUrls.isNotEmpty) ...[
            const Text('Evidence Images:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: claim.evidenceImageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: claim.evidenceImageUrls[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (_, _, _) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Contact details if approved
          if (claim.isApproved) ...[
            Builder(builder: (context) {
              final uid = context.read<AuthProvider>().user?.uid;
              final isClaimant = uid == claim.claimantUid;

              if (!isClaimant) {
                // Show Claimant details
                return _buildContactBox(
                  title: 'Claimant Contact Details:',
                  name: claim.claimantName,
                  phone: claim.claimantPhone,
                  email: claim.claimantEmail,
                );
              }

              // Show Reporter details
              return FutureBuilder<UserModel?>(
                future: _fetchReporter(context, claim.itemId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final reporter = snapshot.data;
                  if (reporter == null) {
                    return const Text('Could not load reporter details.', style: TextStyle(color: AppTheme.error));
                  }
                  return _buildContactBox(
                    title: 'Reporter Contact Details:',
                    name: reporter.fullName,
                    phone: reporter.phoneNumber,
                    email: reporter.email,
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
          
          // Actions
          if (showActions && claim.isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final provider = context.read<ItemProvider>();
                      final success = await provider.rejectClaim(claim.id);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.successMessage ?? 'Claim rejected'), backgroundColor: AppTheme.success));
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to reject claim'), backgroundColor: AppTheme.error));
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = context.read<ItemProvider>();
                      final success = await provider.approveClaim(claim);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.successMessage ?? 'Claim approved'), backgroundColor: AppTheme.success));
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to approve claim'), backgroundColor: AppTheme.error));
                        }
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Future<UserModel?> _fetchReporter(BuildContext context, String itemId) async {
    final item = await context.read<ItemProvider>().getItem(itemId);
    if (item != null) {
      return await AuthService().getUserProfile(item.reporterUid);
    }
    return null;
  }

  Widget _buildContactBox({
    required String title,
    required String name,
    required String phone,
    required String email,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success)),
          const SizedBox(height: 16),
          _ContactRow(
            icon: Icons.person_outlined,
            label: name,
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: phone,
            actionIcon: Icons.call,
            actionColor: AppTheme.success,
            onAction: () async {
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.email_outlined,
            label: email,
            actionIcon: Icons.send,
            actionColor: AppTheme.primaryGreen,
            onAction: () async {
              final uri = Uri(scheme: 'mailto', path: email);
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),
        ]
      )
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? actionIcon;
  final Color? actionColor;
  final VoidCallback? onAction;

  const _ContactRow({
    required this.icon,
    required this.label,
    this.actionIcon,
    this.actionColor,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: AppTheme.textSecondary),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      if (actionIcon != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (actionColor ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(actionIcon, size: 20, color: actionColor ?? AppTheme.primaryGreen),
          ),
        ),
    ]);
  }
}
