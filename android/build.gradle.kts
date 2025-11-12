import org.gradle.api.tasks.compile.JavaCompile

buildscript {
    repositories { google(); mavenCentral() }
}

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories { google(); mavenCentral() }
}

// Keep Flutter's conventional build dir layout
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
    project.evaluationDependsOn(":app")
}

// ⬇️ add this suppression block here
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(
            listOf("-Xlint:-unchecked", "-Xlint:-deprecation", "-Xlint:-options")
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
