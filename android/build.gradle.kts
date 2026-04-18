import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://artifactory-external.vkpartner.ru/artifactory/vkid-sdk-android/")
        }
        maven {
            url = uri("https://artifactory-external.vkpartner.ru/artifactory/vk-id-captcha/android/")
        }
        maven {
            url = uri("https://artifactory-external.vkpartner.ru/artifactory/maven/")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Для новых JDK убираем устаревшие source/target=8 в подпроектах и плагинах.
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {
  id("com.google.gms.google-services") version "4.4.4" apply false
  id("vkid.manifest.placeholders") version "1.1.0" apply true
}

vkidManifestPlaceholders {
  val clientId = findProperty("VKID_CLIENT_ID")?.toString() ?: "0"
  val clientSecret = findProperty("VKID_CLIENT_SECRET")?.toString() ?: ""
  init(
    clientId = clientId,
    clientSecret = clientSecret,
  )
  vkidRedirectHost = "vk.ru"
  vkidRedirectScheme = "vk$clientId"
  vkidClientId = clientId
  vkidClientSecret = clientSecret
}
