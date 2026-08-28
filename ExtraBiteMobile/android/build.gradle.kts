allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

extra.set("flutter", mapOf(
    "compileSdkVersion" to 36,
    "minSdkVersion" to 21,
    "targetSdkVersion" to 36,
    "ndkVersion" to "28.2.13676358"
))

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

subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" &&
                (requested.name == "core" || requested.name == "core-ktx")) {
                useVersion("1.13.1")
            }
            if (requested.group == "androidx.core" && requested.name == "core-viewtree") {
                useVersion("1.0.0")
            }
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
            if (requested.group == "androidx.activity") {
                useVersion("1.9.3")
            }
            if (requested.group == "androidx.navigationevent") {
                useVersion("1.0.0-alpha02")
            }
        }
    }
}
