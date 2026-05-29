import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertNotificationService {
  static final AlertNotificationService _instance =
      AlertNotificationService._internal();

  factory AlertNotificationService() {
    return _instance;
  }

  AlertNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;
  final Set<String> _seenAlertIds = {};

  void _log(String msg) {
    if (kDebugMode) debugPrint('[AlertNotificationService] $msg');
  }

  /// Initialize local notifications and FCM
  Future<void> initialize() async {
    if (_initialized) return;

    // Local Notifications Setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _log('Notification clicked: ${response.payload}');
      },
    );

    await _createAndroidChannel();

    // FCM Setup
    await _setupFCM();

    // Listen to Auth changes to update token
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.tokenRefreshed) {
        _updateTokenInSupabase();
      }
    });

    _initialized = true;
    _log('Initialized');
  }

  /// Create Android notification channel
  Future<void> _createAndroidChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'nexus_alerts',
      'NEXUS Alerts',
      description: 'Alerts from NEXUS device',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Setup Firebase Messaging
  Future<void> _setupFCM() async {

    // Force FCM auto-init
    await _fcm.setAutoInitEnabled(true);

    // Request permissions
    NotificationSettings settings =
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _log('User granted FCM permission');
    } else {
      _log('User declined or has not accepted FCM permission');
    }

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log('Foreground message received: ${message.notification?.title}');
      
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Alerte NEXUS',
          body: message.notification!.body ?? 'Mouvement suspect détecté !',
          payload: message.data['alert_id'],
        );
      }
    });

    // Handle interaction when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log('App opened from notification: ${message.data}');
    });

    // Handle token refresh
    _fcm.onTokenRefresh.listen((token) {
      _updateTokenInSupabase(token);
    });

    // Initial token update if user is already logged in
    _updateTokenInSupabase();
  }

  /// Update the FCM token in Supabase 'profiles' table
  Future<void> _updateTokenInSupabase([
    String? token,
  ]) async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        _log('No authenticated user');
        return;
      }

      final fcmToken =
          token ?? await _fcm.getToken();

      if (fcmToken == null) {
        _log('FCM token is NULL');
        return;
      }

      _log('FCM TOKEN = $fcmToken');

      final response =
      await Supabase.instance.client
          .from('profiles')
          .update({
        'fcm_token': fcmToken,
      })
          .eq('id', user.id);

      _log(
        'Token saved for user ${user.id}',
      );
    } catch (e) {
      _log(
        'Error updating FCM token: $e',
      );
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'nexus_alerts',
        'NEXUS Alerts',
        channelDescription: 'Alerts from NEXUS device',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        (DateTime.now().millisecondsSinceEpoch & 0x7fffffff),
        title,
        body,
        details,
        payload: payload,
      );

      _log('Notification shown locally: $title');
    } catch (e) {
      _log('Error showing local notification: $e');
    }
  }

  /// Listen to real-time alerts for the current device (legacy/fallback)
  void listenToAlerts(String deviceId) {
    try {
      _log('Starting to listen for alerts on device: $deviceId');
      final channel = Supabase.instance.client.channel('alerts_realtime:$deviceId');

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'alerts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'device_id',
          value: deviceId,
        ),
        callback: (payload) {
          _log('New alert detected in DB via Realtime: ${payload.newRecord}');
          final newData = Map<String, dynamic>.from(payload.newRecord);

          if (newData.isNotEmpty) {
            final alertId = newData['id']?.toString();
            
            if (alertId != null) {
              if (_seenAlertIds.contains(alertId)) return;
              _seenAlertIds.add(alertId);
            }

            showNotification(
              title: 'Alerte NEXUS ⚠️',
              body: 'Mouvement suspect détecté !',
              payload: alertId,
            );
          }
        },
      ).subscribe();
    } catch (e) {
      _log('Error listening to alerts: $e');
    }
  }

  /// Stop listening to alerts
  void stopListening() {
    try {
      Supabase.instance.client.removeAllChannels();
      _log('Alert listeners stopped');
    } catch (e) {
      _log('Error stopping listener: $e');
    }
  }
}
