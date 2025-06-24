
// ✅ settings.gradle.kts (Kotlin DSL)
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val sdk = properties.getProperty("flutter.sdk")
        require(sdk != null) { "flutter.sdk not set in local.properties" }
        sdk
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

include(":app")
