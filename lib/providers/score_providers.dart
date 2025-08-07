import 'dart:io';
import 'package:flutter_musicore/models/app_state.dart';  
import 'package:file_picker/file_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider holds the controller for our WebView, allowing other providers to interact with it.
final webViewControllerProvider = StateProvider<InAppWebViewController?>((ref) => null);

// This is the main state manager for our app.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  AppStateNotifier(this._ref) : super(AppState());

  InAppWebViewController? get _webController => _ref.read(webViewControllerProvider);

  Future<void> loadFile() async {
    state = state.copyWith(isLoading: true, clearError: true, playbackState: PlaybackState.stopped);
    stopPlayback(); // Stop any previous playback

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml', 'musicxml', 'mxl'],
    );

    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final xmlString = await file.readAsString();
        
        // IMPORTANT: Escape backticks and other characters for safe injection into JS template literal
        final safeXmlString = xmlString.replaceAll(r'`', r'\`').replaceAll(r'${', r'\${');

        await _webController?.callAsyncJavaScript(
          functionBody: 'loadMusicXML(`$safeXmlString`);'
        );
        state = state.copyWith(isLoading: false, isScoreLoaded: true, zoomLevel: 1.0);
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load or parse file.');
      }
    } else {
      state = state.copyWith(isLoading: false); // User canceled picker
    }
  }

  void setZoom(double newZoom) {
    if (!state.isScoreLoaded || newZoom < 0.2 || newZoom > 5.0) return;
    state = state.copyWith(zoomLevel: newZoom);
    _webController?.callAsyncJavaScript(functionBody: 'setZoom(${state.zoomLevel})');
  }

  void startPlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.playing);
    _webController?.callAsyncJavaScript(functionBody: 'startPlayback()');
  }

  void pausePlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.paused);
    _webController?.callAsyncJavaScript(functionBody: 'pausePlayback()');
  }

  void stopPlayback() {
    if (!state.isScoreLoaded) return;
    state = state.copyWith(playbackState: PlaybackState.stopped);
    _webController?.callAsyncJavaScript(functionBody: 'stopPlayback()');
  }
}