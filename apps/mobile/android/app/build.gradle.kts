import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// S13 Part 16-27 — real release signing. `key.properties` is never
// committed (see android/.gitignore and key.properties.example for the
// template); when it's absent — every environment this repo has been
// built in so far, including this sandbox with no Android SDK — the
// release build type falls back to debug signing below, exactly as
// Flutter's default template did, so `flutter build apk --release`
// keeps working without real signing secrets. This is an honest
// fallback, not a silent stand-in: the Founder setup checklist covers
// generating a real upload keystore and populating key.properties.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.projectascend.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.projectascend.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev/staging/prod environments (S13 Part 16-27) — each flavor gets
    // its own applicationId (via suffix) and app_name, so all three can
    // be installed side by side on one device for testing without
    // overwriting each other. `prod` is the "real" identity
    // (com.projectascend.mobile, no suffix) so it matches whatever
    // Play Store listing/Firebase project eventually gets configured
    // for it. Every `flutter run`/`flutter build` invocation must pass
    // `--flavor dev|staging|prod` once this exists — see the README's
    // "Start the Flutter app" section.
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Ascend Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Ascend Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Ascend")
        }
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                // Signing with the debug keys for now, so `flutter build
                // apk --release`/`flutter run --release` work without a
                // real keystore. See the comment on keystorePropertiesFile
                // above.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
