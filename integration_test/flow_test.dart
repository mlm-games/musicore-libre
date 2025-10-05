import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicore/main.dart';
import 'package:musicore/providers/score_providers.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end flow', () {
    testWidgets('Load, control, and verify UI state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MusicoreApp()));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Welcome screen visible
      expect(find.text('Welcome to Musicore'), findsOneWidget);

      // Create a tiny valid MusicXML file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mini.xml');
      const miniXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
 "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Music</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions><key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><rest/><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <barline location="right"><bar-style>light-heavy</bar-style></barline>
    </measure>
  </part>
</score-partwise>
''';
      await file.writeAsString(miniXml);

      // Grab the provider container from the widget tree and load the file
      final ctx = tester.element(find.byType(Scaffold));
      final container = ProviderScope.containerOf(ctx);
      await container
          .read(appStateProvider.notifier)
          .loadFileFromPath(file.path);

      // Give the WebView time to initialize and OSMD to render
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // App bar shows filename
      expect(find.text('mini.xml'), findsOneWidget);

      // Controls visible
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);

      // Zoom in -> 120%
      await tester.tap(find.byIcon(Icons.zoom_in));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Zoom: 120%'), findsOneWidget);

      // Speed -> 1.5x
      await tester.tap(find.byIcon(Icons.speed));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x').last);
      await tester.pumpAndSettle();
      expect(find.text('Speed: 1.5x'), findsOneWidget);

      // Start playback -> pause icon appears
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Pause playback -> play icon returns
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Toggle follow cursor from menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      // Text depends on initial state (true by default)
      expect(find.textContaining('Disable Follow Cursor'), findsOneWidget);
      await tester.tap(find.textContaining('Disable Follow Cursor'));
      await tester.pumpAndSettle();

      // Stop playback is disabled when already stopped -> enable by starting then stopping
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Close score
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close Score'));
      await tester.pumpAndSettle();

      // Back to welcome state
      expect(find.text('Welcome to Musicore'), findsOneWidget);
    });
  });
}