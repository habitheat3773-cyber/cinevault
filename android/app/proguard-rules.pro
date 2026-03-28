# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Hive
-keep class com.cinevault.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Better Player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Keep model classes
-keepclassmembers class ** {
    public <init>(...);
}

# Don't warn about missing classes
-dontwarn java.lang.instrument.ClassFileTransformer
-dontwarn sun.misc.SignalHandler
