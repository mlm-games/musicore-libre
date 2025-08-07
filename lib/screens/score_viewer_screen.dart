import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_musicore/models/app_state.dart';  
import 'package:flutter_musicore/providers/score_providers.dart';

class ScoreViewerScreen extends ConsumerWidget {
  const ScoreViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Score Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => ref.read(appStateProvider.notifier).loadFile(),
            tooltip: 'Open MusicXML File',
          ),
        ],
      ),
      body: Stack(
        children: [
          // The WebView that renders the score
          InAppWebView(
            initialFile: 'assets/www/index.html',
            onWebViewCreated: (controller) {
              ref.read(webViewControllerProvider.notifier).state = controller;
            },
            onLoadError: (controller, url, code, message) {
              ref.read(appStateProvider.notifier).state = appState.copyWith(
                  errorMessage: "Error loading WebView: $message");
            },
          ),
          // Loading Indicator
          if (appState.isLoading)
            const Center(child: CircularProgressIndicator()),
          // Error Message
          if (appState.errorMessage != null)
            Center(
              child: Text(
                appState.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          // Placeholder message
          if (!appState.isScoreLoaded && !appState.isLoading && appState.errorMessage == null)
            const Center(
              child: Text(
                'Open a MusicXML file to begin.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
        ],
      ),
      // Controls are at the bottom
      bottomNavigationBar: _buildControlBar(context, ref, appState),
    );
  }

  Widget _buildControlBar(BuildContext context, WidgetRef ref, AppState appState) {
    final notifier = ref.read(appStateProvider.notifier);
    final bool enabled = appState.isScoreLoaded;

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Zoom Out
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: enabled ? () => notifier.setZoom(appState.zoomLevel - 0.2) : null,
            tooltip: 'Zoom Out',
          ),
          // Stop
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: enabled && appState.playbackState != PlaybackState.stopped
                ? notifier.stopPlayback
                : null,
            tooltip: 'Stop',
          ),
          // Play/Pause
          IconButton(
            icon: Icon(appState.playbackState == PlaybackState.playing
                ? Icons.pause
                : Icons.play_arrow),
            iconSize: 36,
            onPressed: enabled
                ? (appState.playbackState == PlaybackState.playing
                    ? notifier.pausePlayback
                    : notifier.startPlayback)
                : null,
            tooltip: appState.playbackState == PlaybackState.playing ? 'Pause' : 'Play',
          ),
          // Zoom In
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: enabled ? () => notifier.setZoom(appState.zoomLevel + 0.2) : null,
            tooltip: 'Zoom In',
          ),
        ],
      ),
    );
  }
}