import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicore/models/app_state.dart';
import 'package:musicore/providers/score_providers.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ScoreViewerScreen extends ConsumerStatefulWidget {
  const ScoreViewerScreen({super.key});

  @override
  ConsumerState<ScoreViewerScreen> createState() => _ScoreViewerScreenState();
}

class _ScoreViewerScreenState extends ConsumerState<ScoreViewerScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setupIntentListener();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _setupIntentListener() {
    // For sharing files when the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final filePath = value.first.path;
        ref.read(appStateProvider.notifier).loadFileFromPath(filePath);
      }
    });

    // When the app is running
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final filePath = value.first.path;
        ref.read(appStateProvider.notifier).loadFileFromPath(filePath);
      }
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.currentFileName ?? 'Musicore'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => ref.read(appStateProvider.notifier).loadFile(),
            tooltip: 'Open MusicXML File',
          ),
          if (appState.isScoreLoaded) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(appStateProvider.notifier).resetZoom(),
              tooltip: 'Reset Zoom',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                final notifier = ref.read(appStateProvider.notifier);
                switch (value) {
                  case 'close':
                    notifier.resetScore();
                    break;
                  case 'toggle_follow':
                    notifier.toggleFollowCursor();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_follow',
                  child: Row(
                    children: [
                      Icon(
                        appState.followCursor
                            ? Icons.gps_fixed
                            : Icons.gps_not_fixed,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(appState.followCursor
                          ? 'Disable Follow Cursor'
                          : 'Enable Follow Cursor'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 20),
                      SizedBox(width: 12),
                      Text('Close Score'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialFile: 'assets/www/index.html',
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: true,
                supportZoom: false,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
              ios: IOSInAppWebViewOptions(
                allowsInlineMediaPlayback: true,
              ),
            ),
            onWebViewCreated: (controller) {
              ref.read(webViewControllerProvider.notifier).state = controller;

              // Set up JavaScript handlers
              controller.addJavaScriptHandler(
                handlerName: 'playbackEnded',
                callback: (args) {
                  ref.read(appStateProvider.notifier).handlePlaybackEnded();
                },
              );
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('Console: ${consoleMessage.message}');
            },
          ),
          if (appState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading score...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (appState.errorMessage != null)
            Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appState.errorMessage!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () =>
                            ref.read(appStateProvider.notifier).loadFile(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!appState.isScoreLoaded &&
              !appState.isLoading &&
              appState.errorMessage == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Musicore',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open a MusicXML file to begin',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(appStateProvider.notifier).loadFile(),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open File'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Supports .xml, .musicxml, and .mxl files',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: appState.isScoreLoaded
          ? _buildControlBar(context, ref, appState)
          : null,
    );
  }

  Widget _buildControlBar(
      BuildContext context, WidgetRef ref, AppState appState) {
    final notifier = ref.read(appStateProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Playback controls
            SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: Icons.zoom_out,
                    onPressed:
                        appState.zoomLevel > 0.2 ? notifier.zoomOut : null,
                    tooltip: 'Zoom Out',
                  ),
                  _ControlButton(
                    icon: Icons.stop,
                    onPressed: appState.playbackState != PlaybackState.stopped
                        ? notifier.stopPlayback
                        : null,
                    tooltip: 'Stop',
                  ),
                  _PlayPauseButton(
                    isPlaying: appState.playbackState == PlaybackState.playing,
                    onPressed: appState.playbackState == PlaybackState.playing
                        ? notifier.pausePlayback
                        : notifier.startPlayback,
                  ),
                  _SpeedButton(
                    currentSpeed: appState.playbackSpeed,
                    onSpeedChanged: notifier.setPlaybackSpeed,
                  ),
                  _ControlButton(
                    icon: Icons.zoom_in,
                    onPressed:
                        appState.zoomLevel < 5.0 ? notifier.zoomIn : null,
                    tooltip: 'Zoom In',
                  ),
                ],
              ),
            ),
            // Zoom indicator
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Zoom: ${(appState.zoomLevel * 100).toInt()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Speed: ${appState.playbackSpeed}x',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 28,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary,
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: theme.colorScheme.onPrimary,
        ),
        iconSize: 32,
        onPressed: onPressed,
        tooltip: isPlaying ? 'Pause' : 'Play',
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const _SpeedButton({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.speed),
      tooltip: 'Playback Speed',
      onSelected: onSpeedChanged,
      itemBuilder: (context) => [
        for (final speed in [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
          PopupMenuItem(
            value: speed,
            child: Row(
              children: [
                if (currentSpeed == speed)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 12),
                Text('${speed}x'),
              ],
            ),
          ),
      ],
    );
  }
}
