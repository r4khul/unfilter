package com.example.findstack

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

        // 4. Advanced Kotlin Version Detection
        val kotlinVersion = detectKotlinVersion(appInfo)
        if (kotlinVersion != null) {
            analysis["kotlinVersion"] = kotlinVersion
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

    private fun detectKotlinVersion(appInfo: ApplicationInfo): String? {
        val apkPath = appInfo.sourceDir ?: return null
        val file = File(apkPath)
        if (!file.exists()) return null

        try {
            ZipFile(file).use { zip ->
                val entries = zip.entries()
                while (entries.hasMoreElements()) {
                    val entry = entries.nextElement()
                    val name = entry.name
                    
                    // Kotlin Module files contain version in header
                    // Format: .kotlin_module
                    if (name.endsWith(".kotlin_module")) {
                        zip.getInputStream(entry).use { stream ->
                            // The header for binary metadata is distinct, but kotlin_module files 
                            // often start with a small integer version header.
                            // However, parsing strictly is complex. A simple heuristic is hard here 
                            // without a proto buf parser.
                            // BUT, we can sometimes find "kotlin-stdlib-<version>" in META-INF path
                        }
                    }
                    
                    // Easier heuristic: Look for kotlin-stdlib version files in META-INF
                    // Many builds include META-INF/kotlin-stdlib.kotlin_module or version files
                    // Or "META-INF/maven/org.jetbrains.kotlin/kotlin-stdlib/pom.properties"
                    if (name.equals("META-INF/kotlin-stdlib.kotlin_module")) {
                        // This confirms stdlib presence.
                        // Let's try to find maven properties which are VERY common in builds.
                    }
                    
                    if (name.contains("META-INF/maven/org.jetbrains.kotlin/kotlin-stdlib/pom.properties")) {
                         zip.getInputStream(entry).use { stream ->
                             val props = java.util.Properties()
                             props.load(stream)
                             return props.getProperty("version")
                         }
                    }
                }
            }
        } catch (e: Exception) { }
        return null
    }
}
