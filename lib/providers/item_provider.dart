import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lost_and_found/models/item_model.dart';
import 'package:lost_and_found/models/claim_model.dart';
import 'package:lost_and_found/services/item_service.dart';
import 'package:lost_and_found/services/storage_service.dart';
import 'package:lost_and_found/services/claim_service.dart';

class ItemProvider extends ChangeNotifier {
  final ItemService _itemService = ItemService();
  final StorageService _storageService = StorageService();
  final ClaimService _claimService = ClaimService();

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // ── Getters ─────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // ── Persistent Streams ──────────────────────────────────────────────────

  /// Stream of lost items (all users).
  Stream<List<ItemModel>> get lostItemsStream =>
      _itemService.streamItems(type: ItemType.lost);

  /// Stream of found items (all users).
  Stream<List<ItemModel>> get foundItemsStream =>
      _itemService.streamItems(type: ItemType.found);

  /// Stream of a specific user's items.
  Stream<List<ItemModel>> userItemsStream(String uid) =>
      _itemService.streamUserItems(uid);

  /// Stream of all items (admin).
  Stream<List<ItemModel>> get allItemsStream =>
      _itemService.streamAllItems();

  /// Stream of incoming claims on a user's items.
  Stream<List<ClaimModel>> incomingClaimsStream(String uid) =>
      _claimService.streamIncomingClaims(uid);

  /// Stream of claims submitted by a user.
  Stream<List<ClaimModel>> userClaimsStream(String uid) =>
      _claimService.streamUserClaims(uid);

  /// Stream of claims on a specific item.
  Stream<List<ClaimModel>> itemClaimsStream(String itemId) =>
      _claimService.streamClaimsForItem(itemId);

  // ── Create Item ─────────────────────────────────────────────────────────

  /// Report a lost or found item with images.
  Future<bool> reportItem({
    required String title,
    required String description,
    required ItemType type,
    required String category,
    required String campusLocation,
    String? specificLocation,
    required DateTime dateOccurred,
    required String reporterUid,
    required String reporterName,
    required String reporterDepartment,
    List<File> images = const [],
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Upload images first so a failed upload never creates an orphaned doc.
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _storageService.uploadItemImages(
          imageFiles: images,
          itemId: 'pending',
        );
      }

      // Build the complete item and write it to Firestore in one step.
      final item = ItemModel(
        id: '',
        title: title.trim(),
        description: description.trim(),
        type: type,
        category: category,
        campusLocation: campusLocation,
        specificLocation: specificLocation?.trim(),
        imageUrls: imageUrls,
        dateOccurred: dateOccurred,
        dateReported: DateTime.now(),
        reporterUid: reporterUid,
        reporterName: reporterName,
        reporterDepartment: reporterDepartment,
      );

      await _itemService.createItem(item);

      _successMessage = 'Item reported successfully!';
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to report item: ${e.toString().replaceFirst('Exception: ', '')}');
      _setLoading(false);
      return false;
    }
  }

  // ── Search ──────────────────────────────────────────────────────────────

  /// Search items with filters.
  Future<List<ItemModel>> searchItems({
    String? keyword,
    ItemType? type,
    String? category,
    String? campusLocation,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      return await _itemService.searchItems(
        keyword: keyword,
        type: type,
        category: category,
        campusLocation: campusLocation,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      _setError('Search failed: ${e.toString()}');
      return [];
    }
  }

  // ── Status Updates ──────────────────────────────────────────────────────

  /// Mark an item as resolved.
  Future<bool> markAsResolved(String itemId) async {
    try {
      await _itemService.markAsResolved(itemId);
      _successMessage = 'Item marked as resolved';
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update status');
      return false;
    }
  }

  /// Delete an item and its images.
  Future<bool> deleteItem(String itemId) async {
    try {
      await _storageService.deleteItemImages(itemId);
      await _itemService.deleteItem(itemId);
      _successMessage = 'Item deleted';
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete item');
      return false;
    }
  }

  // ── Claims ──────────────────────────────────────────────────────────────

  /// Fetch a single item.
  Future<ItemModel?> getItem(String id) async {
    return await _itemService.getItem(id);
  }

  /// Fetch a single claim by ID.
  Future<ClaimModel?> getClaim(String claimId) async {
    return await _claimService.getClaim(claimId);
  }

  /// Submit a claim on an item.
  Future<bool> submitClaim(ClaimModel claim) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Check for duplicate claim
      final hasExisting = await _claimService.hasExistingClaim(
        claim.itemId,
        claim.claimantUid,
      );

      if (hasExisting) {
        _setError('You already have a pending claim on this item');
        _setLoading(false);
        return false;
      }

      await _claimService.submitClaim(claim);
      _successMessage = 'Claim submitted successfully. The reporter will review your claim.';
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to submit claim: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Approve a claim.
  Future<bool> approveClaim(ClaimModel claim, {String? message}) async {
    try {
      await _claimService.approveClaim(claim, responseMessage: message);
      _successMessage = 'Claim approved! Contact details shared with the claimant.';
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to approve claim');
      return false;
    }
  }

  /// Reject a claim.
  Future<bool> rejectClaim(String claimId, {String? message}) async {
    try {
      await _claimService.rejectClaim(claimId, responseMessage: message);
      _successMessage = 'Claim rejected';
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reject claim');
      return false;
    }
  }

  // ── Statistics ──────────────────────────────────────────────────────────

  Future<Map<String, int>> getUserStats(String uid) =>
      _itemService.getUserStats(uid);

  Future<Map<String, int>> getPlatformStats() =>
      _itemService.getPlatformStats();

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _successMessage = null;
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
