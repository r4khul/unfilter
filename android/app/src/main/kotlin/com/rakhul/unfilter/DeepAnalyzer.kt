package com.rakhul.unfilter

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.util.SparseArray
import kotlinx.coroutines.*
import java.io.File
import java.io.InputStream
import java.io.ByteArrayInputStream
import java.security.MessageDigest
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import com.rakhul.unfilter.LibSignatures.MatchType

/**
 * DeepAnalyzer: A high-performance, fault-tolerant, concurrent inspection engine for Android APKs.
 * Uses advanced streaming forensics (ByteTrie, Header Skipping) to detect technologies at "Rocket Jet" speed.
 */
class DeepAnalyzer(private val context: Context) {

    data class DetectedLibrary(
        val name: String,
        val category: String,
        val version: String? = null,
        val source: String
    )

    // --- High-Performance Constants ---
    companion object {
        private const val DEX_HEADER_SIZE = 112
        private const val BUFFER_SIZE_LARGE = 256 * 1024 // 256KB for maximum throughput
        private const val STRING_IDS_OFF_OFFSET = 60
        private val FLUTTER_VER_REGEX = "Flutter (\\d+\\.\\d+\\.\\d+)".toRegex()
    }

    // --- Micro-Optimized Rooted Trie ---
    // Uses a fixed array for the first byte (O(1) access) and SparseArrays for deeper levels.
    class FastByteTrie {
        class Node {
            val children = SparseArray<Node>(4) // Initial capacity optimization
            var matchRule: LibSignatures.Rule? = null
        }
        
        val root = arrayOfNulls<Node>(256)

        fun insert(rule: LibSignatures.Rule) {
            val bytes = rule.pattern.toByteArray()
            if (bytes.isEmpty()) return
            
            val firstByte = bytes[0].toInt() and 0xFF
            var node = root[firstByte]
            if (node == null) {
                node = Node()
                root[firstByte] = node
            }

            for (i in 1 until bytes.size) {
                val key = bytes[i].toInt() and 0xFF
                var child = node!!.children.get(key)
                if (child == null) {
                    child = Node()
                    node.children.put(key, child)
                }
                node = child
            }
            node!!.matchRule = rule
        }
    }

    private val dexTrie = FastByteTrie()
    private val flutterPackageBytes = "package:".toByteArray()
    
    // Dedicated IO Dispatcher with Supervisor to ensure system stability
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    init {
        // Pre-compute lookup structures (One-time cost)
        LibSignatures.RULES.filter { it.type == MatchType.DEX_PATH }.forEach { dexTrie.insert(it) }
    }

    fun analyze(pkg: PackageInfo, pm: PackageManager): Map<String, Any?> {
        val appInfo = pkg.applicationInfo ?: return emptyMap()
        val analysis = mutableMapOf<String, Any?>()

        // 1. Metadata Extraction (Instant Access)
        extractMetadata(pkg, pm, analysis)

        // 2. Parallel Deep Forensic Scan (The Heavy Lifting)
        val apkPath = appInfo.sourceDir
        if (apkPath != null && File(apkPath).exists()) {
             runBlocking {
                 val rawResults = scanApkParallel(apkPath)
                 
                 // Smart Consolidation: Refine duplicates to cleaner output
                 val refinedResults = consolidateLibraries(rawResults)
                 
                 val techStack = refinedResults.map { lib ->
                     mapOf(
                         "name" to lib.name,
                         "category" to lib.category,
                         "version" to (lib.version ?: ""),
                         "source" to lib.source
                     )
                 }
                 analysis["techStack"] = techStack

                 // Legacy Compatibility & Framework Versions
                 val languages = extractFrameworkVersions(refinedResults)
                 
                 if (!languages.containsKey("Kotlin")) {
                    val hasKotlin = withContext(Dispatchers.IO) {
                         try {
                              ZipFile(File(apkPath)).use { zip -> 
                                  scanForKotlinInternal(zip)
                              }
                         } catch(e: Exception) { false }
                    }
                    if (hasKotlin) languages["Kotlin"] = "Detected"
                 }
                 
                 if (languages.isNotEmpty()) {
                      analysis["techVersions"] = languages
                      if (languages.containsKey("Kotlin")) analysis["kotlinVersion"] = languages["Kotlin"]
                 }
             }
        } else {
             analysis["splitApks"] = emptyList<String>()
        }
        
        return analysis
    }

