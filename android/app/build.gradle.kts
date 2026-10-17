import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 🎯 شناسه یکتای اپ که توی مایکت و تپسل ثبت کردی
    namespace = "ir.amirali.hooshyar"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "ir.amirali.hooshyar"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
        
        // 🎯 فعال‌سازی MultiDex (به خاطر حجم بالای کدهای تپسل)
        multiDexEnabled = true
        
        // 🎯 کلید تپسل برای استفاده در AndroidManifest (حیاتی برای جلوگیری از کرش)
        manifestPlaceholders["TapsellMediationAppKey"] = "sdsdftnpetlllqqsogjrsfkpeokciqtbgkdisnlflekdmqoadhdojfnpsfjdssljnjhfba"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // حفظ امضای اپ برای انتشار در مایکت
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}