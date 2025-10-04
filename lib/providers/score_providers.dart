import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicore/models/app_state.dart';
import 'package:path/path.dart' as path;

final webViewControllerProvider =
    StateProvider<InAppWebViewController?>((ref) => null);

// Tracks whether the HTML viewer finished loading (onLoadStop).
final webViewReadyProvider = StateProvider<bool>((ref) => false);

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
      late final String xmlString;

      if (extension == 'mxl') {
        xmlString = await _extractXmlFromMxl(file.bytes!);
      } else {
        xmlString = utf8.decode(file.bytes!);
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
      late final String xmlString;

      if (extension == '.mxl') {
        xmlString = await _extractXmlFromMxl(bytes);
      } else {
        xmlString = utf8.decode(bytes);
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

    for (final file in archive) {
      if (!file.isFile) continue;
      final name = file.name;
      if (name.endsWith('.xml') &&
          !name.startsWith('META-INF/') &&
          !name.startsWith('__MACOSX/')) {
        final content = file.content as List<int>;
        return utf8.decode(content);
      }
    }

    throw Exception('No valid MusicXML file found in archive');
  }

  Future<void> _loadXmlIntoWebView(String xmlString) async {
    await _ensureWebViewReady();

    // Use JSON encoding to safely pass large strings and all characters.
    final json = jsonEncode(xmlString);
    await _evalJS('window.loadMusicXML($json);');

    // Sync viewer settings (in case user adjusted before loading another file).
    await _evalJS('setZoom(${state.zoomLevel.clamp(0.2, 5.0)});');
    await _evalJS('setPlaybackSpeed(${state.playbackSpeed.clamp(0.25, 2.0)});');
    await _evalJS('setFollowCursor(${state.followCursor});');
  }

  Future<void> _ensureWebViewReady() async {
    // Wait until the WebView reports it finished loading index.html
    const totalWait = Duration(seconds: 8);
    const pollEvery = Duration(milliseconds: 100);
    var waited = Duration.zero;

    while (!_ref.read(webViewReadyProvider)) {
      await Future.delayed(pollEvery);
      waited += pollEvery;
      if (waited >= totalWait) {
        throw Exception('Viewer is not ready yet. Please try again.');
      }
    }
  }

  Future<void> _evalJS(String source) async {
    try {
      await _webController?.evaluateJavascript(source: source);
    } catch (e) {
      debugPrint('JS eval error: $e');
    }
  }

  void setZoom(double newZoom) {
    if (!state.isScoreLoaded) return;

    final clampedZoom = newZoom.clamp(0.2, 5.0);
    state = state.copyWith(zoomLevel: clampedZoom);
    _evalJS('setZoom($clampedZoom);');
  }

  void zoomIn() => setZoom(state.zoomLevel + 0.2);
  void zoomOut() => setZoom(state.zoomLevel - 0.2);
  void resetZoom() => setZoom(1.0);

  void setPlaybackSpeed(double speed) {
    if (!state.isScoreLoaded) return;

    final clampedSpeed = speed.clamp(0.25, 2.0);
    state = state.copyWith(playbackSpeed: clampedSpeed);
    _evalJS('setPlaybackSpeed($clampedSpeed);');
  }

  void toggleFollowCursor() {
    state = state.copyWith(followCursor: !state.followCursor);
    _evalJS('setFollowCursor(${state.followCursor});');
  }

  void startPlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.playing);
    _evalJS('startPlayback();');
  }

  void pausePlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.paused);
    _evalJS('pausePlayback();');
  }

  void stopPlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.stopped);
    _evalJS('stopPlayback();');
  }

  void resetScore() {
    stopPlayback();
    state = const AppState();
    _evalJS('resetScore();');
  }

  void handlePlaybackEnded() {
    state = state.copyWith(playbackState: PlaybackState.stopped);
  }
}
