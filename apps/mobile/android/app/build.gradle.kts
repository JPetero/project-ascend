import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// S14 Part 1 — real release signing, with a hard build failure for the
// `prod` flavor when it's missing, replacing S13 Part 16-27's silent
// debug-signing fallback for every flavor (a `prod release` binary
// signed with the well-known Flutter debug key must never be produced
// and mistaken for a real release artifact). Two equally-valid sources,
// checked in this order:
//
//   1. `android/key.properties` (never committed — see .gitignore and
//      key.properties.example) for local developer builds.
//   2. `ASCEND_KEYSTORE_PATH` / `ASCEND_KEYSTORE_PASSWORD` /
//      `ASCEND_KEY_ALIAS` / `ASCEND_KEY_PASSWORD` environment variables
//      for CI, where committing a keystore file is never appropriate —
//      these are injected from GitHub Actions secrets instead.
//
// `dev`/`staging` flavors are untouched by this and keep falling back to
// debug signing (explicitly fine for local/internal-test builds); only
// `assembleProdRelease`/`bundleProdRelease` are guarded below.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun releaseSigningValue(envVar: String, propertyKey: String): String? {
    val fromEnv = System.getenv(envVar)
    if (!fromEnv.isNullOrBlank()) return fromEnv
    val fromProperties = keystoreProperties.getProperty(propertyKey)
    return if (fromProperties.isNullOrBlank()) null else fromProperties
}

val releaseStoreFile = releaseSigningValue("ASCEND_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = releaseSigningValue("ASCEND_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = releaseSigningValue("ASCEND_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = releaseSigningValue("ASCEND_KEY_PASSWORD", "keyPassword")
val hasReleaseSigning =
    releaseStoreFile != null &&
        releaseStorePassword != null &&
        releaseKeyAlias != null &&
        releaseKeyPassword != null

android {
    namespace = "com.projectascend.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // S14 Part 4 — required for the per-flavor resValue("string",
    // "app_name", ...) calls below. Confirmed via a real GitHub Actions
    // run (not guessed): without this, AGP fails configuration with
    // "Product Flavor dev contains custom resource values, but the
    // feature is disabled" — resValues defaults to off in current AGP
    // versions. This is why the CI Android build job has never actually
    // succeeded since flavors were introduced, undetected until this
    // session could observe a real run (no Android SDK exists in the
    // sandbox that wrote the original flavor config).
    buildFeatures {
        resValues = true
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

    // Declared before productFlavors below, which references
    // signingConfigs.getByName("release") — Gradle Kotlin DSL blocks
    // execute top-to-bottom during configuration, so the signing config
    // must exist before anything looks it up by name.
    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
            }
        }
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
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Else: falls through to buildTypes.release's debug
            // signingConfig below — but the taskGraph guard further down
            // throws before assembleProdRelease/bundleProdRelease can
            // actually produce that binary, so this fallback is never
            // reached for a real prod artifact.
        }
    }

    buildTypes {
        release {
            // dev/staging always sign with the debug key — fine for
            // local development and internal test builds, which is why
            // this default is untouched by the prod-only guard below.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Hard-fails a `prod` release/bundle build when real signing isn't
// configured, instead of silently shipping a debug-signed binary that
// looks like a production artifact. Checking the resolved task graph
// (rather than e.g. `afterEvaluate`) means this also catches an
// umbrella invocation like a bare `assembleRelease` that pulls in
// `assembleProdRelease` as one of several flavor tasks.
gradle.taskGraph.whenReady {
    val buildingProdRelease = allTasks.any { task ->
        task.name.equals("assembleProdRelease", ignoreCase = true) ||
            task.name.equals("bundleProdRelease", ignoreCase = true)
    }
    if (buildingProdRelease && !hasReleaseSigning) {
        throw GradleException(
            "Production release signing is not configured.\n" +
                "Provide apps/mobile/android/key.properties (copy " +
                "key.properties.example and fill in real values) or set " +
                "ASCEND_KEYSTORE_PATH / ASCEND_KEYSTORE_PASSWORD / " +
                "ASCEND_KEY_ALIAS / ASCEND_KEY_PASSWORD environment " +
                "variables before building the prod release or bundle. " +
                "See packages/docs/founder-setup-checklist.md.",
        )
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
