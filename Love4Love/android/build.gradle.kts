@file:Suppress("DEPRECATION")

// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    val kotlinVersion = "1.9.22"

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.3.0") // ✅ Usa 8.3.0 en lugar de 8.6.0 por compatibilidad estable
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:4.4.1")
        // Si usas Firebase Crashlytics o Performance, debes agregar esos classpath aquí también
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
