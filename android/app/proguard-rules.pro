# Flutter-safe ProGuard rules

# Keep Flutter engine and embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep JSON model classes (Dart reflection)
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep Kotlin metadata
-keepattributes RuntimeVisibleAnnotations
-keep class kotlin.Metadata { *; }

# Suppress warnings from R8
-dontwarn io.flutter.**
-dontwarn com.google.**
