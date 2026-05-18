plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // El plugin de Flutter Gradle debe ir DESPUÉS de los plugins de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.proyectomoviles.barberly"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.proyectomoviles.barberly"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: configurar firma de release antes de publicar.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
