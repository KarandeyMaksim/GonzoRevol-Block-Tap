import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'core/ads_service.dart';
import 'core/analytics_service.dart';
import 'core/audio_service.dart';
import 'core/iap_service.dart';
import 'data/game_repository.dart';
import 'features/splash/splash_screen.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await GameRepository.create();

  // Fire-and-forget: none of these must block first paint, and each wrapper
  // is already crash-safe (no network / no Play services on first cold
  // start must never prevent the app from launching).
  unawaited(AnalyticsService.instance.activate());
  unawaited(AdsService.instance.init());
  unawaited(IapService.instance.init());
  unawaited(AudioService.instance.init());

  runApp(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repository),
      ],
      child: const GonzoRevolApp(),
    ),
  );
}

class GonzoRevolApp extends StatefulWidget {
  const GonzoRevolApp({super.key});

  @override
  State<GonzoRevolApp> createState() => _GonzoRevolAppState();
}

class _GonzoRevolAppState extends State<GonzoRevolApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      AnalyticsService.instance.appClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GonzoRevol Block Tap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
