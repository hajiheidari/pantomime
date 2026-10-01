import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Store flavors. Each store gets its own upload/signing key, stored OUTSIDE
// git in android/keys/<store>.properties (see docs/store_notes.md):
//   storeFile=/absolute/path/to/<store>-upload.jks
//   storePassword=…
//   keyAlias=…
//   keyPassword=…
// Without that file the release build is signed with the debug key (fine for
// local testing, never for uploading).
val stores = listOf("play", "bazaar", "myket")

fun keyProps(store: String): Properties? {
    val f = rootProject.file("keys/$store.properties")
    if (!f.exists()) return null
    return Properties().apply { f.inputStream().use { load(it) } }
}

android {
    // REPLACE_ME: set your real package name here and in applicationId.
    namespace = "com.REPLACE_ME.pantomime"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Same applicationId in every store (Bazaar and Myket allow it).
        applicationId = "com.REPLACE_ME.pantomime"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Real id: pass -PADMOB_APP_ID=ca-app-pub-…~… (keep it out of git).
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("ADMOB_APP_ID") as String?)
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        for (store in stores) {
            val p = keyProps(store) ?: continue
            create(store) {
                storeFile = file(p.getProperty("storeFile"))
                storePassword = p.getProperty("storePassword")
                keyAlias = p.getProperty("keyAlias")
                keyPassword = p.getProperty("keyPassword")
            }
        }
    }

    flavorDimensions += "store"
    productFlavors {
        for (store in stores) {
            create(store) {
                dimension = "store"
                // Read by Flutter as `appFlavor` → AppStore.detect().
                signingConfig = signingConfigs.findByName(store)
                    ?: signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        release {
            // Flavor signing configs apply; debug key only as a fallback.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
