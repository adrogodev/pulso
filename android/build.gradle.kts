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
// Legacy plugins (e.g. on_audio_query_android) don't declare a namespace,
// which AGP 8+ requires, and compile against SDKs older than what their
// AndroidX dependencies need. Patch both without forking the plugin.
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType<com.android.build.gradle.LibraryExtension>()
        if (android.namespace == null) {
            android.namespace = project.group.toString()
        }
        // The plugin's own `android {}` block runs after this callback, so the
        // compileSdk override must happen once its DSL is finalized.
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl { dsl ->
                if ((dsl.compileSdk ?: 0) < 34) {
                    // Keep in sync with app/build.gradle.kts.
                    dsl.compileSdk = 37
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
