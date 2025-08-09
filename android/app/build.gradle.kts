plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.spor_programi_app"
    // Bu satırları flutter.compileSdkVersion yerine doğrudan versiyon numarasıyla değiştiriyoruz
    compileSdk = 34 // Firebase için genellikle 33 veya 34 önerilir
    ndkVersion = "27.0.12077973" // Firebase'in istediği NDK versiyonu

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.spor_programi_app"
        // Bu satırı flutter.minSdkVersion yerine doğrudan versiyon numarasıyla değiştiriyoruz
        minSdk = 23 // Firebase için en az 23 olması gerekiyor
        targetSdk = flutter.targetSdkVersion // Bu flutter.targetSdkVersion olarak kalabilir
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}