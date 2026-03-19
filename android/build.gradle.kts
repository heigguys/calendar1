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

fun Project.forceAndroidCompileSdk(compileSdk: Int) {
    val androidExt = extensions.findByName("android") ?: return
    val methods = androidExt.javaClass.methods

    fun invokeIfFound(name: String, arg: Any): Boolean {
        val method = methods.firstOrNull {
            if (it.name != name || it.parameterCount != 1) {
                return@firstOrNull false
            }
            val parameterType = it.parameterTypes.firstOrNull() ?: return@firstOrNull false
            when (arg) {
                is Int ->
                    parameterType == Int::class.javaPrimitiveType ||
                        parameterType == Int::class.javaObjectType
                is String -> parameterType == String::class.java
                else -> false
            }
        } ?: return false
        method.invoke(androidExt, arg)
        return true
    }

    if (invokeIfFound("setCompileSdk", compileSdk)) return
    if (invokeIfFound("setCompileSdkVersion", compileSdk)) return
    if (invokeIfFound("compileSdkVersion", compileSdk)) return

    val sdkText = compileSdk.toString()
    if (invokeIfFound("setCompileSdkVersion", sdkText)) return
    invokeIfFound("compileSdkVersion", sdkText)
}

subprojects {
    afterEvaluate {
        ensureAndroidNamespace()
        forceAndroidCompileSdk(36)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


// 另一种尝试：如果上面的 beforeEvaluate 还是报错，请换成这个
allprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && requested.name == "core-ktx") {
                // 强制某些导致 lStar 问题的核心库版本对齐
            }
        }
    }
}
