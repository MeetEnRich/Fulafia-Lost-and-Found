import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationType { claimReceived, claimApproved, claimRejected, general }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? itemId;
  final String? claimId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.itemId,
    this.claimId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      itemId: map['itemId'],
      claimId: map['claimId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'type': type.name,
        'itemId': itemId,
        'claimId': claimId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _notifSubscription;

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    // Request runtime permission on Android 13+ and iOS
    await requestPermission();
  }

  /// Request notification permissions (Android 13+, iOS).
  Future<void> requestPermission() async {
    // Android 13+ runtime permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // iOS runtime permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _notifRef(String uid) =>
      _firestore.collection('notifications').doc(uid).collection('items');

  /// Stream of unread notification count for a user.
  Stream<int> unreadCountStream(String uid) {
    return _notifRef(uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Stream of all notifications for a user, newest first.
  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _notifRef(uid).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Start listening to incoming notifications to trigger local popups.
  void startListening(String uid) {
    _notifSubscription?.cancel();
    _notifSubscription = _notifRef(uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            // Only fire for notifications created in the last 10 seconds
            // to avoid re-triggering old unread ones on startup.
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null &&
                DateTime.now().difference(createdAt).inSeconds < 10) {
              _showLocalNotification(
                title: data['title'] ?? 'New Notification',
                body: data['body'] ?? '',
              );
            }
          }
        }
      }
    });
  }

  void stopListening() {
    _notifSubscription?.cancel();
    _notifSubscription = null;
  }

  /// Send a notification to a specific user (writes to their Firestore sub-collection).
  Future<void> sendToUser({
    required String recipientUid,
    required String title,
    required String body,
    required NotificationType type,
    String? itemId,
    String? claimId,
  }) async {
    final docRef = _notifRef(recipientUid).doc();
    final notif = AppNotification(
      id: docRef.id,
      title: title,
      body: body,
      type: type,
      itemId: itemId,
      claimId: claimId,
      createdAt: DateTime.now(),
    );
    await docRef.set(notif.toMap());
    // Local notification is triggered by the recipient's startListening() stream.
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String uid, String notifId) async {
    await _notifRef(uid).doc(notifId).update({'isRead': true});
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final unread =
        await _notifRef(uid).where('isRead', isEqualTo: false).get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete all notifications that have been read.
  Future<void> deleteReadNotifications(String uid) async {
    final batch = _firestore.batch();
    final read = await _notifRef(uid).where('isRead', isEqualTo: true).get();
    for (final doc in read.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Convenience senders ───────────────────────────────────────────────────

  Future<void> notifyClaimReceived({
    required String reporterUid,
    required String claimantName,
    required String itemTitle,
    required String itemId,
    required String claimId,
  }) =>
      sendToUser(
        recipientUid: reporterUid,
        title: 'New Claim on Your Item',
        body: '$claimantName has submitted a claim on "$itemTitle".',
        type: NotificationType.claimReceived,
        itemId: itemId,
        claimId: claimId,
      );

  Future<void> notifyClaimApproved({
    required String claimantUid,
    required String itemTitle,
    required String itemId,
    required String claimId,
  }) =>
      sendToUser(
        recipientUid: claimantUid,
        title: 'Claim Approved! 🎉',
        body:
            'Your claim on "$itemTitle" was approved. Contact the reporter to collect your item.',
        type: NotificationType.claimApproved,
        itemId: itemId,
        claimId: claimId,
      );

  Future<void> notifyClaimRejected({
    required String claimantUid,
    required String itemTitle,
    required String itemId,
    required String claimId,
  }) =>
      sendToUser(
        recipientUid: claimantUid,
        title: 'Claim Not Approved',
        body: 'Your claim on "$itemTitle" was not approved by the reporter.',
        type: NotificationType.claimRejected,
        itemId: itemId,
        claimId: claimId,
      );

  // ── Local notification ────────────────────────────────────────────────────

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lost_and_found_alerts',
      'Lost & Found Alerts',
      channelDescription: 'Notifications for claims and item updates',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
