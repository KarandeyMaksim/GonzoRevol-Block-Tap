// Smoke test verifying the app boots to the Splash screen without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gonzorevol_block_tap/data/game_repository.dart';
import 'package:gonzorevol_block_tap/main.dart';
import 'package:gonzorevol_block_tap/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = await GameRepository.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repository)],
        child: const GonzoRevolApp(),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
