import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a claim request.
enum ClaimStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }
}

class ClaimModel {
  final String id;
  final String itemId;
  final String itemTitle;
  final String claimantUid;
  final String claimantName;
  final String claimantEmail;
  final String claimantPhone;
  final String message;
  final List<String> evidenceImageUrls;
  final ClaimStatus status;
  final String? responseMessage;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.claimantUid,
    required this.claimantName,
    required this.claimantEmail,
    required this.claimantPhone,
    required this.message,
    this.evidenceImageUrls = const [],
    this.status = ClaimStatus.pending,
    this.responseMessage,
    required this.createdAt,
    this.respondedAt,
  });

  /// Whether the claim is still awaiting a decision.
  bool get isPending => status == ClaimStatus.pending;

  /// Whether the claim has been approved.
  bool get isApproved => status == ClaimStatus.approved;

  /// Create from Firestore document snapshot.
  factory ClaimModel.fromMap(Map<String, dynamic> map, String id) {
    return ClaimModel(
      id: id,
      itemId: map['itemId'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      claimantUid: map['claimantUid'] ?? '',
      claimantName: map['claimantName'] ?? '',
      claimantEmail: map['claimantEmail'] ?? '',
      claimantPhone: map['claimantPhone'] ?? '',
      message: map['message'] ?? '',
      evidenceImageUrls: List<String>.from(map['evidenceImageUrls'] ?? []),
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClaimStatus.pending,
      ),
      responseMessage: map['responseMessage'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'claimantUid': claimantUid,
      'claimantName': claimantName,
      'claimantEmail': claimantEmail,
      'claimantPhone': claimantPhone,
      'message': message,
      'evidenceImageUrls': evidenceImageUrls,
      'status': status.name,
      'responseMessage': responseMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// Create a copy with modified fields.
  ClaimModel copyWith({
    ClaimStatus? status,
    String? responseMessage,
    DateTime? respondedAt,
    List<String>? evidenceImageUrls,
  }) {
    return ClaimModel(
      id: id,
      itemId: itemId,
      itemTitle: itemTitle,
      claimantUid: claimantUid,
      claimantName: claimantName,
      claimantEmail: claimantEmail,
      claimantPhone: claimantPhone,
      message: message,
      evidenceImageUrls: evidenceImageUrls ?? this.evidenceImageUrls,
      status: status ?? this.status,
      responseMessage: responseMessage ?? this.responseMessage,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  String toString() => 'ClaimModel(id: $id, itemId: $itemId, status: ${status.name})';
}
