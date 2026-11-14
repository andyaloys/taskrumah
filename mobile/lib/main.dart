import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/local_notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().init();
  runApp(
    const ProviderScope(
      child: FamilyTaskApp(),
    ),
  );
}
