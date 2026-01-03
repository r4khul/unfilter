package com.rakhul.unfilter

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import java.io.ByteArrayInputStream
import java.io.File
import java.security.MessageDigest
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.util.zip.ZipFile

class DeepAnalyzer(private val context: Context) {

    fun analyze(pkg: PackageInfo, pm: PackageManager): Map<String, Any?> {
        val appInfo = pkg.applicationInfo ?: return emptyMap()
        val analysis = mutableMapOf<String, Any?>()

        // 1. Installer Source
        val installer = getInstallerPackageName(pkg.packageName, pm)
        analysis["installerStore"] = installer ?: "Unknown"

        // 2. Signing Info (SHA-1 & SHA-256)
        val signatures = getSignatures(pkg, pm)
        if (signatures.isNotEmpty()) {
            val cert = signatures[0]
            analysis["signingSha1"] = getFingerprint(cert, "SHA-1")
            analysis["signingSha256"] = getFingerprint(cert, "SHA-256")
        }

        // 3. Component Counts
        analysis["activitiesCount"] = pkg.activities?.size ?: 0
        analysis["servicesCount"] = pkg.services?.size ?: 0
        analysis["receiversCount"] = pkg.receivers?.size ?: 0
        analysis["providersCount"] = pkg.providers?.size ?: 0

        // 4. Advanced Stack Version Detection
        val techVersions = mutableMapOf<String, String>()
        val apkPath = appInfo.sourceDir
        if (apkPath != null && File(apkPath).exists()) {
             try {
                ZipFile(File(apkPath)).use { zip ->
                    // Kotlin
                    detectKotlinVersion(zip)?.let { techVersions["Kotlin"] = it }
                    
                    // React Native
                    detectReactNativeVersion(zip)?.let { techVersions["React Native"] = it }
                    
                    // Unity
                    detectUnityVersion(zip)?.let { techVersions["Unity"] = it }
                    
                    // Flutter (Basic)
                    detectFlutterVersion(zip)?.let { techVersions["Flutter"] = it }
                }
             } catch (e: Exception) { }
        }
        
        if (techVersions.isNotEmpty()) {
            analysis["techVersions"] = techVersions
        }
        
        // Backward compatibility for UI
        if (techVersions.containsKey("Kotlin")) {
            analysis["kotlinVersion"] = techVersions["Kotlin"]
        }

        // 5. Split APKs
        val splitNames = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
             appInfo.splitNames?.toList() ?: emptyList<String>()
        } else {
             emptyList<String>()
        }
        analysis["splitApks"] = splitNames

        // 6. Native Lib Architecture
        // primaryCpuAbi caused compilation issues, removed for now.
        analysis["primaryCpuAbi"] = "Unknown"

        return analysis
    }

    private fun getInstallerPackageName(packageName: String, pm: PackageManager): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                pm.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(packageName)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getSignatures(pkg: PackageInfo, pm: PackageManager): List<ByteArray> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val signingInfo = pkg.signingInfo
                if (signingInfo != null) {
                    if (signingInfo.hasMultipleSigners()) {
                        signingInfo.apkContentsSigners.map { it.toByteArray() }
                    } else {
                        signingInfo.signingCertificateHistory.map { it.toByteArray() }
                    }
                } else {
                    emptyList()
                }
            } else {
                @Suppress("DEPRECATION")
                val signatures = pkg.signatures
                signatures?.map { it.toByteArray() } ?: emptyList()
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun getFingerprint(signature: ByteArray, algorithm: String): String {
        return try {
            val certFactory = CertificateFactory.getInstance("X509")
            val x509Cert = certFactory.generateCertificate(ByteArrayInputStream(signature)) as X509Certificate
            val md = MessageDigest.getInstance(algorithm)
            val digest = md.digest(x509Cert.encoded)
            digest.joinToString(":") { "%02X".format(it) }
        } catch (e: Exception) {
            "Error"
        }
    }

    private fun detectKotlinVersion(zip: ZipFile): String? {
        try {
            val entry = zip.getEntry("META-INF/maven/org.jetbrains.kotlin/kotlin-stdlib/pom.properties")
            if (entry != null) {
                zip.getInputStream(entry).use { stream ->
                    val props = java.util.Properties()
                    props.load(stream)
                    return props.getProperty("version")
                }
            }
        } catch (e: Exception) { }
        return null
    }

    private fun detectFlutterVersion(zip: ZipFile): String? {
        try {
            // Check libflutter.so for engine hash or version string if visible
            // Note: Scanning large binaries is slow, read only header or small chunks
            val abis = arrayOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
            var libEntry: java.util.zip.ZipEntry? = null
            
            for (abi in abis) {
                libEntry = zip.getEntry("lib/$abi/libflutter.so")
                if (libEntry != null) break
            }

            if (libEntry != null) {
                 // Scan first 32KB for "Flutter <version>" string
                 // This primarily works for Debug/Profile builds or specific engine variants
                 zip.getInputStream(libEntry).use { stream ->
                     val buffer = ByteArray(32 * 1024)
                     val read = stream.read(buffer)
                     if (read > 0) {
                         val content = String(buffer, 0, read)
                         // Look for "Flutter 3.x.x" etc.
                         val regex = "Flutter (\\d+\\.\\d+\\.\\d+)".toRegex()
                         val match = regex.find(content)
                         if (match != null) {
                             return match.groupValues[1]
                         }
                     }
                 }
            }
            
            // Note: version.json usually contains App Version, not SDK version, so we skip it 
            // to avoid confusing the user with "1.0.0" when they expect SDK version.
        } catch (e: Exception) { }
        return null
    }

    private fun detectReactNativeVersion(zip: ZipFile): String? {
        try {
            val entry = zip.getEntry("assets/index.android.bundle")
            if (entry != null) {
                zip.getInputStream(entry).use { stream ->
                    val buffer = ByteArray(1024)
                    val read = stream.read(buffer)
                    if (read > 0) {
                        val header = String(buffer, 0, read)
                        if (header.contains("Hermes")) {
                            // "Hermes JavaScript bytecode, version 84"
                            val regex = "Hermes JavaScript bytecode, version (\\d+)".toRegex()
                            val match = regex.find(header)
                            if (match != null) {
                                return "Hermes Bytecode v${match.groupValues[1]}"
                            }
                            return "Hermes Enabled"
                        }
                        return "Standard Bundle" 
                    }
                }
            }
        } catch (e: Exception) { }
        return null
    }

    private fun detectUnityVersion(zip: ZipFile): String? {
        try {
            val entry = zip.getEntry("assets/bin/Data/ProjectSettings") 
                ?: zip.getEntry("assets/bin/Data/globalgamemanagers")
                ?: zip.getEntry("assets/bin/Data/data.unity3d")
            
            if (entry != null) {
                zip.getInputStream(entry).use { stream ->
                    val buffer = ByteArray(8192) // Read 8KB
                    val read = stream.read(buffer)
                    if (read > 0) {
                        val text = String(buffer, 0, read)
                        val regex = "(\\d+\\.\\d+\\.\\d+[a-z]\\d+)".toRegex()
                        val match = regex.find(text)
                        if (match != null) {
                            return match.groupValues[1]
                        }
                    }
                }
            }
        } catch (e: Exception) { }
        return null
    }
}
