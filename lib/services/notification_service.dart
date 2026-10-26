import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(settings);
      _initialized = true;

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint("Failed to initialize NotificationService: $e");
    }
  }

  static Future<void> showChapterUpdatedNotification({
    required String title,
    required int chapter,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manga_updates_channel',
      'Manga Chapter Updates',
      channelDescription: 'Notifications when a manga chapter is automatically updated',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '📖 Chapter Updated',
        '$title updated to Chapter $chapter!',
        details,
      );
    } catch (e) {
      debugPrint("Error displaying chapter notification: $e");
    }
  }

  static Future<void> showAlreadyUpToDateNotification({
    required String title,
    required int chapter,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manga_updates_channel',
      'Manga Chapter Updates',
      channelDescription: 'Notifications when a manga chapter is checked or updated',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 2,
        '📚 Already Up to Date',
        '$title is already at Chapter $chapter',
        details,
      );
    } catch (e) {
      debugPrint("Error displaying up-to-date notification: $e");
    }
  }

  static Future<void> showMangaSuggestionNotification({
    required String title,
    required int chapter,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manga_suggestions_channel',
      'Manga Import Suggestions',
      channelDescription: 'Notifications when a new manga is detected from browser reading',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1,
        '🧩 New Manga Detected',
        '$title (Ch. $chapter) read. Tap to add to your library!',
        details,
      );
    } catch (e) {
      debugPrint("Error displaying suggestion notification: $e");
    }
  }
}
