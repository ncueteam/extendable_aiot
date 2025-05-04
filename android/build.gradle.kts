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
    
    // 為 flutter_bluetooth_serial 添加命名空間
    afterEvaluate {
        if (project.name == "flutter_bluetooth_serial" && 
            project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            val androidExtension = android as com.android.build.gradle.LibraryExtension
            androidExtension.namespace = "com.github.edufolly.flutterbluetoothserial"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
