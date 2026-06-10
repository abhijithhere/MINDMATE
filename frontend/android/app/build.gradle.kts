plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🟢 1. Enable Core Library Desugaring
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
            applicationId = "com.example.frontend"
            
            // 🟢 Set this to 21 manually to fix the Desugaring/Notification errors
            minSdk = flutter.minSdkVersion 
            
            targetSdk = flutter.targetSdkVersion
            versionCode = flutter.versionCode
            versionName = flutter.versionName
        }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(kotlin("stdlib-jdk7"))
    
    // 🟢 3. Add the Desugar JDK library dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
