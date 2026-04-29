import 'package:cloud_firestore/cloud_firestore.dart';

/// The type of item report.
enum ItemType {
  lost,
  found;

  String get label => this == ItemType.lost ? 'Lost' : 'Found';
}

/// The current status of an item report.
enum ItemStatus {
  active,
  claimed,
  resolved,
  expired;

  String get label {
    switch (this) {
      case ItemStatus.active:
        return 'Active';
      case ItemStatus.claimed:
        return 'Claimed';
      case ItemStatus.resolved:
        return 'Resolved';
      case ItemStatus.expired:
        return 'Expired';
    }
  }
}

class ItemModel {
  final String id;
  final String title;
  final String description;
  final ItemType type;
  final String category;
  final String campusLocation;
  final String? specificLocation;
  final List<String> imageUrls;
  final DateTime dateOccurred;
  final DateTime dateReported;
  final String reporterUid;
  final String reporterName;
  final String reporterDepartment;
  final ItemStatus status;
  final String? claimedByUid;
  final List<String> searchKeywords;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.campusLocation,
    this.specificLocation,
    this.imageUrls = const [],
    required this.dateOccurred,
    required this.dateReported,
    required this.reporterUid,
    required this.reporterName,
    this.reporterDepartment = '',
    this.status = ItemStatus.active,
    this.claimedByUid,
    this.searchKeywords = const [],
  });

  /// Generate search keywords from title and description for Firestore queries.
  static List<String> generateKeywords(String title, String description) {
    final words = <String>{};
    final combined = '$title $description'.toLowerCase();

    // Add individual words (3+ chars)
    for (final word in combined.split(RegExp(r'\s+'))) {
      final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
      if (cleaned.length >= 3) {
        words.add(cleaned);
      }
    }

    // Add prefix substrings for partial matching on the title
    final titleLower = title.toLowerCase().trim();
    for (int i = 1; i <= titleLower.length && i <= 20; i++) {
      words.add(titleLower.substring(0, i));
    }

    return words.toList();
  }

  /// Create from Firestore document snapshot.
  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    return ItemModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ItemType.lost,
      ),
      category: map['category'] ?? '',
      campusLocation: map['campusLocation'] ?? '',
      specificLocation: map['specificLocation'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      dateOccurred: (map['dateOccurred'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateReported: (map['dateReported'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reporterUid: map['reporterUid'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reporterDepartment: map['reporterDepartment'] ?? '',
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.active,
      ),
      claimedByUid: map['claimedByUid'],
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
    );
  }

  /// Convert to map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'category': category,
      'campusLocation': campusLocation,
      'specificLocation': specificLocation,
      'imageUrls': imageUrls,
      'dateOccurred': Timestamp.fromDate(dateOccurred),
      'dateReported': Timestamp.fromDate(dateReported),
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'reporterDepartment': reporterDepartment,
      'status': status.name,
      'claimedByUid': claimedByUid,
      'searchKeywords': searchKeywords,
    };
  }

  /// Create a copy with modified fields.
  ItemModel copyWith({
    String? title,
    String? description,
    ItemType? type,
    String? category,
    String? campusLocation,
    String? specificLocation,
    List<String>? imageUrls,
    DateTime? dateOccurred,
    ItemStatus? status,
    String? claimedByUid,
    List<String>? searchKeywords,
  }) {
    return ItemModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      campusLocation: campusLocation ?? this.campusLocation,
      specificLocation: specificLocation ?? this.specificLocation,
      imageUrls: imageUrls ?? this.imageUrls,
      dateOccurred: dateOccurred ?? this.dateOccurred,
      dateReported: dateReported,
      reporterUid: reporterUid,
      reporterName: reporterName,
      reporterDepartment: reporterDepartment,
      status: status ?? this.status,
      claimedByUid: claimedByUid ?? this.claimedByUid,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  @override
  String toString() => 'ItemModel(id: $id, title: $title, type: ${type.name})';
}
