plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.total_english"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // ✅ Bật desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.total_english"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // signingConfigs {
    //     create("release") {
    //         storeFile = file(System.getProperty("user.home") + "/totalenglish-key.jks")
    //         storePassword = "123456"
    //         keyAlias = "totalenglish"
    //         keyPassword = "123456"
    //     }
    // }
    // buildTypes {
    //     getByName("release") {
    //         signingConfig = signingConfigs.getByName("debug")
    //         //signingConfig = signingConfigs.getByName("release") sửa xong sai
    //         isMinifyEnabled = false
    //         isShrinkResources = false
    //         proguardFiles(
    //             getDefaultProguardFile("proguard-android-optimize.txt"),
    //             file("proguard-rules.pro")
    //         )
    //     }
    // }
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

}

flutter {
    source = "../.."
}
dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

  // 🔔 Firebase Cloud Messaging
  implementation("com.google.firebase:firebase-messaging") // ✅ Kotlin-style
  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  // https://firebase.google.com/docs/android/setup#available-libraries
  
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

}