import com.android.build.gradle.LibraryExtension
import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val libraryExtension = extensions.findByType(LibraryExtension::class.java)
        if (name == "on_audio_query_android" && libraryExtension?.namespace == null) {
            libraryExtension?.namespace = "com.lucas.musicplayer.on_audio_query"
        }
        if (name == "on_audio_query_android") {
            val manifestFile = file("src/main/AndroidManifest.xml")
            val sanitizedDir = layout.buildDirectory.dir("sanitizedManifests").get()
            val sanitizedFile = sanitizedDir.file("on_audio_query_android_manifest.xml").asFile

            val sanitizeTask = tasks.register("sanitizeOnAudioQueryManifest") {
                inputs.file(manifestFile)
                outputs.file(sanitizedFile)

                doLast {
                    val content = manifestFile.readText()
                        .replace("package=\"com.lucasjosino.on_audio_query\"", "")
                    sanitizedFile.parentFile?.mkdirs()
                    sanitizedFile.writeText(content)
                }
            }

            libraryExtension?.sourceSets?.named("main")?.configure {
                manifest.srcFile(sanitizedFile)
            }

            libraryExtension?.compileOptions?.apply {
                sourceCompatibility = JavaVersion.VERSION_1_8
                targetCompatibility = JavaVersion.VERSION_1_8
            }

            tasks.withType(KotlinJvmCompile::class.java).configureEach {
                compilerOptions.jvmTarget.set(JvmTarget.JVM_1_8)
            }

            tasks.matching { it.name == "preBuild" }.configureEach {
                dependsOn(sanitizeTask)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
