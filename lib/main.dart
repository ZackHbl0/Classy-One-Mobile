import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login_page.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/welcome_page.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart' as import_fcm_service;
import 'theme/app_theme.dart';

// Plugin de notifications locales (global pour être accessible partout)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Canal de notification Android (global)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifications Importantes',
  description: 'Ce canal est utilisé pour les notifications critiques.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase pour l'isolat d'arrière-plan
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Extraire les infos soit de 'notification', soit de 'data'
  String? title = message.notification?.title ?? message.data['title'];
  String? body = message.notification?.body ?? message.data['body'];

  if (title != null || body != null) {
    debugPrint("FCM [Arrière-plan]: Affichage d'une notification: $title");
    await flutterLocalNotificationsPlugin.show(
      id: message.messageId.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.max,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Demander la permission pour les notifications (iOS/Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 3. Configuration de flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: DarwinInitializationSettings(),
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Gérer le clic sur la notification
      },
    );

    // 4. Créer le canal Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 5. Configurer FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Gérer les notifications en premier plan (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String? title = message.notification?.title ?? message.data['title'];
      String? body = message.notification?.body ?? message.data['body'];

      if (title != null || body != null) {
        debugPrint("FCM [Premier plan]: Affichage d'une notification: $title");
        flutterLocalNotificationsPlugin.show(
          id: message.messageId.hashCode,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 6. Initialiser le service FCM pour synchroniser le token
    await import_fcm_service.FcmService.initialize();
  } catch (e) {
    debugPrint('Erreur d\'initialisation globale: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Classy One',
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/welcome': (context) => const WelcomePage(),
            '/login': (context) => const LoginPage(),
            '/main': (context) => MainScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
