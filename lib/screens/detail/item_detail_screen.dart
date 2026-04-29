import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/models/claim_model.dart';
import 'package:lost_and_found/providers/auth_provider.dart';
import 'package:lost_and_found/providers/item_provider.dart';
import 'package:lost_and_found/services/item_service.dart';
import 'package:lost_and_found/services/storage_service.dart';
import 'package:lost_and_found/utils/validators.dart';
import 'package:lost_and_found/widgets/common_widgets.dart';
import 'package:lost_and_found/widgets/claim_detail_sheet.dart';
import 'package:lost_and_found/widgets/doodle_app_bar.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DoodleAppBar(title: Text('Item Details')),
      body: FutureBuilder<ItemModel?>(
        future: ItemService().getItem(itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Item Not Found',
              message: 'This item may have been removed.',
            );
          }
          return _ItemDetailBody(item: snapshot.data!);
        },
      ),
    );
  }
}

// ── Image carousel with dots + tap-to-fullscreen ──────────────────────────────

class _ImageCarousel extends StatefulWidget {
  final String itemId;
  final List<String> imageUrls;
  const _ImageCarousel({required this.itemId, required this.imageUrls});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenImageViewer(
        imageUrls: widget.imageUrls,
        initialIndex: index,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullscreen(i),
              child: Hero(
                tag: i == 0 ? 'item_image_${widget.itemId}' : 'item_image_${widget.itemId}_$i',
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, _) => Container(
                    color: AppTheme.background,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppTheme.background,
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Dots indicator
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.imageUrls.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _current == i ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        // Tap hint icon
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullscreenImageViewer({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late int _current;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.imageUrls.length > 1
            ? Text('${_current + 1} / ${widget.imageUrls.length}')
            : null,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.imageUrls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _ItemDetailBody extends StatelessWidget {
  final ItemModel item;
  const _ItemDetailBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.user?.uid == item.reporterUid;
    final isLost = item.type == ItemType.lost;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (item.imageUrls.isNotEmpty)
          _ImageCarousel(itemId: item.id, imageUrls: item.imageUrls)
        else
          Container(
            height: 160,
            color: (isLost ? AppTheme.lostColor : AppTheme.foundColor).withValues(alpha: 0.08),
            child: Center(
              child: Icon(
                isLost ? Icons.search_off : Icons.inventory_2,
                size: 56,
                color: isLost ? AppTheme.lostColor : AppTheme.foundColor,
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              StatusBadge(
                label: isLost ? 'LOST' : 'FOUND',
                color: isLost ? AppTheme.lostColor : AppTheme.foundColor,
              ),
              const SizedBox(width: 8),
              StatusBadge(label: item.status.label, color: _statusColor(item.status)),
            ]),
            const SizedBox(height: 12),
            Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            _InfoRow(icon: Icons.category_outlined, label: 'Category', value: item.category),
            _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: item.campusLocation),
            if (item.specificLocation != null && item.specificLocation!.isNotEmpty)
              _InfoRow(icon: Icons.pin_drop_outlined, label: 'Specific', value: item.specificLocation!),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date ${isLost ? "Lost" : "Found"}',
              value: '${item.dateOccurred.day}/${item.dateOccurred.month}/${item.dateOccurred.year}',
            ),
            _InfoRow(icon: Icons.access_time, label: 'Reported', value: timeago.format(item.dateReported)),
            _InfoRow(icon: Icons.person_outlined, label: 'Reporter', value: item.reporterName),
            _InfoRow(icon: Icons.school_outlined, label: 'Department', value: item.reporterDepartment),
            const SizedBox(height: 24),

            if (isOwner && item.status == ItemStatus.active)
              PrimaryButton(
                label: 'Mark as Resolved',
                icon: Icons.check_circle,
                onPressed: () => _markResolved(context),
              ),

            if (isOwner && item.status == ItemStatus.active) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteItem(context),
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  label: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                ),
              ),
            ],

            if (!isOwner && item.status == ItemStatus.active) ...[
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Claim This Item',
                icon: Icons.front_hand,
                onPressed: () => _showClaimDialog(context),
              ),
            ],

