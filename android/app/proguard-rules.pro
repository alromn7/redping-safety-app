# RedPing App - Optimized ProGuard Rules for Production

# === AGGRESSIVE SIZE OPTIMIZATION ===
-optimizationpasses 5
-repackageclasses ''
-allowaccessmodification
-flattenpackagehierarchy

# Remove debug logging in production (saves 1-2 MB)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# === Flutter Framework ===
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.Log { *; }

# === Firebase & Google Services ===
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.common.** { *; }
-keepclassmembers class com.google.firebase.** { *; }

# === Google Play Core (for deferred components) ===
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# === JSON Serialization ===
-keep class * extends java.lang.Object {
    <fields>;
}
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# === RedPing Specific ===
-keep class com.redping.redping.** { *; }

# === Location Services ===
-keep class com.baseflow.geolocator.** { *; }
-keep class com.lyokone.location.** { *; }

# === Sensors & Hardware ===
-keep class dev.fluttercommunity.plus.** { *; }

# === Notifications ===
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# === ML Kit Text Recognition ===
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google_mlkit_text_recognition.** { *; }

# === Stripe SDK ===
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-keepclassmembers class com.stripe.android.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# === Security & Encryption ===
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# === Reflection (for newer Java versions) ===
-dontwarn java.lang.reflect.AnnotatedType

# === Optimization Rules ===
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 3
-allowaccessmodification
-dontpreverify
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# === Keep Native Methods ===
-keepclasseswithmembernames class * {
    native <methods>;
}
