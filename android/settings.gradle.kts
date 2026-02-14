pluginManagement {
    val flutterSdkPath = try {
        val properties = java.util.Properties()
        val propertiesFile = java.io.File("local.properties")
        if (propertiesFile.exists()) {
            propertiesFile.inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        } else {
            val flutterRoot = System.getenv("FLUTTER_ROOT")
            require(flutterRoot != null) { "FLUTTER_ROOT not set in environmental variable" }
            flutterRoot
        }
    } catch (e: Exception) {
        throw GradleException("Flutter SDK not found.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // ALIYUN MIRRORS (Tezkor yuklash uchun)
        maven { url = java.net.URI("https://maven.aliyun.com/repository/google") }
        maven { url = java.net.URI("https://maven.aliyun.com/repository/public") }
        maven { url = java.net.URI("https://maven.aliyun.com/repository/gradle-plugin") }
        
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.3.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}

include(":app")