    private fun extractMetadata(pkg: PackageInfo, pm: PackageManager, analysis: MutableMap<String, Any?>) {
        analysis["installerStore"] = getInstallerPackageName(pkg.packageName, pm) ?: "Unknown"
        
        // Split APKs
        val splitNames = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
             pkg.applicationInfo?.splitNames?.toList() ?: emptyList<String>()
        } else emptyList<String>()
        analysis["splitApks"] = splitNames
        
        val signatures = getSignatures(pkg, pm)
        if (signatures.isNotEmpty()) {
            val cert = signatures[0]
            analysis["signingSha1"] = getFingerprint(cert, "SHA-1")
            analysis["signingSha256"] = getFingerprint(cert, "SHA-256")
        }
        analysis["activitiesCount"] = pkg.activities?.size ?: 0
        analysis["servicesCount"] = pkg.services?.size ?: 0
        analysis["receiversCount"] = pkg.receivers?.size ?: 0
        analysis["providersCount"] = pkg.providers?.size ?: 0
    }

    private fun extractFrameworkVersions(libs: List<DetectedLibrary>): MutableMap<String, String> {
        val map = mutableMapOf<String, String>()
        libs.filter { it.category == "Framework" || it.category == "Game Engine" }
            .forEach { map[it.name] = it.version ?: "" }
        return map
    }

    private fun consolidateLibraries(raw: List<DetectedLibrary>): List<DetectedLibrary> {
        // Group by name, pick the one with version, or fallback to ANY.
        return raw.groupBy { it.name }.map { (_, instances) ->
            // Prioritize instances with Version presence
            instances.maxByOrNull { (if (it.version != null) 10 else 0) } ?: instances.first()
        }.sortedBy { it.name }
    }

    private suspend fun scanApkParallel(apkPath: String): List<DetectedLibrary> = withContext(Dispatchers.IO) {
        val detected = Collections.newSetFromMap(ConcurrentHashMap<DetectedLibrary, Boolean>())
        
        try {
            ZipFile(File(apkPath)).use { zip ->
                val entries = zip.entries().toList()
                val entryNames = entries.map { it.name }
                
                // A. Instant File Name Checks
                LibSignatures.RULES.forEach { rule ->
                    if (rule.type == MatchType.NATIVE_LIB || rule.type == MatchType.ASSET_FILE) {
                        val matcher = rule.pattern.toRegex()
                        if (entryNames.any { matcher.containsMatchIn(it) }) {
                            detected.add(DetectedLibrary(rule.name, rule.category, null, "File System"))
                        }
                    }
                }

                val deferreds = mutableListOf<Deferred<Unit>>()

                // B. Parallel DEX Segment Scanning
                entries.filter { it.name.endsWith(".dex") }.forEach { entry ->
                    deferreds.add(async(Dispatchers.IO) {
                        try {
                            zip.getInputStream(entry).use { stream ->
                                scanDexEfficiently(stream, detected)
                            }
                        } catch (e: Exception) {}
                    })
                }

                // C. Parallel Flutter Binary Forensics
                entries.find { it.name.contains("libapp.so") }?.let { libEntry ->
                    deferreds.add(async(Dispatchers.IO) {
                        try {
                            zip.getInputStream(libEntry).use { stream ->
                                scanFlutterPackages(stream).forEach { pkg ->
                                    detected.add(DetectedLibrary(pkg, "Flutter Package", null, "Flutter Binary"))
                                }
                            }
                        } catch (e: Exception) {}
                    })
                }
                
                // D. Parallel Version Analysis
                deferreds.add(async(Dispatchers.IO) {
                     extractFlutterVersion(zip)?.let { ver ->
                         // Upgrade existing Flutter entry if present
                         detected.removeIf { it.name == "Flutter" && it.version == null }
                         detected.add(DetectedLibrary("Flutter", "Framework", ver, "Manifest"))
                     }
                     // Keep return unit
                     Unit 
                })

                deferreds.awaitAll()
            }
        } catch (e: Exception) { }

        return@withContext detected.toList()
    }

    // --- Core Forensics Engines ---

    /**
     * Parses DEX Header to find the String Data Pool offset and jumps directly to it.
     * Skips parsing code, annotations, and definitions.
     */
    private fun scanDexEfficiently(stream: InputStream, detected: MutableSet<DetectedLibrary>) {
        val buffer = ByteArray(BUFFER_SIZE_LARGE)
        
        // 1. Read Header
        val header = ByteArray(DEX_HEADER_SIZE)
        if (stream.read(header) != DEX_HEADER_SIZE) return 
        
        val headerBuf = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN)
        val idsOff = headerBuf.getInt(STRING_IDS_OFF_OFFSET).toLong()
        // If IDs are at 112 (contiguous), we are good. If further, skip.
        val currentPos = DEX_HEADER_SIZE.toLong()
        
        if (idsOff >= currentPos) {
             safeSkip(stream, idsOff - currentPos)
             
             // 2. Read Pointer to First String
             val idBuf = ByteArray(4)
             if (stream.read(idBuf) == 4) {
                 val firstStringOff = ByteBuffer.wrap(idBuf).order(ByteOrder.LITTLE_ENDIAN).getInt().toLong()
                 
                 // 3. Jump to String Data Pool
                 // Current pos is idsOff + 4
                 val nextPos = idsOff + 4
                 if (firstStringOff > nextPos) {
                     safeSkip(stream, firstStringOff - nextPos)
                     // Successfully landed at Data Section.
                 }
             }
        }
        
        // 4. Stream Scan from Data Section
        scanWithTrie(stream, detected, buffer)
    }
    
    private fun scanWithTrie(stream: InputStream, detected: MutableSet<DetectedLibrary>, buffer: ByteArray) {
        var bytesRead: Int
        
        // Optimized Reuse: 'Swap' strategy for lists to avoid allocation churn
        var activeNodes = ArrayList<FastByteTrie.Node>(16)
        var nextActiveNodes = ArrayList<FastByteTrie.Node>(16)
        
        val rootArray = dexTrie.root
        // Thread-local seen cache to reduce Set contention
        val seenRules = HashSet<String>()

        while (stream.read(buffer).also { bytesRead = it } != -1) {
            for (i in 0 until bytesRead) {
                val b = buffer[i].toInt() and 0xFF
                
                // 1. Process Active Matches
                if (activeNodes.isNotEmpty()) {
                    val size = activeNodes.size
                    for (j in 0 until size) {
                        val node = activeNodes[j]
                        val child = node.children.get(b)
                        if (child != null) {
                            child.matchRule?.let { rule ->
                                if (seenRules.add(rule.name)) {
                                     detected.add(DetectedLibrary(rule.name, rule.category, null, "DEX Scan"))
                                }
                            }
                            if (child.children.size() > 0) {
                                nextActiveNodes.add(child)
                            }
                        }
                    }
                    // List Swap Optimization
                    val temp = activeNodes
                    activeNodes = nextActiveNodes
                    nextActiveNodes = temp
                    nextActiveNodes.clear()
                }

                // 2. Start New Matches via O(1) Root Lookup
                val child = rootArray[b]
                if (child != null) {
                    child.matchRule?.let { rule ->
                        if (seenRules.add(rule.name)) {
                             detected.add(DetectedLibrary(rule.name, rule.category, null, "DEX Scan"))
                        }
                    }
                    if (child.children.size() > 0) activeNodes.add(child)
                }
            }
        }
    }
    
    private fun safeSkip(stream: InputStream, n: Long) {
        var remaining = n
        val skipBuf = ByteArray(8192) 
        while (remaining > 0) {
            val skipped = stream.skip(remaining)
            if (skipped > 0) {
                remaining -= skipped
            } else {
                val read = stream.read(skipBuf, 0, minOf(skipBuf.size.toLong(), remaining).toInt())
                if (read == -1) break
                remaining -= read
            }
        }
    }

    /**
     * Flutter Binary Forensic Scanner.
     * Extracts "package:name/" strings from libapp.so without allocating String objects for non-matches.
     */
    private fun scanFlutterPackages(stream: InputStream): Set<String> {
        val packages = HashSet<String>()
        val buffer = ByteArray(BUFFER_SIZE_LARGE)
        var bytesRead: Int
        var matchIndex = 0
        val headerLen = flutterPackageBytes.size
        
        while (stream.read(buffer).also { bytesRead = it } != -1) {
            var i = 0
            while (i < bytesRead) {
                val b = buffer[i]
                if (b == flutterPackageBytes[matchIndex]) {
                    matchIndex++
                    if (matchIndex == headerLen) {
                        // Header Confirmed. Extract Name.
                        val sb = StringBuilder()
                         var j = i + 1
                         var isValid = false
                         // Look ahead in current buffer
                         while (j < bytesRead) {
                             val charByte = buffer[j]
                             if (charByte.toChar() == '/') {
                                 isValid = true
                                 i = j
                                 break
                             } else if (charByte < 32 || charByte > 126) {
                                 i = j; break
                             } else {
                                 sb.append(charByte.toChar())
                                 j++
                             }
                         }
                         if (isValid && sb.length > 2) {
                             val name = sb.toString()
                             if (name != "flutter" && name != "dart") packages.add(name)
                         }
                         matchIndex = 0
                    }
                } else {
                    if (matchIndex > 0) {
                        // Retry for overlapped patterns (rare for "package:")
                        matchIndex = if (b == flutterPackageBytes[0]) 1 else 0
                    }
                }
                i++
            }
        }
        return packages
    }

    private fun extractFlutterVersion(zip: ZipFile): String? {
         val abis = arrayOf("arm64-v8a", "armeabi-v7a", "x86_64")
         for (abi in abis) {
             val entry = zip.getEntry("lib/$abi/libflutter.so") ?: continue
             try {
                 zip.getInputStream(entry).use { s -> 
                     val buf = ByteArray(32 * 1024)
                     val read = s.read(buf)
                     if (read > 0) {
                         val str = String(buf, 0, read)
                         val m = FLUTTER_VER_REGEX.find(str)
                         if (m != null) return m.groupValues[1]
                     }
                 }
                 return null
             } catch(e:Exception){}
         }
         return null
    }

    private fun scanForKotlinInternal(zip: ZipFile): Boolean {
         val entries = zip.entries()
         while(entries.hasMoreElements()) {
             if (entries.nextElement().name.endsWith(".kotlin_module")) return true
         }
         return false
    }

    private fun getInstallerPackageName(packageName: String, pm: PackageManager): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                pm.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(packageName)
            }
        } catch (e: Exception) { null }
    }

    private fun getSignatures(pkg: PackageInfo, pm: PackageManager): List<ByteArray> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val signingInfo = pkg.signingInfo
                if (signingInfo != null) {
                     if (signingInfo.hasMultipleSigners()) signingInfo.apkContentsSigners.map { it.toByteArray() }
                     else signingInfo.signingCertificateHistory.map { it.toByteArray() }
                } else emptyList()
            } else {
                @Suppress("DEPRECATION")
                pkg.signatures?.map { it.toByteArray() } ?: emptyList()
            }
        } catch (e: Exception) { emptyList() }
    }

    private fun getFingerprint(signature: ByteArray, algorithm: String): String {
        return try {
            val certFactory = CertificateFactory.getInstance("X509")
            val x509Cert = certFactory.generateCertificate(ByteArrayInputStream(signature)) as X509Certificate
            val md = MessageDigest.getInstance(algorithm)
            val digest = md.digest(x509Cert.encoded)
            digest.joinToString(":") { "%02X".format(it) }
        } catch (e: Exception) { "Error" }
    }
}
