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

subprojects {
    // Redirect only plugin subprojects (not :app) to C: drive
    // to avoid the "different roots" error with Pub Cache on C:.
    if (project.name != "app") {
        val pluginBuildDir = File("C:/tmp/RepuNet/build/${project.name}")
        project.layout.buildDirectory.set(pluginBuildDir)
    } else {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
