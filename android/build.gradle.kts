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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

fun Project.ensureAndroidNamespace() {
    val androidExt = extensions.findByName("android") ?: return
    val getNamespace =
        androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
            ?: return
    val setNamespace =
        androidExt.javaClass.methods.firstOrNull {
            it.name == "setNamespace" &&
                it.parameterCount == 1 &&
                it.parameterTypes.firstOrNull() == String::class.java
        } ?: return

    val currentNamespace = getNamespace.invoke(androidExt) as? String
    if (!currentNamespace.isNullOrBlank()) {
        return
    }

    val manifest = file("src/main/AndroidManifest.xml")
    val manifestPackage =
        if (manifest.exists()) {
            Regex("""package\s*=\s*"([^"]+)"""")
                .find(manifest.readText())
                ?.groupValues
                ?.getOrNull(1)
        } else {
            null
        }

    val fallbackNamespace = "autofix.${name.replace('-', '_')}"
    setNamespace.invoke(androidExt, manifestPackage ?: fallbackNamespace)
}

subprojects {
    afterEvaluate {
        ensureAndroidNamespace()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
