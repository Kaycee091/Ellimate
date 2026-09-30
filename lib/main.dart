import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/constants/app_constants.dart';
import 'app/app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Firebase (non-critical — won't crash app if it fails)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[ElliMate] Firebase init failed: $e');
  }

  // Initialize local notifications
  try {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Navigate based on notification payload
        debugPrint('[ElliMate] Notification tapped: ${details.payload}');
      },
    );

    // Create notification channels
    const androidNotifChannel = AndroidNotificationChannel(
      AppConstants.chatNotificationChannelId,
      'Chat Notifications',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotifChannel);
  } catch (e) {
    debugPrint('[ElliMate] Local notifications init failed: $e');
  }

  runApp(
    const ProviderScope(
      child: ElliMateApp(),
    ),
  );
}
