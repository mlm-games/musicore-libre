allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    configurations.configureEach {
        // For fdroid
        exclude(group = "com.google.android.play", module = "core")
        exclude(group = "com.google.android.play", module = "core-ktx")
        exclude(group = "com.google.android.play", module = "feature-delivery")
        exclude(group = "com.google.android.play", module = "feature-delivery-ktx")
        exclude(group = "com.google.android.play", module = "asset-delivery")
        exclude(group = "com.google.android.play", module = "asset-delivery-ktx")
        exclude(group = "com.google.android.play", module = "app-update")
        exclude(group = "com.google.android.play", module = "app-update-ktx")
        exclude(group = "com.google.android.play")
        exclude(group = "com.google.android.gms")  // just in case
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
