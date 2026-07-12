import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/core/network/realtime_config.dart';
import 'package:pair/core/notifications/push_notification_service.dart';
import 'package:pair/core/router.dart';
import 'package:pair/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('API_BASE_URL: $apiBaseUrl');
    debugPrint(
      'REVERB: ${ReverbConfig.wsScheme}://${ReverbConfig.host}:${ReverbConfig.port}',
    );
  }

  runApp(const ProviderScope(child: PairApp()));
}

class PairApp extends ConsumerStatefulWidget {
  const PairApp({super.key});

  @override
  ConsumerState<PairApp> createState() => _PairAppState();
}

class _PairAppState extends ConsumerState<PairApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pair',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
