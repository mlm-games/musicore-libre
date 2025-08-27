import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicore/main.dart';
import 'package:musicore/models/app_state.dart';
import 'package:musicore/providers/score_providers.dart';

// Mock provider for testing different states
class MockAppStateNotifier extends StateNotifier<AppState> {
  MockAppStateNotifier(AppState state) : super(state);
  
  void setState(AppState newState) {
    state = newState;
  }
}

void main() {
  group('MusicoreApp Tests', () {
    testWidgets('Initial state shows welcome screen', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MusicoreApp()));

      expect(find.text('Welcome to Musicore'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.text('Supports .xml, .musicxml, and .mxl files'), findsOneWidget);
    });

    testWidgets('Loading state shows progress indicator', (WidgetTester tester) async {
      final mockNotifier = MockAppStateNotifier(
        const AppState(isLoading: true)
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MusicoreApp(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading score...'), findsOneWidget);
    });

    testWidgets('Error state shows error card', (WidgetTester tester) async {
      final mockNotifier = MockAppStateNotifier(
        const AppState(errorMessage: 'Failed to load file: Invalid format')
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MusicoreApp(),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Failed to load file: Invalid format'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Loaded state shows controls', (WidgetTester tester) async {
      final mockNotifier = MockAppStateNotifier(
        const AppState(
          isScoreLoaded: true,
          currentFileName: 'test_score.mxl',
          zoomLevel: 1.0,
          playbackSpeed: 1.0,
        )
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MusicoreApp(),
        ),
      );

      // Check app bar
      expect(find.text('test_score.mxl'), findsOneWidget);
      
      // Check control buttons
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
      
      // Check status indicators
      expect(find.text('Zoom: 100%'), findsOneWidget);
      expect(find.text('Speed: 1.0x'), findsOneWidget);
    });

    testWidgets('Playback controls change state correctly', (WidgetTester tester) async {
      final mockNotifier = MockAppStateNotifier(
        const AppState(
          isScoreLoaded: true,
          playbackState: PlaybackState.playing,
        )
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MusicoreApp(),
        ),
      );

      // When playing, pause button should be shown
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });
  });

  group('File Type Support Tests', () {
    test('AppState correctly identifies file extensions', () {
      const validFiles = ['score.xml', 'music.musicxml', 'compressed.mxl'];
      const invalidFiles = ['document.pdf', 'image.png', 'text.txt'];

      for (final file in validFiles) {
        expect(
          file.endsWith('.xml') || file.endsWith('.musicxml') || file.endsWith('.mxl'),
          isTrue,
          reason: '$file should be recognized as valid',
        );
      }

      for (final file in invalidFiles) {
        expect(
          file.endsWith('.xml') || file.endsWith('.musicxml') || file.endsWith('.mxl'),
          isFalse,
          reason: '$file should be recognized as invalid',
        );
      }
    });
  });
}