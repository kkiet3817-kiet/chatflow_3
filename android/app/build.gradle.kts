plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // Nâng cấp lên 36 theo yêu cầu của các plugin
    namespace = "com.example.chatflo"
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.example.chatflow_3"
        minSdk = flutter.minSdkVersion // Đặt thủ công 21 để đảm bảo chạy được Firebase
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
=======
        applicationId = "com.example.chatflo"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // Nên đồng bộ targetSdk với compileSdk
        versionCode = 1
        versionName = "1.0"
        
        multiDexEnabled = true
>>>>>>> 70dee18ea0a01a242d90e66029636ad964427b7a
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
