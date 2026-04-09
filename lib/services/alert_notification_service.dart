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

  bool _initialized = false;
  final Set<String> _seenAlertIds = {};

  void _log(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_initialized) return;

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
        // Logic to handle click when app is in foreground/background
        // The router will handle the redirection if we use a global key or similar,
        // but for now, just bringing the app to front is default.
      },
    );

    // Create Android notification channel
    await _createAndroidChannel();

    _initialized = true;
    _log('AlertNotificationService initialized');
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
      // On peut ajouter un son personnalisé ici si présent dans res/raw
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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

      _log('Notification shown: $title - $body');
    } catch (e) {
      _log('Error showing notification: $e');
    }
  }

  /// Listen to real-time alerts for the current device
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
          _log('New alert detected in DB: ${payload.newRecord}');
          final newData = Map<String, dynamic>.from(payload.newRecord);

          if (newData.isNotEmpty) {
            final alertId = newData['id']?.toString();
            
            // Éviter les doublons si la callback est appelée plusieurs fois
            if (alertId != null) {
              if (_seenAlertIds.contains(alertId)) return;
              _seenAlertIds.add(alertId);
            }

            // Déclencher la notification
            showNotification(
              title: 'Alerte NEXUS ⚠️',
              body: 'Mouvement suspect détecté !',
              payload: alertId,
            );
          }
        },
      ).subscribe();

      _log('Alert listener subscribed for device: $deviceId');
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
