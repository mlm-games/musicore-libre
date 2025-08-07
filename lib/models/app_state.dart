enum PlaybackState { playing, paused, stopped }

class AppState {
  final bool isLoading;
  final bool isScoreLoaded;
  final String? errorMessage;
  final PlaybackState playbackState;
  final double zoomLevel;
  final String? currentFileName;
  final double playbackSpeed;
  final bool followCursor;

  const AppState({
    this.isLoading = false,
    this.isScoreLoaded = false,
    this.errorMessage,
    this.playbackState = PlaybackState.stopped,
    this.zoomLevel = 1.0,
    this.currentFileName,
    this.playbackSpeed = 1.0,
    this.followCursor = true,
  });

  AppState copyWith({
    bool? isLoading,
    bool? isScoreLoaded,
    String? errorMessage,
    bool clearError = false,
    PlaybackState? playbackState,
    double? zoomLevel,
    String? currentFileName,
    bool clearFileName = false,
    double? playbackSpeed,
    bool? followCursor,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isScoreLoaded: isScoreLoaded ?? this.isScoreLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      playbackState: playbackState ?? this.playbackState,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      currentFileName: clearFileName ? null : currentFileName ?? this.currentFileName,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      followCursor: followCursor ?? this.followCursor,
    );
  }
}