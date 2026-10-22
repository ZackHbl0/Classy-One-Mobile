import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../providers/notification_provider.dart';
import '../screens/absences_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/documents_page.dart';
import '../screens/evenements_page.dart';
import '../screens/grades_screen.dart';
import '../screens/notifications_page.dart';
import '../screens/paiement_page.dart';
import '../screens/planning_page.dart';
import '../utils/content_router.dart';
import 'auth_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM [Background Handler]: Received message ${message.messageId}');
}

/// Global Android notification channel with maximum priority for heads-up alerts
const AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
  'classy_one_channel_v1',
  'Notifications Importantes',
  description: 'Ce canal est utilisé pour les notifications critiques et les alertes d\'urgence.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initializes FCM, permissions, local heads-up notifications, and background/foreground handlers
  static Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // 1. Request user notification permissions
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted push notification permission');
    } else {
      debugPrint('FCM: Push permission status: ${settings.authorizationStatus}');
    }

    // 2. Presentation options when app is in foreground for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Initialize Flutter Local Notifications for heads-up notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('FCM [LocalNotification]: Tapped with payload: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            handleNotificationTap(data);
          } catch (e) {
            debugPrint('FCM [LocalNotification]: Failed to parse payload JSON: $e');
          }
        }
      },
    );

    // 4. Create Android Notification Channel
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(fcmChannel);
    await androidImplementation?.requestNotificationsPermission();

    // 5. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Foreground message listener (triggers local heads-up + in-app overlay + instant state refresh)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM [Foreground]: Message received: ${message.messageId}');
      final String title = message.notification?.title ?? message.data['title'] ?? 'Nouvelle notification';
      final String body = message.notification?.body ?? message.data['body'] ?? '';

      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
      if (!data.containsKey('title')) data['title'] = title;
      if (!data.containsKey('body')) data['body'] = body;

      // 6a. Instantly update notification list state without requiring a manual refresh
      await refreshNotificationStateSilently();

      // 6b. Display Android / iOS native heads-up notification from top of screen
      await showLocalNotification(
        id: message.hashCode,
        title: title,
        body: body,
        data: data,
      );

      // 6c. Display stylish animated in-app banner with tap navigation
      showInAppNotificationBanner(
        title: title,
        body: body,
        data: data,
      );
    });

    // 7. Handle notification tapped while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM [Background Tap]: User opened notification: ${message.data}');
      handleNotificationTap(message.data);
    });

    // 8. Handle notification that launched app from terminated state
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM [Terminated Tap]: App launched via notification: ${initialMessage.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationTap(initialMessage.data);
      });
    }

    // 9. Sync token with backend
    await updateToken();

    // 10. Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
  }

  /// Instantly updates the notification list and badge count without manual refresh
  static Future<void> refreshNotificationStateSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      final context = navigatorKey?.currentContext;

      if (context != null && idStudent != 0) {
        debugPrint('FCM: Silently refreshing NotificationProvider for student $idStudent');
        context.read<NotificationProvider>().fetchNotificationsSilently(idStudent);
      }
    } catch (e) {
      debugPrint('FCM: Error refreshing notification state: $e');
    }
  }

  /// Displays a native Heads-Up Notification via flutter_local_notifications
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      fcmChannel.id,
      fcmChannel.name,
      channelDescription: fcmChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Displays a floating top in-app notification overlay
  static void showInAppNotificationBanner({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) return;
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) {
                if (overlayEntry.mounted) overlayEntry.remove();
              },
              child: GestureDetector(
                onTap: () {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                  handleNotificationTap(data);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101520),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Accent line
                      Container(
                        width: 4,
                        height: 48,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2234),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/app_icon_adaptive.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.notifications, color: Color(0xFF38BDF8), size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ClassyOne',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'À l\'instant',
                                      style: TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF8B5CF6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  /// Deep-links to target screen or delegates attached file to ContentRouter
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    debugPrint('FCM: Handling notification tap with payload: $data');

    BuildContext? context = navigatorKey?.currentContext;
    if (context == null) {
      await Future.delayed(const Duration(milliseconds: 400));
      context = navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('FCM: Navigator context unavailable for deep link.');
        return;
      }
    }

    // 1. Check if the notification contains a file or media attachment -> use ContentRouter
    final String? fileUrl = data['url'] ??
        data['file_url'] ??
        data['piece_jointe'] ??
        data['pieceJointe'] ??
        data['attachment'];

    if (fileUrl != null && fileUrl.toString().trim().isNotEmpty) {
      final String trimmedUrl = fileUrl.toString().trim();
      final String contentTitle = data['title'] ?? data['titre'] ?? 'Document joint';
      debugPrint('FCM: Routing file attachment via ContentRouter: $trimmedUrl');
      await ContentRouter.routeContent(
        context,
        contentUrl: trimmedUrl,
        contentTitle: contentTitle,
      );
      return;
    }

    // 2. Route based on notification category or type
    final String type = (data['type'] ?? data['categorie'] ?? '').toString().toLowerCase();

    Widget? targetPage;
    if (type.contains('plan') || type.contains('emploi')) {
      targetPage = const PlanningPage();
    } else if (type.contains('exam') || type.contains('note') || type.contains('grade') || type.contains('bulletin')) {
      targetPage = const GradesScreen();
    } else if (type.contains('event') || type.contains('vénement') || type.contains('venement')) {
      targetPage = const EvenementsPage();
    } else if (type.contains('paiement') || type.contains('payment') || type.contains('finance')) {
      targetPage = const PaiementPage(showBackButton: true);
    } else if (type.contains('absence') || type.contains('absent')) {
      targetPage = const AbsencesScreen();
    } else if (type.contains('cour') || type.contains('lesson')) {
      targetPage = const CoursesScreen();
    } else if (type.contains('doc')) {
      targetPage = const DocumentsPage();
    } else {
      // Default to notifications center
      targetPage = const NotificationsPage();
    }

    if (targetPage != null) {
      debugPrint('FCM: Deep linking to ${targetPage.runtimeType}');
      navigatorKey?.currentState?.push(
        MaterialPageRoute(builder: (_) => targetPage!),
      );
    }
  }

  /// Updates and syncs the FCM token with the backend API
  static Future<void> updateToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Clears token on server on user logout
  static Future<void> clearTokenOnServer() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? 'student';
    final idStudent = prefs.getInt('idStudent') ?? 0;

    if (userRole == 'parent') {
      debugPrint('FCM: Clearing parent token on server...');
      await _authService.updateParentFcmToken('');
      debugPrint('FCM: Parent token cleared on server');
    } else if (idStudent != 0) {
      debugPrint('FCM: Clearing student token on server...');
      await _authService.updateFcmToken('');
      debugPrint('FCM: Student token cleared on server');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? 'student';
    final idStudent = prefs.getInt('idStudent') ?? 0;

    // Check if notifications are enabled in settings
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    if (notificationsEnabled) {
      if (userRole == 'parent') {
        debugPrint('FCM: Syncing parent token with Laravel...');
        final result = await _authService.updateParentFcmToken(token);
        if (result['success'] == true) {
          debugPrint('FCM: Parent token successfully synced with Laravel');
        } else {
          debugPrint('FCM: Failed to sync parent token: ${result['message']}');
        }
      } else if (idStudent != 0) {
        debugPrint('FCM: Syncing student token with Laravel...');
        final result = await _authService.updateFcmToken(token);
        if (result['success'] == true) {
          debugPrint('FCM: Student token successfully synced with Laravel');
        } else {
          debugPrint('FCM: Failed to sync student token: ${result['message']}');
        }
      }
    }
  }
}