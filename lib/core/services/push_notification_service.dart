import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/core/router/app_router.dart';
import 'package:ne3ma/features/donations/data/repositories/donation_repository.dart';
import 'package:ne3ma/features/notifications/providers/notifications_provider.dart';
import 'package:ne3ma/features/profile/data/repository/profile_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ne3ma/firebase_options.dart';

const String _androidNotificationChannelId = 'ne3ma_notifications_high_v2';
const String _androidNotificationChannelName = 'NEJMA Notifications';
const String _androidNotificationChannelDescription =
    'General notifications for reservations, messages, and nearby donations.';
const int _maxAndroidNotificationId = 2147483647;

int _notificationIdFromTime() {
  return DateTime.now().millisecondsSinceEpoch.remainder(
    _maxAndroidNotificationId,
  );
}

int _notificationIdForMessage(RemoteMessage message) {
  return (message.messageId?.hashCode ?? _notificationIdFromTime()) &
      _maxAndroidNotificationId;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase may already be initialized in the background isolate.
  }
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint("Message Data: ${message.data}");
  if (message.notification != null) {
    debugPrint(
      "Message Notification: Title=${message.notification?.title}, Body=${message.notification?.body}",
    );
  }

  // Android displays FCM "notification" payloads automatically in the
  // background. Data-only pushes need us to create a visible notification.
  if (message.notification == null) {
    debugPrint(
      "PushNotifications: Data-only background message detected, triggering local notification.",
    );
    await _showBackgroundDataNotification(message);
  }
}

/// Top-level callback for flutter_local_notifications background taps.
/// Must be a top-level or static function annotated with @pragma.
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint(
    '👆 PushNotifications [BG isolate]: Notification tapped with payload: ${response.payload}',
  );
  // Navigation is handled when the app relaunches via getNotificationAppLaunchDetails.
}

