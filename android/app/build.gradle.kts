import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.brianhenning.minnesota_whist"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.brianhenning.minnesota_whist"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Keystore file path
            val keystorePath = "${System.getProperty("user.home")}/.android/keystores/minnesota-whist-release-key.jks"
            val keystoreFile = file(keystorePath)

            // Get passwords from environment (optional - won't fail if not set)
            val keystorePassword = System.getenv("MINNESOTAWHIST_KEYSTORE_PASSWORD")
            val keyPassword = System.getenv("MINNESOTAWHIST_KEY_PASSWORD")

            if (keystoreFile.exists() && keystorePassword != null && keyPassword != null) {
                storeFile = keystoreFile
                storePassword = keystorePassword
                this.keyPassword = keyPassword

                // Key alias from properties file or default
                keyAlias = keystoreProperties.getProperty("keyAlias")?.takeIf { it.isNotEmpty() }
                    ?: "minnesota-whist-release"

                println("Release signing configured with keystore: $keystorePath")
            } else {
                if (!keystoreFile.exists()) {
                    println("Warning: Release keystore not found at $keystorePath")
                }
                if (keystorePassword == null || keyPassword == null) {
                    println("Warning: MINNESOTAWHIST_KEYSTORE_PASSWORD or MINNESOTAWHIST_KEY_PASSWORD not set")
                }
                println("Release builds will be unsigned. Debug builds will work normally.")
            }
        }
    }

    buildTypes {
        release {
            // Only sign if keystore exists
            val releaseSigningConfig = signingConfigs.getByName("release")
            if (releaseSigningConfig.storeFile?.exists() == true) {
                signingConfig = releaseSigningConfig
            }
            // Enable ProGuard/R8 for release builds
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
