import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_and_found/models/item_model.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('items');

  // ── Create ──────────────────────────────────────────────────────────────

  /// Create a new lost/found item report.
  Future<String> createItem(ItemModel item) async {
    final docRef = _itemsRef.doc();
    final itemWithId = ItemModel(
      id: docRef.id,
      title: item.title,
      description: item.description,
      type: item.type,
      category: item.category,
      campusLocation: item.campusLocation,
      specificLocation: item.specificLocation,
      imageUrls: item.imageUrls,
      dateOccurred: item.dateOccurred,
      dateReported: DateTime.now(),
      reporterUid: item.reporterUid,
      reporterName: item.reporterName,
      reporterDepartment: item.reporterDepartment,
      status: ItemStatus.active,
      searchKeywords: ItemModel.generateKeywords(item.title, item.description),
    );

    await docRef.set(itemWithId.toMap());
    return docRef.id;
  }

  // ── Read ────────────────────────────────────────────────────────────────

  /// Stream all items of a given type, ordered by most recent.
  /// Uses only equality filters to avoid composite index requirements.
  Stream<List<ItemModel>> streamItems({
    required ItemType type,
    int limit = 50,
  }) {
    return _itemsRef
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: ItemStatus.active.name)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
              .toList();
          items.sort((a, b) => b.dateReported.compareTo(a.dateReported));
          return items;
        });
  }

  /// Stream all items (for admin view).
  Stream<List<ItemModel>> streamAllItems({int limit = 50}) {
    return _itemsRef
        .orderBy('dateReported', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream items reported by a specific user.
  /// Sorted client-side to avoid composite index requirement.
  Stream<List<ItemModel>> streamUserItems(String uid) {
    return _itemsRef
        .where('reporterUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
              .toList();
          items.sort((a, b) => b.dateReported.compareTo(a.dateReported));
          return items;
        });
  }

  /// Get a single item by ID.
  Future<ItemModel?> getItem(String itemId) async {
    final doc = await _itemsRef.doc(itemId).get();
    if (!doc.exists) return null;
    return ItemModel.fromMap(doc.data()!, doc.id);
  }

  /// Search items by keyword, category, location, and date range.
  Future<List<ItemModel>> searchItems({
    String? keyword,
    ItemType? type,
    String? category,
    String? campusLocation,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 30,
  }) async {
    // Build a base query — only use equality filters to avoid composite index
    // requirements for every filter combination. Date range and keyword are
    // applied client-side after fetching.
    Query<Map<String, dynamic>> query = _itemsRef
        .where('status', isEqualTo: ItemStatus.active.name);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (campusLocation != null && campusLocation.isNotEmpty) {
      query = query.where('campusLocation', isEqualTo: campusLocation);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    var items = snapshot.docs
        .map((doc) => ItemModel.fromMap(doc.data(), doc.id))
        .toList();

    // Client-side: date range filter
    if (fromDate != null) {
      items = items.where((item) =>
          !item.dateOccurred.isBefore(fromDate)).toList();
    }
    if (toDate != null) {
      final endOfDay = toDate.add(const Duration(days: 1));
      items = items.where((item) =>
          item.dateOccurred.isBefore(endOfDay)).toList();
    }

    // Client-side: keyword filter
    if (keyword != null && keyword.trim().isNotEmpty) {
      final searchTerm = keyword.trim().toLowerCase();
      items = items.where((item) {
        return item.title.toLowerCase().contains(searchTerm) ||
            item.description.toLowerCase().contains(searchTerm) ||
            item.searchKeywords.any((k) => k.contains(searchTerm));
      }).toList();
    }

    items.sort((a, b) => b.dateReported.compareTo(a.dateReported));
    return items;
  }

  // ── Update ──────────────────────────────────────────────────────────────

  /// Update an item's status.
  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    await _itemsRef.doc(itemId).update({'status': status.name});
  }

  /// Mark an item as claimed by a user.
  Future<void> markAsClaimed(String itemId, String claimedByUid) async {
    await _itemsRef.doc(itemId).update({
      'status': ItemStatus.claimed.name,
      'claimedByUid': claimedByUid,
    });
  }

  /// Mark an item as resolved.
  Future<void> markAsResolved(String itemId) async {
    await _itemsRef.doc(itemId).update({
      'status': ItemStatus.resolved.name,
    });
  }

  /// Update item details.
  Future<void> updateItem(ItemModel item) async {
    await _itemsRef.doc(item.id).update(item.toMap());
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  /// Delete an item (admin or owner only).
  Future<void> deleteItem(String itemId) async {
    await _itemsRef.doc(itemId).delete();
  }

  // ── Statistics ──────────────────────────────────────────────────────────

  /// Get item counts for a user (for profile stats).
  Future<Map<String, int>> getUserStats(String uid) async {
    final userItems = await _itemsRef
        .where('reporterUid', isEqualTo: uid)
        .get();

    int totalReported = userItems.docs.length;
    int resolved = userItems.docs
        .where((doc) => doc.data()['status'] == ItemStatus.resolved.name)
        .length;

    return {
      'totalReported': totalReported,
      'resolved': resolved,
    };
  }

  /// Get overall platform stats (for admin).
  Future<Map<String, int>> getPlatformStats() async {
    final allItems = await _itemsRef.get();
    final docs = allItems.docs;

    return {
      'totalItems': docs.length,
      'lostItems': docs.where((d) => d.data()['type'] == 'lost').length,
      'foundItems': docs.where((d) => d.data()['type'] == 'found').length,
      'activeItems': docs.where((d) => d.data()['status'] == 'active').length,
      'resolvedItems': docs.where((d) => d.data()['status'] == 'resolved').length,
    };
  }
}
