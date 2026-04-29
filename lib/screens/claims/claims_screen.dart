import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/models/claim_model.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';
import 'package:lost_and_found/widgets/claim_detail_sheet.dart';
import 'package:lost_and_found/widgets/doodle_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const DoodleAppBar(
          title: Text('Claims'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Incoming'), Tab(text: 'My Claims')],
          ),
        ),
        body: const TabBarView(children: [_IncomingClaims(), _MyClaims()]),
      ),
    );
  }
}

class _IncomingClaims extends StatelessWidget {
  const _IncomingClaims();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) {
      return const EmptyState(icon: Icons.inbox_outlined, title: 'Not signed in', message: 'Please sign in to view incoming claims.');
    }
    return StreamBuilder<List<ClaimModel>>(
      stream: context.read<ItemProvider>().incomingClaimsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return EmptyState(icon: Icons.error_outline, title: 'Error', message: snapshot.error.toString());
        final claims = snapshot.data ?? [];
        if (claims.isEmpty) return const EmptyState(icon: Icons.inbox_outlined, title: 'No Incoming Claims', message: 'Claims on your reported items will appear here.');
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: claims.length,
          itemBuilder: (_, i) => _ClaimTile(claim: claims[i], isIncoming: true),
        );
      },
    );
  }
}

class _MyClaims extends StatelessWidget {
  const _MyClaims();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) {
      return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Not signed in', message: 'Please sign in to view your claims.');
    }
    return StreamBuilder<List<ClaimModel>>(
      stream: context.read<ItemProvider>().userClaimsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return EmptyState(icon: Icons.error_outline, title: 'Error', message: snapshot.error.toString());
        final claims = snapshot.data ?? [];
        if (claims.isEmpty) return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No Claims Yet', message: "Claims you've submitted will appear here.");
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: claims.length,
          itemBuilder: (_, i) => _ClaimTile(claim: claims[i], isIncoming: false),
        );
      },
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final ClaimModel claim;
  final bool isIncoming;
  const _ClaimTile({required this.claim, required this.isIncoming});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ClaimDetailSheet(
              claim: claim, 
              showActions: isIncoming,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14), 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(claim.itemTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
              StatusBadge(label: claim.status.label, color: claim.isPending ? AppTheme.warning : claim.isApproved ? AppTheme.success : AppTheme.error),
            ]),
            const SizedBox(height: 4),
            if (isIncoming) 
              Row(
                children: [
                  GestureDetector(
                    onTap: (claim.claimantProfileImageUrl != null && claim.claimantProfileImageUrl!.isNotEmpty)
                        ? () => showDialog(context: context, builder: (_) => ImagePreviewDialog(imageUrl: claim.claimantProfileImageUrl!))
                        : null,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      backgroundImage: (claim.claimantProfileImageUrl != null && claim.claimantProfileImageUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(claim.claimantProfileImageUrl!)
                          : null,
                      child: (claim.claimantProfileImageUrl == null || claim.claimantProfileImageUrl!.isEmpty)
                          ? Text(claim.claimantName[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.primaryGreen))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('From: ${claim.claimantName}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            const SizedBox(height: 6),
            Text(claim.message, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeago.format(claim.createdAt), style: Theme.of(context).textTheme.labelSmall),
                if (claim.evidenceImageUrls.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${claim.evidenceImageUrls.length} photos', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
              ]
            ),
            const SizedBox(height: 8),
            const Text('Tap to view full details', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontStyle: FontStyle.italic)),
          ]),
        ),
      ),
    );
  }
}

