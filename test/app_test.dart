import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicore/main.dart';
import 'package:musicore/models/app_state.dart';
import 'package:musicore/providers/score_providers.dart';

ProviderScope _scopeWith({
  required AppState initialState,
}) {
  return ProviderScope(
    overrides: [
      renderWebViewProvider.overrideWithValue(false),
      webViewReadyProvider.overrideWith((ref) => true),
      appStateProvider.overrideWith((ref) {
        final notifier = AppStateNotifier(ref);
        notifier.state = initialState;
        return notifier;
      }),
    ],
    child: const MusicoreApp(),
  );
}

void main() {
  group('MusicoreApp (widget)', () {
    testWidgets('Initial state shows welcome screen', (tester) async {
      await tester.pumpWidget(_scopeWith(initialState: const AppState()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Musicore'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.text('Supports .xml, .musicxml, and .mxl files'), findsOneWidget);
      expect(find.byKey(const Key('webview_stub')), findsOneWidget);
    });

    testWidgets('Loading state shows progress UI', (tester) async {
      await tester.pumpWidget(
        _scopeWith(initialState: const AppState(isLoading: true)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading score...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget); // AppBar bottom
    });

    testWidgets('Error state shows error card', (tester) async {
      await tester.pumpWidget(
        _scopeWith(initialState: const AppState(errorMessage: 'Failed to load file: Invalid format')),
      );
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Failed to load file: Invalid format'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Loaded state shows controls and indicators', (tester) async {
      await tester.pumpWidget(
        _scopeWith(
          initialState: const AppState(
            isScoreLoaded: true,
            currentFileName: 'test_score.mxl',
            zoomLevel: 1.0,
            playbackSpeed: 1.0,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('test_score.mxl'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
      expect(find.text('Zoom: 100%'), findsOneWidget);
      expect(find.text('Speed: 1.0x'), findsOneWidget);
    });

    testWidgets('Playback icon reflects playing state', (tester) async {
      await tester.pumpWidget(
        _scopeWith(
          initialState: const AppState(
            isScoreLoaded: true,
            playbackState: PlaybackState.playing,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });
  });

  group('File type heuristics (pure Dart)', () {
    test('Recognizes valid/invalid extensions', () {
      const valid = ['score.xml', 'music.musicxml', 'compressed.mxl'];
      const invalid = ['document.pdf', 'image.png', 'text.txt'];

      for (final f in valid) {
        expect(f.endsWith('.xml') || f.endsWith('.musicxml') || f.endsWith('.mxl'), isTrue, reason: '$f should be valid');
      }
      for (final f in invalid) {
        expect(f.endsWith('.xml') || f.endsWith('.musicxml') || f.endsWith('.mxl'), isFalse, reason: '$f should be invalid');
      }
    });
  });
}