            if (isOwner) ...[
              const SizedBox(height: 24),
              Text('Claims', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              _ClaimsList(itemId: item.id),
            ],
          ]),
        ),
      ]),
    );
  }

  Color _statusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.active:   return AppTheme.activeStatus;
      case ItemStatus.claimed:  return AppTheme.claimedStatus;
      case ItemStatus.resolved: return AppTheme.resolvedStatus;
      case ItemStatus.expired:  return AppTheme.resolvedStatus;
    }
  }

  void _markResolved(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Resolved?'),
        content: const Text('This means the item has been recovered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final provider = context.read<ItemProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final success = await provider.markAsResolved(item.id);
      if (success) {
        messenger.showSnackBar(SnackBar(content: Text(provider.successMessage ?? 'Resolved'), backgroundColor: AppTheme.success));
        nav.pop();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _deleteItem(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final provider = context.read<ItemProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final success = await provider.deleteItem(item.id);
      if (success) {
        messenger.showSnackBar(SnackBar(content: Text(provider.successMessage ?? 'Deleted'), backgroundColor: AppTheme.success));
        nav.pop();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _showClaimDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClaimSheet(item: item),
    );
  }
}

// ── Claim bottom sheet — keyboard-aware, scrollable, with image evidence ──────

class _ClaimSheet extends StatefulWidget {
  final ItemModel item;
  const _ClaimSheet({required this.item});

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _msgController = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _evidenceImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_evidenceImages.length >= 3) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _evidenceImages.add(File(picked.path)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<ItemProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    // Upload evidence images first
    List<String> evidenceUrls = [];
    if (_evidenceImages.isNotEmpty) {
      try {
        evidenceUrls = await StorageService().uploadItemImages(
          imageFiles: _evidenceImages,
          itemId: widget.item.id,
        );
      } catch (_) {
        // Evidence upload failed — continue without images rather than blocking the claim
      }
    }

    final claim = ClaimModel(
      id: '',
      itemId: widget.item.id,
      itemTitle: widget.item.title,
      claimantUid: auth.user!.uid,
      claimantName: auth.user!.fullName,
      claimantEmail: auth.user!.email,
      claimantPhone: auth.user!.phoneNumber,
      claimantProfileImageUrl: auth.user!.profileImageUrl,
      message: _msgController.text.trim(),
      evidenceImageUrls: evidenceUrls,
      createdAt: DateTime.now(),
    );

    final success = await provider.submitClaim(claim);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        nav.pop();
        messenger.showSnackBar(const SnackBar(
          content: Text('Claim submitted! The reporter will review it.'),
          backgroundColor: AppTheme.success,
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Failed to submit claim'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // padding accounts for keyboard height so the field is never covered
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Claim This Item', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Describe why this item belongs to you. Include identifying details.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Message field
              TextFormField(
                controller: _msgController,
                decoration: const InputDecoration(
                  labelText: 'Your claim message',
                  hintText: "e.g., It's a black phone with a cracked screen and red case...",
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                validator: Validators.claimMessage,
              ),
              const SizedBox(height: 16),

              // Evidence images (optional)
              Row(children: [
                Text('Photo Evidence', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 6),
                Text('(optional)', style: Theme.of(context).textTheme.labelSmall),
              ]),
              const SizedBox(height: 4),
              Text(
                'Add up to 3 photos to support your claim.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._evidenceImages.asMap().entries.map((e) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Image.file(e.value, width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _evidenceImages.removeAt(e.key)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )),
                  if (_evidenceImages.length < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.textSecondary, size: 28),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Claim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ── Claims list ───────────────────────────────────────────────────────────────

class _ClaimsList extends StatelessWidget {
  final String itemId;
  const _ClaimsList({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClaimModel>>(
      stream: context.read<ItemProvider>().itemClaimsStream(itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final claims = snapshot.data ?? [];
        if (claims.isEmpty) {
          return Text('No claims yet', style: Theme.of(context).textTheme.bodySmall);
        }
        return Column(children: claims.map((c) => _ClaimCard(claim: c)).toList());
      },
    );
  }
}

// ── Claim card with approve/reject + evidence images ─────────────────────────

class _ClaimCard extends StatelessWidget {
  final ClaimModel claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final claim = this.claim;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ClaimDetailSheet(claim: claim, showActions: true),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(claim.claimantName, style: const TextStyle(fontWeight: FontWeight.w600))),
              StatusBadge(
                label: claim.status.label,
                color: claim.isPending ? AppTheme.warning : claim.isApproved ? AppTheme.success : AppTheme.error,
              ),
            ]),
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
