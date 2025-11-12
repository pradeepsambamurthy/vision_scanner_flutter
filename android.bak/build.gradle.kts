// android/build.gradle.kts (project level)

buildscript {
    repositories { google(); mavenCentral() }
}

plugins {
    // Keep ONLY the application plugin here with a version.
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false

    // Google Services plugin: declare version here, apply in app/build.gradle
    id("com.google.gms.google-services") version "4.4.2" apply false
 
}

allprojects {
    repositories { google(); mavenCentral() }
}

