import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_and_found/models/claim_model.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/services/notification_service.dart';

class ClaimService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _claimsRef =>
      _firestore.collection('claims');

  /// Submit a new claim on an item.
  Future<String> submitClaim(ClaimModel claim) async {
    final docRef = _claimsRef.doc();
    final claimWithId = ClaimModel(
      id: docRef.id,
      itemId: claim.itemId,
      itemTitle: claim.itemTitle,
      claimantUid: claim.claimantUid,
      claimantName: claim.claimantName,
      claimantEmail: claim.claimantEmail,
      claimantPhone: claim.claimantPhone,
      message: claim.message,
      evidenceImageUrls: claim.evidenceImageUrls,
      status: ClaimStatus.pending,
      createdAt: DateTime.now(),
    );
    await docRef.set(claimWithId.toMap());

    // Notify the item reporter.
    final itemDoc =
        await _firestore.collection('items').doc(claim.itemId).get();
    if (itemDoc.exists) {
      final reporterUid = itemDoc.data()?['reporterUid'] as String?;
      if (reporterUid != null) {
        await NotificationService().notifyClaimReceived(
          reporterUid: reporterUid,
          claimantName: claim.claimantName,
          itemTitle: claim.itemTitle,
          itemId: claim.itemId,
          claimId: docRef.id,
        );
      }
    }
    return docRef.id;
  }

  /// Fetch a single claim by ID.
  Future<ClaimModel?> getClaim(String claimId) async {
    final doc = await _claimsRef.doc(claimId).get();
    if (doc.exists) {
      return ClaimModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream claims for a specific item (item reporter sees these).
  /// Sorted client-side to avoid requiring a composite index.
  Stream<List<ClaimModel>> streamClaimsForItem(String itemId) {
    return _claimsRef
        .where('itemId', isEqualTo: itemId)
        .snapshots()
        .map((snapshot) {
          final claims = snapshot.docs
              .map((doc) => ClaimModel.fromMap(doc.data(), doc.id))
              .toList();
          claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return claims;
        });
  }

  /// Stream claims submitted by a specific user.
  /// Sorted client-side to avoid requiring a composite index.
  Stream<List<ClaimModel>> streamUserClaims(String uid) {
    return _claimsRef
        .where('claimantUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final claims = snapshot.docs
              .map((doc) => ClaimModel.fromMap(doc.data(), doc.id))
              .toList();
          claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return claims;
        });
  }

  /// Stream all incoming claims on items reported by a specific user.
  Stream<List<ClaimModel>> streamIncomingClaims(String reporterUid) {
    return _firestore
        .collection('items')
        .where('reporterUid', isEqualTo: reporterUid)
        .snapshots()
        .asyncMap((itemSnapshot) async {
      final itemIds = itemSnapshot.docs.map((doc) => doc.id).toList();
      if (itemIds.isEmpty) return <ClaimModel>[];

      // Firestore 'whereIn' supports max 30 values; chunk if needed.
      // No orderBy here — sorted client-side to avoid composite index requirement.
      final allClaims = <ClaimModel>[];
      for (var i = 0; i < itemIds.length; i += 10) {
        final chunk = itemIds.sublist(
          i,
          (i + 10 > itemIds.length) ? itemIds.length : i + 10,
        );
        final claimSnapshot = await _claimsRef
            .where('itemId', whereIn: chunk)
            .get();
        allClaims.addAll(
          claimSnapshot.docs.map((doc) => ClaimModel.fromMap(doc.data(), doc.id)),
        );
      }

      allClaims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allClaims;
    });
  }

  /// Approve a claim — updates claim status and marks item as claimed.
  Future<void> approveClaim(ClaimModel claim, {String? responseMessage}) async {
    final batch = _firestore.batch();
    batch.update(_claimsRef.doc(claim.id), {
      'status': ClaimStatus.approved.name,
      'responseMessage': responseMessage ?? 'Claim approved',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_firestore.collection('items').doc(claim.itemId), {
      'status': ItemStatus.claimed.name,
      'claimedByUid': claim.claimantUid,
    });
    final otherClaims = await _claimsRef
        .where('itemId', isEqualTo: claim.itemId)
        .where('status', isEqualTo: ClaimStatus.pending.name)
        .get();
    for (final doc in otherClaims.docs) {
      if (doc.id != claim.id) {
        batch.update(doc.reference, {
          'status': ClaimStatus.rejected.name,
          'responseMessage': 'Another claim was approved for this item',
          'respondedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }
    await batch.commit();

    // Notify the claimant.
    await NotificationService().notifyClaimApproved(
      claimantUid: claim.claimantUid,
      itemTitle: claim.itemTitle,
      itemId: claim.itemId,
      claimId: claim.id,
    );
  }

  /// Reject a claim.
  Future<void> rejectClaim(String claimId, {String? responseMessage}) async {
    await _claimsRef.doc(claimId).update({
      'status': ClaimStatus.rejected.name,
      'responseMessage': responseMessage ?? 'Claim rejected',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Notify the claimant.
    final doc = await _claimsRef.doc(claimId).get();
    if (doc.exists) {
      final data = doc.data()!;
      await NotificationService().notifyClaimRejected(
        claimantUid: data['claimantUid'] as String,
        itemTitle: data['itemTitle'] as String,
        itemId: data['itemId'] as String,
        claimId: claimId,
      );
    }
  }

  /// Check if a user already has a pending claim on an item.
  Future<bool> hasExistingClaim(String itemId, String claimantUid) async {
    final snapshot = await _claimsRef
        .where('itemId', isEqualTo: itemId)
        .where('claimantUid', isEqualTo: claimantUid)
        .where('status', isEqualTo: ClaimStatus.pending.name)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
