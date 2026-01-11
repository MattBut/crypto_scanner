// Импорт классов для работы с файлами
import java.util.Properties
import java.io.FileInputStream
import java.io.File

// --- 1. БЛОК ЧТЕНИЯ КОНФИГУРАЦИИ КЛЮЧА ПОДПИСИ (key.properties) ---
val signingConfigsProps = Properties()
// key.properties находится в папке 'android/' (rootProject), поэтому читаем его оттуда.
val signingPropsFile = project.rootProject.file("key.properties")
if (signingPropsFile.exists()) {
    try {
        FileInputStream(signingPropsFile).use { signingConfigsProps.load(it) }
    } catch (e: Exception) {
        throw GradleException("Не удалось прочитать файл key.properties: ${e.message}")
    }
} else {
    println("ПРЕДУПРЕЖДЕНИЕ: key.properties не найден. Сборка для релиза завершится ошибкой.")
}
// ----------------------------------------------------------------

// --- 2. БЛОК ЧТЕНИЯ FLUTTER SDK (local.properties) ---
// Получаем доступ к local.properties, который также находится в корневом каталоге 'android/'
val localPropertiesFile = project.rootProject.file("local.properties")
val localProperties = Properties()
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { localProperties.load(it) }
}

val flutterRoot = localProperties.getProperty("flutter.sdk")
if (flutterRoot == null) {
    throw GradleException("Flutter SDK не найден. Определите расположение с помощью flutter.sdk в файле local.properties.")
}
// --------------------------------------------------------


plugins {
    id("com.android.application")
    kotlin("android")
    // Плагин Flutter Gradle должен быть применен после плагинов Android и Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "online.iprofi.crypto_scanner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 3. Определение конфигурации подписи
    signingConfigs {
        create("release") {
            // Чтение пути из Properties с использованием Kotlin-синтаксиса []
            val storeFilePath = signingConfigsProps["storeFile"] as String
            
            // ГЛАВНОЕ ИСПРАВЛЕНИЕ ПУТИ: project.file() разрешает путь относительно текущего модуля (app).
            // Если в key.properties указано "app/butiaev_development.jks", это правильно указывает на android/app/butiaev_development.jks.
            storeFile = project.file(storeFilePath) 

            keyAlias = signingConfigsProps["keyAlias"] as String
            storePassword = signingConfigsProps["storePassword"] as String
            keyPassword = signingConfigsProps["keyPassword"] as String
        }
    }


    defaultConfig {
        applicationId = "online.iprofi.crypto_scanner"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Применяем созданную конфигурацию 'release'
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
