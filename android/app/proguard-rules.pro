
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-dontwarn com.google.android.play.core.**
-dontnote com.google.android.play.core.**

-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.InAppWebView.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keep class io.github.mlm_games.musicore.** { *; }

-assumenosideeffects class com.google.android.play.** {
    *;
}