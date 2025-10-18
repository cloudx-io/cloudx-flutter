allprojects {
    repositories {
        google()
        mavenCentral()
        mavenLocal()
        // Add mbridge repository required by CloudX SDK
        maven(url = "https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea")
        // CloudX Maven repository
        maven(url = "https://maven.pkg.github.com/cloudexchange-io/cloudexchange.android.sdk") {
            credentials {
                username = project.findProperty("github.username") as String? ?: System.getenv("GITHUB_USERNAME")
                password = project.findProperty("github.token") as String? ?: System.getenv("GITHUB_TOKEN")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
