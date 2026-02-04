import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    // Play Store publishing (requires service account credentials)
    id("com.github.triplet.play") version "3.9.0"
}

android {
    namespace = "com.redping.redping"
    // compileSdk raised to 36 to satisfy plugin & androidx activity 1.10.x requirements
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.redping.redping"
        minSdk = 24
        // targetSdk can remain at a stable level; raising to 36 keeps parity
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // multiDex disabled after shrink/R8; will revert if method count exceeds 64K.
        // Restrict native ABIs to arm64 only for smaller distribution size.
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    flavorDimensions += "mode"
    productFlavors {
        create("sos") {
            dimension = "mode"
            // Icon already contains branding; keep label short.
            resValue("string", "app_name", "SOS")
        }
        create("sar") {
            dimension = "mode"
            // Allow side-by-side install with SOS build.
            applicationIdSuffix = ".sar"
            versionNameSuffix = "-sar"
            resValue("string", "app_name", "SAR")
        }
    }

    // (Removed) ABI splits - now using ndk abiFilters arm64-only. Use CLI --split-per-abi only if reintroducing multiple ABIs.

    // Release signing config resolution order:
    // 1. key.properties (if present & non-placeholder)
    // 2. Environment variables: ANDROID_KEYSTORE_PATH / ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD / ANDROID_KEY_ALIAS
    // 3. Fallback to debug.
    val keystoreProps = Properties()
    val keystorePropsFile = rootProject.file("key.properties")
    if (keystorePropsFile.exists()) {
        keystoreProps.load(FileInputStream(keystorePropsFile))
    }
    val fileStoreFile = keystoreProps.getProperty("storeFile") ?: ""
    val fileStorePassword = keystoreProps.getProperty("storePassword") ?: ""
    val fileKeyPassword = keystoreProps.getProperty("keyPassword") ?: ""
    val fileKeyAlias = keystoreProps.getProperty("keyAlias") ?: ""
    val fileHasPlaceholders = fileStorePassword.startsWith("REPLACE_ME_") || fileKeyPassword.startsWith("REPLACE_ME_")
    val fileKeystore = if (fileStoreFile.isNotBlank()) rootProject.file(fileStoreFile) else null
    val fileValid = fileKeystore?.exists() == true && fileStorePassword.isNotBlank() && fileKeyPassword.isNotBlank() && fileKeyAlias.isNotBlank() && !fileHasPlaceholders

    // Env fallback (do not write key.properties; avoid leaking secrets to disk)
    val envStoreFilePath = System.getenv("ANDROID_KEYSTORE_PATH") ?: "android/keystore/redping-release.jks"
    val envStorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
    val envKeyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: ""
    val envKeyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: ""
    val envKeystoreFile = rootProject.file(envStoreFilePath)
    val envValid = envKeystoreFile.exists() && envStorePassword.isNotBlank() && envKeyPassword.isNotBlank() && envKeyAlias.isNotBlank()

    signingConfigs {
        when {
            fileValid -> {
                create("release") {
                    keyAlias = fileKeyAlias
                    keyPassword = fileKeyPassword
                    storeFile = fileKeystore
                    storePassword = fileStorePassword
                }
            }
            !fileValid && envValid -> {
                create("release") {
                    keyAlias = envKeyAlias
                    keyPassword = envKeyPassword
                    storeFile = envKeystoreFile
                    storePassword = envStorePassword
                }
            }
            else -> { /* no release keystore available; will fallback to debug */ }
        }
    }

    buildTypes {
        release {
            // Use release keystore if configured & valid; fallback to debug if missing/placeholder.
            val releaseConfig = signingConfigs.findByName("release")
            signingConfig = releaseConfig ?: signingConfigs.getByName("debug")

            // Enable code shrinking and obfuscation for production
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    
    // Packaging optimizations: compress native libs & drop redundant META-INF resources
    packaging {
        jniLibs { useLegacyPackaging = false }
        resources {
            excludes += listOf(
                "META-INF/LICENSE*",
                "META-INF/NOTICE*",
                "META-INF/DEPENDENCIES",
                "META-INF/*.version",
                "META-INF/*.properties"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Removed multidex dependency (evaluate if still necessary). Re-add if build fails with Dex overflow.
    implementation("com.google.android.play:integrity:1.3.0")
}

// Gradle Play Publisher configuration. Service account JSON will be provided at runtime by CI.
// CI step should write credentials to android/play/service-account.json (ignored from VCS).
play {
    serviceAccountCredentials.set(file("play/service-account.json"))
    track.set("internal") // change to production when ready
    defaultToAppBundles.set(true) // prefer AAB upload
    // Fail gracefully if credentials missing (local dev without publishing)
    enabled.set(file("play/service-account.json").exists())
}