@pragma('vm:entry-point')
Future<void> _showBackgroundDataNotification(RemoteMessage message) async {
  final title = _messageTitle(message);
  final body = _messageBody(message);

  if (title.isEmpty && body.isEmpty) {
    debugPrint(
      '⚠️ PushNotifications: Background data message had no title/body',
    );
    return;
  }

  const channel = AndroidNotificationChannel(
    _androidNotificationChannelId,
    _androidNotificationChannelName,
    description: _androidNotificationChannelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  final localNotifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings(
    '@drawable/ic_notification',
  );
  const iosSettings = DarwinInitializationSettings();
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(
    settings,
    onDidReceiveBackgroundNotificationResponse:
        onDidReceiveBackgroundNotificationResponse,
  );
  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await localNotifications.show(
    _notificationIdForMessage(message),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: const Color(0xFF1E4D35),
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.status,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode({
      ..._normalizedMessageData(message.data),
      'title': title,
      'body': body,
    }),
  );
}

String _messageTitle(RemoteMessage message) {
  final data = _normalizedMessageData(message.data);
  return message.notification?.title ??
      data['title']?.toString() ??
      data['notificationTitle']?.toString() ??
      'New Notification';
}

String _messageBody(RemoteMessage message) {
  final data = _normalizedMessageData(message.data);
  return message.notification?.body ??
      data['body']?.toString() ??
      data['notificationBody']?.toString() ??
      data['message']?.toString() ??
      '';
}

Map<String, dynamic> _normalizedMessageData(Map<String, dynamic> data) {
  final normalized = Map<String, dynamic>.from(data);
  final rawData = normalized['data'];

  if (rawData is String && rawData.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        normalized.addAll(decoded);
      } else if (decoded is Map) {
        normalized.addAll(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Keep the original payload if backend data is not JSON.
    }
  }

  return normalized;
}

class PushDebugInfo {
  const PushDebugInfo({
    this.isInitialized = false,
    this.permissionStatus = 'Unknown',
    this.authStatus = 'Unknown',
    this.localNotificationStatus = 'Unknown',
    this.currentToken = '',
    this.backendSyncStatus = 'Not synced yet',
    this.lastEvent = 'Nothing received yet',
    this.lastNotificationTitle = '',
    this.lastNotificationBody = '',
    this.lastNotificationType = '',
    this.lastNotificationData = const <String, dynamic>{},
    this.lastError = '',
  });

  final bool isInitialized;
  final String permissionStatus;
  final String authStatus;
  final String localNotificationStatus;
  final String currentToken;
  final String backendSyncStatus;
  final String lastEvent;
  final String lastNotificationTitle;
  final String lastNotificationBody;
  final String lastNotificationType;
  final Map<String, dynamic> lastNotificationData;
  final String lastError;

  PushDebugInfo copyWith({
    bool? isInitialized,
    String? permissionStatus,
    String? authStatus,
    String? localNotificationStatus,
    String? currentToken,
    String? backendSyncStatus,
    String? lastEvent,
    String? lastNotificationTitle,
    String? lastNotificationBody,
    String? lastNotificationType,
    Map<String, dynamic>? lastNotificationData,
    String? lastError,
  }) {
    return PushDebugInfo(
      isInitialized: isInitialized ?? this.isInitialized,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      authStatus: authStatus ?? this.authStatus,
      localNotificationStatus:
          localNotificationStatus ?? this.localNotificationStatus,
      currentToken: currentToken ?? this.currentToken,
      backendSyncStatus: backendSyncStatus ?? this.backendSyncStatus,
      lastEvent: lastEvent ?? this.lastEvent,
      lastNotificationTitle:
          lastNotificationTitle ?? this.lastNotificationTitle,
      lastNotificationBody: lastNotificationBody ?? this.lastNotificationBody,
      lastNotificationType: lastNotificationType ?? this.lastNotificationType,
      lastNotificationData: lastNotificationData ?? this.lastNotificationData,
      lastError: lastError ?? this.lastError,
    );
  }
}

class PushNotificationService {
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _androidNotificationChannelId,
    _androidNotificationChannelName,
    description: _androidNotificationChannelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  final ProfileRepository _profileRepository = ProfileRepository();
  final DonationRepository _donationRepository = DonationRepository();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<PushDebugInfo> debugInfo = ValueNotifier(
    const PushDebugInfo(),
  );
  bool _isInitialized = false;
  RemoteMessage? _pendingLaunchMessage;

  void logDebugSnapshot({String reason = 'manual snapshot'}) {
    final info = debugInfo.value;
    final tokenPreview = info.currentToken.isEmpty
        ? 'empty'
        : '${info.currentToken.substring(0, info.currentToken.length < 18 ? info.currentToken.length : 18)}...';
    debugPrint('━━━━━━━━━━ PUSH DEBUG SNAPSHOT ━━━━━━━━━━');
    debugPrint('Reason: $reason');
    debugPrint('Initialized: ${info.isInitialized}');
    debugPrint('Permission: ${info.permissionStatus}');
    debugPrint('Local notifications: ${info.localNotificationStatus}');
    debugPrint('Auth: ${info.authStatus}');
    debugPrint('Token: $tokenPreview');
    debugPrint('Backend sync: ${info.backendSyncStatus}');
    debugPrint('Last event: ${info.lastEvent}');
    debugPrint('Last notification title: ${info.lastNotificationTitle}');
    debugPrint('Last notification type: ${info.lastNotificationType}');
    debugPrint('Last payload: ${jsonEncode(info.lastNotificationData)}');
    if (info.lastError.isNotEmpty) {
      debugPrint('Last error: ${info.lastError}');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    // 1. Request permission
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    _patchDebugInfo(
      (current) => current.copyWith(
        isInitialized: true,
        permissionStatus: _authorizationStatusLabel(
          settings.authorizationStatus,
        ),
        lastEvent: 'Push service initialized',
      ),
    );

    await _initLocalNotifications();
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingLaunchMessage = initialMessage;
      _recordIncomingMessage(initialMessage, source: 'launch');
    }

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Got a message whilst in the foreground!');
      debugPrint('🔔 Message ID: ${message.messageId}');
      debugPrint('🔔 Message data: ${jsonEncode(message.data)}');

      if (message.notification != null) {
        debugPrint(
          '🔔 Message title: ${message.notification?.title}, body: ${message.notification?.body}',
        );
      } else {
        debugPrint('🔔 Message has NO notification block (data-only)');
      }

      _recordIncomingMessage(message, source: 'foreground');

      final title = _titleForMessage(message);
      final body = _bodyForMessage(message);
      debugPrint('🔔 Parsed title: "$title", body: "$body"');

      unawaited(_showForegroundNotification(message));
      _refreshNotificationCenter();
    });

    // 4. Listen to background message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked from background!');
      _recordIncomingMessage(message, source: 'background tap');
      unawaited(_handleNotificationTap(message));
      _refreshNotificationCenter();
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('🔄 PushNotifications: FCM token refreshed');
      _patchDebugInfo(
        (current) => current.copyWith(
          currentToken: token,
          lastEvent: 'FCM token refreshed',
        ),
      );
      unawaited(syncTokenWithBackend(tokenOverride: token));
    });

    // 5. Retrieve push token and sync if authenticated
    try {
      final token = await messaging.getToken();
      debugPrint('FCM Token: $token');
      _patchDebugInfo(
        (current) => current.copyWith(
          currentToken: token ?? '',
          lastEvent: 'FCM token fetched',
        ),
      );
      await syncTokenWithBackend(tokenOverride: token);
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      _patchDebugInfo(
        (current) => current.copyWith(
          lastError: 'Token fetch failed: $e',
          lastEvent: 'Failed to fetch FCM token',
        ),
      );
    }

    await refreshDebugInfo();
    logDebugSnapshot(reason: 'service init completed');
  }

  Future<void> syncTokenWithBackend({String? tokenOverride}) async {
    debugPrint('📤 PushNotifications: Starting token sync...');
    final accessToken = await GraphQLClient.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('⚠️ PushNotifications: No auth token yet, skip push sync');
      _patchDebugInfo(
        (current) => current.copyWith(
          authStatus: 'No access token',
          backendSyncStatus: 'Skipped: user is not authenticated',
          lastEvent: 'Push token sync skipped',
        ),
      );
      return;
    }

    final token = tokenOverride ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ PushNotifications: No FCM token available');
      _patchDebugInfo(
        (current) => current.copyWith(
          authStatus: 'Authenticated',
          currentToken: '',
          backendSyncStatus: 'Skipped: no FCM token available',
          lastEvent: 'Push token sync skipped',
        ),
      );
      return;
    }

    try {
      debugPrint(
        '📡 PushNotifications: Syncing token to backend (${token.length} chars)',
      );
      await _profileRepository.updatePushToken(token);
      debugPrint('✅ PushNotifications: Push token synced to backend');
      _patchDebugInfo(
        (current) => current.copyWith(
          authStatus: 'Authenticated',
          currentToken: token,
          backendSyncStatus: 'Synced successfully to backend',
          lastEvent: 'Push token synced',
          lastError: '',
        ),
      );
    } catch (e) {
      debugPrint('❌ PushNotifications: Failed to sync push token - $e');
      _patchDebugInfo(
        (current) => current.copyWith(
          authStatus: 'Authenticated',
          currentToken: token,
          backendSyncStatus: 'Sync failed',
          lastError: 'Backend sync failed: $e',
          lastEvent: 'Push token sync failed',
        ),
      );
    }
    logDebugSnapshot(reason: 'token sync finished');
  }

  Future<void> refreshDebugInfo() async {
    debugPrint('🔍 PushNotifications: Refreshing debug info...');
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final localNotificationsEnabled = await _areLocalNotificationsEnabled();
      final token = await FirebaseMessaging.instance.getToken();
      final accessToken = await GraphQLClient.getAccessToken();
      _patchDebugInfo(
        (current) => current.copyWith(
          isInitialized: _isInitialized,
          permissionStatus: _authorizationStatusLabel(
            settings.authorizationStatus,
          ),
          localNotificationStatus: localNotificationsEnabled == null
              ? 'Unknown'
              : localNotificationsEnabled
              ? 'Enabled'
              : 'Disabled',
          authStatus: accessToken == null || accessToken.isEmpty
              ? 'No access token'
              : 'Authenticated',
          currentToken: token ?? '',
          lastEvent: 'Debug state refreshed',
        ),
      );
      logDebugSnapshot(reason: 'debug refresh');
    } catch (e) {
      debugPrint('❌ PushNotifications: Failed to refresh debug info - $e');
      _patchDebugInfo(
        (current) => current.copyWith(
          lastError: 'Debug refresh failed: $e',
          lastEvent: 'Failed to refresh debug state',
        ),
      );
    }
  }

  Future<void> requestPermissionsAgain() async {
    debugPrint('🛂 PushNotifications: Requesting notification permission...');
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _requestLocalNotificationPermission();
    final localNotificationsEnabled = await _areLocalNotificationsEnabled();
    _patchDebugInfo(
      (current) => current.copyWith(
        permissionStatus: _authorizationStatusLabel(
          settings.authorizationStatus,
        ),
        localNotificationStatus: localNotificationsEnabled == null
            ? 'Unknown'
            : localNotificationsEnabled
            ? 'Enabled'
            : 'Disabled',
        lastEvent: 'Notification permission requested again',
      ),
    );
    debugPrint(
      '🛂 PushNotifications: Permission result = ${settings.authorizationStatus}',
    );
    logDebugSnapshot(reason: 'permission request');
  }

  Future<void> showLocalDebugNotification() async {
    debugPrint('🧪 PushNotifications: Showing local debug notification...');
    await _localNotifications.show(
      _notificationIdFromTime(),
      'Push debug test',
      'If you see this, local notifications are working on this device.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF1E4D35),
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.status,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(const <String, dynamic>{
        'type': 'NEARBY_DONATION',
        'title': 'Push debug test',
        'body': 'This local test confirms notification display on device.',
        'source': 'local-debug',
      }),
    );
    _patchDebugInfo(
      (current) => current.copyWith(
        lastEvent: 'Local debug notification displayed',
        lastNotificationTitle: 'Push debug test',
        lastNotificationBody:
            'If you see this, local notifications are working on this device.',
        lastNotificationType: 'LOCAL_DEBUG',
        lastNotificationData: const <String, dynamic>{'source': 'local-debug'},
      ),
    );
    logDebugSnapshot(reason: 'local debug notification');
  }

  Future<void> processPendingLaunchNotification() async {
    final pendingMessage = _pendingLaunchMessage;
    if (pendingMessage == null) {
      return;
    }

    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext == null) {
      return;
    }

    _pendingLaunchMessage = null;
    await _handleNotificationTap(pendingMessage);
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          '👆 PushNotifications: Local notification tapped with payload: ${response.payload}',
        );
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        final data = _decodePayload(payload);
        if (data == null) {
          return;
        }

        unawaited(_handleNotificationTapData(data));
      },
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _requestLocalNotificationPermission() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<bool?> _areLocalNotificationsEnabled() async {
    return _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    _recordIncomingMessage(message, source: 'notification tap');
    await _handleNotificationTapData(message.data);
  }

  Future<void> _handleNotificationTapData(Map<String, dynamic> data) async {
    debugPrint(
      '🧭 PushNotifications: Handling notification tap data: ${jsonEncode(data)}',
    );
    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext == null) {
      _pendingLaunchMessage = null;
      debugPrint(
        '⚠️ PushNotifications: No navigator context available for notification tap',
      );
      return;
    }

    final type = data['type'];
    final donationId = data['donationId']?.toString();

    if (type == null || type.toString().isEmpty) {
      debugPrint(
        '🧭 PushNotifications: No type provided, opening notifications screen',
      );
      navContext.push('/notifications');
      return;
    }

    switch (type) {
      case 'MESSAGE':
        debugPrint('🧭 PushNotifications: Routing to messages');
        navContext.go('/messages');
        break;
      case 'WARNING':
        debugPrint('🧭 PushNotifications: Routing to profile warning view');
        navContext.go('/profile-tab');
        break;
      case 'NEARBY_DONATION':
        debugPrint(
          '🧭 PushNotifications: Routing nearby donation with donationId=$donationId',
        );
        await _openDonationOrFallback(
          navContext,
          donationId: donationId,
          fallbackRoute: '/home',
        );
        break;
      case 'RESERVATION':
      case 'CANCELLATION':
      case 'COMPLETION':
        debugPrint(
          '🧭 PushNotifications: Routing reservation-style notification with donationId=$donationId',
        );
        await _openDonationOrFallback(
          navContext,
          donationId: donationId,
          fallbackRoute: '/special',
        );
        break;
      default:
        debugPrint(
          '🧭 PushNotifications: Unknown type $type, opening notifications screen',
        );
        navContext.push('/notifications');
    }
  }

  Future<void> _openDonationOrFallback(
    BuildContext context, {
    required String? donationId,
    required String fallbackRoute,
  }) async {
    if (donationId != null && donationId.isNotEmpty) {
      try {
        debugPrint(
          '📦 PushNotifications: Fetching donation $donationId before navigation',
        );
        final donation = await _donationRepository.getDonation(donationId);
        if (donation != null && context.mounted) {
          debugPrint(
            '✅ PushNotifications: Donation found, opening /donation/${donation.id}',
          );
          context.push('/donation/${donation.id}', extra: donation);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ PushNotifications: Failed to open donation - $e');
      }
    }

    if (context.mounted) {
      debugPrint('↩️ PushNotifications: Falling back to route $fallbackRoute');
      context.go(fallbackRoute);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = _normalizedMessageData(message.data);
    final title = _messageTitle(message);
    final body = _messageBody(message);

    if (title.isEmpty && body.isEmpty) {
      debugPrint(
        '⚠️ PushNotifications: Foreground message had no title/body, skipping local display',
      );
      return;
    }

    final payload = jsonEncode({...data, 'title': title, 'body': body});
    debugPrint(
      '🔔 PushNotifications: Showing foreground notification title="$title" payload=$payload',
    );

    await _localNotifications.show(
      _notificationIdForMessage(message),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: const Color(0xFF1E4D35),
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.status,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  String _titleForMessage(RemoteMessage message) {
    return _messageTitle(message);
  }

  String _bodyForMessage(RemoteMessage message) {
    return _messageBody(message);
  }

  Map<String, dynamic>? _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('⚠️ PushNotifications: Failed to decode payload - $e');
    }
    return null;
  }

  String _authorizationStatusLabel(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Authorized';
      case AuthorizationStatus.denied:
        return 'Denied';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      case AuthorizationStatus.notDetermined:
        return 'Not determined';
    }
  }

  void _recordIncomingMessage(RemoteMessage message, {required String source}) {
    final data = Map<String, dynamic>.from(message.data);
    debugPrint(
      '📩 PushNotifications: Incoming message from $source | title="${_titleForMessage(message)}" | type=${data['type']} | data=${jsonEncode(data)}',
    );
    _patchDebugInfo(
      (current) => current.copyWith(
        lastEvent: 'Last notification received via $source',
        lastNotificationTitle: _titleForMessage(message),
        lastNotificationBody: _bodyForMessage(message),
        lastNotificationType: data['type']?.toString() ?? 'Unknown',
        lastNotificationData: data,
      ),
    );
  }

  void _patchDebugInfo(PushDebugInfo Function(PushDebugInfo current) update) {
    debugInfo.value = update(debugInfo.value);
  }

  void _refreshNotificationCenter() {
    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext == null) {
      return;
    }

    try {
      ProviderScope.containerOf(navContext, listen: false)
          .read(notificationsProvider.notifier)
          .fetchNotifications(background: true);
    } catch (e) {
      debugPrint('⚠️ PushNotifications: Could not refresh notifications - $e');
    }
  }
}
