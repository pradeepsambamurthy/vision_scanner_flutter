plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.eyesight_flutter"

    // Use Flutter’s compile/target/min values so `flutter` commands stay in sync
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.eyesight_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // No shrinking in debug
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // Keep debug signing so `flutter run --release` works while experimenting
            signingConfig = signingConfigs.getByName("debug")

            // IMPORTANT: do NOT shrink resources unless minify is ON.
            isMinifyEnabled = false
            isShrinkResources = false

            // You can keep this even if minify is off; it’s harmless
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Java/Kotlin 17 (required by modern AGP/Firebase)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    // Avoid common META-INF conflicts
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1"
            )
        }
    }
}

flutter { source = "../.." }

// (Optional) Firebase BOM keeps Firebase artifacts in sync
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-analytics")
}
