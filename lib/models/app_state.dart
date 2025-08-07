enum PlaybackState { playing, paused, stopped }

class AppState {
  final bool isLoading;
  final bool isScoreLoaded;
  final String? errorMessage;
  final PlaybackState playbackState;
  final double zoomLevel;

  AppState({
    this.isLoading = false,
    this.isScoreLoaded = false,
    this.errorMessage,
    this.playbackState = PlaybackState.stopped,
    this.zoomLevel = 1.0,
  });

  AppState copyWith({
    bool? isLoading,
    bool? isScoreLoaded,
    String? errorMessage,
    bool clearError = false,
    PlaybackState? playbackState,
    double? zoomLevel,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isScoreLoaded: isScoreLoaded ?? this.isScoreLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      playbackState: playbackState ?? this.playbackState,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}