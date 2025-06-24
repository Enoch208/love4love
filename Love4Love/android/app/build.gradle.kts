plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.love4love"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.love4love"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true

        // Excluir x86 solo si no tienes un emulador x86
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")  // Excluye x86 si no lo usas
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = System.getenv("STORE_PASSWORD") ?: "Regy1185"
            keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "Regy1185"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        buildConfig = true
        viewBinding = true
    }

    packaging {
        resources {
            excludes += "META-INF/*"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.12.0")

    // Versión actualizada para Flutter Local Notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
}

flutter {
    source = "../.."
    target = "lib/main.dart"
}
