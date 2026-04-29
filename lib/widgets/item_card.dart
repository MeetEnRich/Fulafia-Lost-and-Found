import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:lost_and_found/config/theme.dart';
import 'package:lost_and_found/models/item_model.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == ItemType.lost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Thumbnail ──────────────────────────────────
                Hero(
                  tag: 'item_image_${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: SizedBox(
                      width: 85,
                      height: 85,
                      child: item.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: AppTheme.background,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, _, _) => _placeholderIcon(isLost),
                            )
                          : _placeholderIcon(isLost),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

              // ── Item Info ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + title row
                    Row(
                      children: [
                        _typeBadge(isLost),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location + time row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.campusLocation,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(item.dateReported),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _typeBadge(bool isLost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isLost ? AppTheme.lostColor : AppTheme.foundColor)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isLost ? AppTheme.lostColor : AppTheme.foundColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _placeholderIcon(bool isLost) {
    return Container(
      color: (isLost ? AppTheme.lostColor : AppTheme.foundColor)
          .withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          isLost ? Icons.search_off : Icons.inventory_2_outlined,
          color: isLost ? AppTheme.lostColor : AppTheme.foundColor,
          size: 32,
        ),
      ),
    );
  }
}
