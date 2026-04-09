import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/login_page.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/welcome_page.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Demander la permission pour les notifications (très important pour le background/foreground FCM)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Configuration des notifications en premier plan (Foreground)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Canal utilisé pour les notifications importantes.',
      importance: Importance.max,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Canal utilisé pour les notifications importantes.',
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

  } catch (e) {
    debugPrint('Erreur d\'initialisation Firebase: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final int? idStudent = prefs.getInt('idStudent');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ],
        child: MyApp(initialRoute: idStudent != null ? '/main' : '/login'),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'OSBT Notify',
          localizationsDelegates: [
            ...context.localizationDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: initialRoute,
          routes: {
            '/welcome': (context) => const WelcomePage(),
            '/login': (context) => const LoginPage(),
            '/main': (context) => const MainScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
