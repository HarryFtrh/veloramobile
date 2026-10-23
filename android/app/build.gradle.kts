plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.velora.velora_mobile"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.velora.velora_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("default") {
            dimension = "app"
            applicationId = "com.velora.velora_mobile"
            resValue("string", "app_name", "Velora Mobile")
        }
        create("fnb") {
            dimension = "app"
            applicationId = "com.velora.fnb"
            resValue("string", "app_name", "Velora F&B")
        }
        create("customer") {
            dimension = "app"
            applicationId = "com.velora.roastery.customer"
            resValue("string", "app_name", "Artisan Roasters")
        }
        create("pharmacy") {
            dimension = "app"
            applicationId = "com.velora.pharmacy"
            resValue("string", "app_name", "Velora Pharmacy")
        }
        create("sales") {
            dimension = "app"
            applicationId = "com.velora.sales"
            resValue("string", "app_name", "Velora Sales")
        }
        create("marketplace") {
            dimension = "app"
            applicationId = "com.velora.marketplace"
            resValue("string", "app_name", "Velora Marketplace")
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
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

tasks.whenTaskAdded {
    if (name.startsWith("assemble")) {
        doLast {
            val rootBuild = File(rootDir, "../build/app/outputs")
            val localBuild = layout.buildDirectory.asFile.get()
            val apkDir = File(localBuild, "outputs/apk")
            if (apkDir.exists()) {
                val targetFlutterApk = File(rootBuild, "flutter-apk")
                targetFlutterApk.mkdirs()
                val apks = apkDir.walkTopDown().filter { it.extension == "apk" }.toList()
                apks.forEach { apk ->
                    apk.copyTo(File(targetFlutterApk, apk.name), overwrite = true)
                }
                // Prioritas: salin fnb-debug sebagai app-debug.apk
                val fnbApk = apks.find { it.name.contains("fnb", ignoreCase = true) && it.name.contains("debug", ignoreCase = true) }
                    ?: apks.find { it.name.contains("default", ignoreCase = true) && it.name.contains("debug", ignoreCase = true) }
                    ?: apks.firstOrNull { it.name.contains("debug", ignoreCase = true) }
                fnbApk?.copyTo(File(targetFlutterApk, "app-debug.apk"), overwrite = true)
            }
        }
    }
}
