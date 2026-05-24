## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

## Supabase / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

## Google Play Core
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
