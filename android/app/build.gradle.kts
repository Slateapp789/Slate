import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
val requiredSigningProperties = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val missingSigningProperties = requiredSigningProperties.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
val releaseStoreFile = keystoreProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let(rootProject::file)

if (releaseTaskRequested) {
    when {
        !keystorePropertiesFile.exists() -> throw GradleException(
            "Release signing is not configured. Copy android/key.properties.example " +
                "to android/key.properties and provide the Play signing credentials."
        )
        missingSigningProperties.isNotEmpty() -> throw GradleException(
            "Android release signing is missing: ${missingSigningProperties.joinToString()}."
        )
        releaseStoreFile?.isFile != true -> throw GradleException(
            "Android release signing storeFile does not exist: " +
                (releaseStoreFile?.path ?: "<not configured>")
        )
    }
}

android {
    namespace = "com.ismaeel.workloop"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ismaeel.workloop"
        minSdk = 24
        targetSdk = 36
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (missingSigningProperties.isEmpty() && releaseStoreFile?.isFile == true) {
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isDebuggable = false
            isJniDebuggable = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
