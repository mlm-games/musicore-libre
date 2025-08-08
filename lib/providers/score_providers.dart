import 'dart:io';
import 'package:musicore/models/app_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

final webViewControllerProvider =
    StateProvider<InAppWebViewController?>((ref) => null);

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;

  AppStateNotifier(this._ref) : super(const AppState());

  InAppWebViewController? get _webController =>
      _ref.read(webViewControllerProvider);

  Future<void> loadFile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml', 'musicxml', 'mxl'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Unable to read file');
      }

      final extension = file.extension?.toLowerCase();
      String xmlString;

      if (extension == 'mxl') {
        xmlString = await _extractXmlFromMxl(file.bytes!);
      } else {
        xmlString = String.fromCharCodes(file.bytes!);
      }

      await _loadXmlIntoWebView(xmlString);

      state = state.copyWith(
        isLoading: false,
        isScoreLoaded: true,
        playbackState: PlaybackState.stopped,
        zoomLevel: 1.0,
        currentFileName: file.name,
        playbackSpeed: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load file: ${e.toString()}',
      );
    }
  }

  Future<void> loadFileFromPath(String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist at path: $filePath');
      }

      final bytes = await file.readAsBytes();
      final fileName = path.basename(filePath);
      final extension = path.extension(filePath).toLowerCase();
      String xmlString;

      if (extension == '.mxl') {
        xmlString = await _extractXmlFromMxl(bytes);
      } else {
        xmlString = String.fromCharCodes(bytes);
      }

      await _loadXmlIntoWebView(xmlString);

      state = state.copyWith(
        isLoading: false,
        isScoreLoaded: true,
        playbackState: PlaybackState.stopped,
        zoomLevel: 1.0,
        currentFileName: fileName,
        playbackSpeed: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load shared file: ${e.toString()}',
      );
    }
  }


  Future<String> _extractXmlFromMxl(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    // Look for the main score file
    for (final file in archive) {
      if (file.name.endsWith('.xml') &&
          !file.name.startsWith('META-INF/') &&
          !file.name.startsWith('__MACOSX/')) {
        return String.fromCharCodes(file.content);
      }
    }

    throw Exception('No valid MusicXML file found in archive');
  }

  Future<void> _loadXmlIntoWebView(String xmlString) async {
    // Wait a bit to ensure WebView is ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Escape the XML string for safe JavaScript injection
    final escapedXml = xmlString
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');

    // Use window.loadMusicXML which we defined globally
    final result = await _webController?.evaluateJavascript(
        source: 'window.loadMusicXML("$escapedXml");');

    print('Load result: $result');
  }

  void setZoom(double newZoom) {
    if (!state.isScoreLoaded) return;

    final clampedZoom = newZoom.clamp(0.2, 5.0);
    state = state.copyWith(zoomLevel: clampedZoom);
    _webController?.evaluateJavascript(source: 'setZoom($clampedZoom);');
  }

  void zoomIn() => setZoom(state.zoomLevel + 0.2);
  void zoomOut() => setZoom(state.zoomLevel - 0.2);
  void resetZoom() => setZoom(1.0);

  void setPlaybackSpeed(double speed) {
    if (!state.isScoreLoaded) return;

    final clampedSpeed = speed.clamp(0.25, 2.0);
    state = state.copyWith(playbackSpeed: clampedSpeed);
    _webController?.evaluateJavascript(
        source: 'setPlaybackSpeed($clampedSpeed);');
  }

  void toggleFollowCursor() {
    state = state.copyWith(followCursor: !state.followCursor);
    _webController?.evaluateJavascript(
        source: 'setFollowCursor(${state.followCursor});');
  }

  void startPlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.playing);
    _webController?.evaluateJavascript(source: 'startPlayback();');
  }

  void pausePlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.paused);
    _webController?.evaluateJavascript(source: 'pausePlayback();');
  }

  void stopPlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.stopped);
    _webController?.evaluateJavascript(source: 'stopPlayback();');
  }

  void resetScore() {
    stopPlayback();
    state = const AppState();
    _webController?.evaluateJavascript(source: 'resetScore();');
  }

  void handlePlaybackEnded() {
    state = state.copyWith(playbackState: PlaybackState.stopped);
  }
}
