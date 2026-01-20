package com.rakhul.unfilter

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.Callable
import java.util.concurrent.atomic.AtomicInteger
import java.util.stream.Collectors

class AppRepository(private val context: Context) {

    private val packageManager: PackageManager = context.packageManager
    private val stackDetector = StackDetector()
    private val usageManager = UsageManager(context)

    private val deepAnalyzer = DeepAnalyzer(context)
    
    private val scanExecutor = Executors.newFixedThreadPool(4)

    fun getInstalledApps(
        includeDetails: Boolean,
        onProgress: (current: Int, total: Int, currentApp: String) -> Unit,
        checkScanCancelled: () -> Boolean
    ): List<Map<String, Any?>> {
        var flags = 0
        if (includeDetails) {
            flags = PackageManager.GET_META_DATA or
                    PackageManager.GET_PERMISSIONS or
                    PackageManager.GET_SERVICES or
                    PackageManager.GET_RECEIVERS or
                    PackageManager.GET_PROVIDERS or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES)
        }

        val packages = packageManager.getInstalledPackages(flags)
        
        val launchIntent = android.content.Intent(android.content.Intent.ACTION_MAIN, null)
        launchIntent.addCategory(android.content.Intent.CATEGORY_LAUNCHER)
        val launchables = packageManager.queryIntentActivities(launchIntent, 0)
        val launchablePackages = launchables.map { it.activityInfo.packageName }.toSet()

        val total = packages.size
        val usageMap = if (includeDetails) usageManager.getUsageMap() else emptyMap()

        if (includeDetails) {
             val counter = AtomicInteger(0)
             val futures = mutableListOf<Future<Map<String, Any?>?>>()
             
             for (pkg in packages) {
                 if (checkScanCancelled()) break
                 
                 futures.add(scanExecutor.submit(Callable {
                     if (checkScanCancelled()) return@Callable null
                     
                     val index = counter.incrementAndGet()
                     val packageName = pkg.packageName
                     
                     if (index % 10 == 0) {
                         onProgress(index, total, packageName)
                     }

                     val appInfo = pkg.applicationInfo ?: return@Callable null
                     val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                     val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                     val shouldInclude = launchablePackages.contains(packageName) || (!isSystem || isUpdatedSystem)

                     if (shouldInclude) {
                         try {
                             convertPackageToMap(pkg, true, usageMap)
                         } catch (e: Exception) { null }
                     } else {
                         null
                     }
                 }))
             }

             val results = mutableListOf<Map<String, Any?>>()
             for (future in futures) {
                 try {
                     val result = future.get()
                     if (result != null) results.add(result)
                 } catch (e: Exception) {
                 }
             }
             return results
        } else {
            val appList = mutableListOf<Map<String, Any?>>()
            for ((index, pkg) in packages.withIndex()) {
                if (checkScanCancelled()) break

                val packageName = pkg.packageName

                if (includeDetails && index % 10 == 0) {
                     onProgress(index + 1, total, packageName)
                }

                val appInfo = pkg.applicationInfo ?: continue
                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                val shouldInclude = launchablePackages.contains(packageName) || (!isSystem || isUpdatedSystem)

                if (shouldInclude) {
                    try {
                        appList.add(convertPackageToMap(pkg, includeDetails, usageMap))
                    } catch (e: Exception) { }
                }
            }
            return appList
        }
    }

    fun getAppsDetails(packageNames: List<String>): List<Map<String, Any?>> {
        val usageMap = usageManager.getUsageMap()
        val flags = PackageManager.GET_META_DATA or
                PackageManager.GET_PERMISSIONS or
                PackageManager.GET_SERVICES or
                PackageManager.GET_RECEIVERS or
                PackageManager.GET_PROVIDERS or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES)

        val futures = mutableListOf<Future<Map<String, Any?>?>>()
        
        for (name in packageNames) {
            futures.add(scanExecutor.submit(Callable {
                try {
                    val pkg = packageManager.getPackageInfo(name, flags)
                    if (pkg.applicationInfo != null) {
                        convertPackageToMap(pkg, true, usageMap)
                    } else null
                } catch (e: Exception) { null }
            }))
        }

        val results = mutableListOf<Map<String, Any?>>()
        for (future in futures) {
            try {
                val result = future.get()
                if (result != null) results.add(result)
            } catch (e: Exception) { }
        }
        return results
    }


    private fun convertPackageToMap(
        pkg: PackageInfo,
        includeDetails: Boolean,
        usageMap: Map<String, android.app.usage.UsageStats>?
    ): Map<String, Any?> {
        val appInfo = pkg.applicationInfo!!

        var stack = "Unknown"
        var libs = emptyList<String>()
        var iconBytes = ByteArray(0)
        var usage: android.app.usage.UsageStats? = null
        var deepData: Map<String, Any?> = emptyMap()
        
        var permissions = emptyList<String>()
        var services = emptyList<String>()
        var receivers = emptyList<String>()
        var providers = emptyList<String>()

        if (includeDetails) {
            val sourceDir = appInfo.sourceDir
            var zipFile: java.util.zip.ZipFile? = null
            try {
                if (sourceDir != null && File(sourceDir).exists()) {
                    zipFile = java.util.zip.ZipFile(File(sourceDir))
                }
            } catch (e: Exception) { 
            }

            try {
                val pair = stackDetector.detectStackAndLibs(appInfo, zipFile)
                stack = pair.first
                libs = pair.second

                usage = usageMap?.get(pkg.packageName)
                deepData = deepAnalyzer.analyze(pkg, packageManager, zipFile)

                try {
                    val iconDrawable = packageManager.getApplicationIcon(appInfo)
                    iconBytes = drawableToByteArray(iconDrawable)
                } catch (e: Exception) { }
                
                permissions = pkg.requestedPermissions?.toList() ?: emptyList()
                services = pkg.services?.map { it.name } ?: emptyList()
                receivers = pkg.receivers?.map { it.name } ?: emptyList()
                providers = pkg.providers?.map { it.name } ?: emptyList()
            } finally {
                try {
                    zipFile?.close()
                } catch (e: Exception) { }
            }
        }

        val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

        var appSize = 0L
        var dataSize = 0L
        var cacheSize = 0L
        var externalCacheSize = 0L

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val storageStatsManager = context.getSystemService(Context.STORAGE_STATS_SERVICE) as android.app.usage.StorageStatsManager
                val uuid = android.os.storage.StorageManager.UUID_DEFAULT
                val stats = storageStatsManager.queryStatsForPackage(
                    uuid, 
                    pkg.packageName, 
                    android.os.Process.myUserHandle()
                )
                
                appSize = stats.appBytes
                dataSize = stats.dataBytes
                cacheSize = stats.cacheBytes
                externalCacheSize = stats.externalCacheBytes
            } catch (e: Exception) {
                if (appInfo.sourceDir != null) appSize = File(appInfo.sourceDir).length()
            }
        } else {
             if (appInfo.sourceDir != null) appSize = File(appInfo.sourceDir).length()
        }

        val totalSize = appSize + dataSize + cacheSize

        val map = mutableMapOf<String, Any?>(
            "appName" to (if (includeDetails) packageManager.getApplicationLabel(appInfo).toString() else pkg.packageName),
            "packageName" to pkg.packageName,
            "version" to (pkg.versionName ?: "Unknown"),
            "icon" to iconBytes,
            "versionCode" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pkg.longVersionCode else pkg.versionCode.toLong()),
            "stack" to stack,
            "nativeLibraries" to libs,
            "isSystem" to isSystem,
            "firstInstallTime" to pkg.firstInstallTime,
            "lastUpdateTime" to pkg.lastUpdateTime,
            "minSdkVersion" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) appInfo.minSdkVersion else 0),
            "targetSdkVersion" to appInfo.targetSdkVersion,
            "uid" to appInfo.uid,
            "permissions" to permissions,
            "services" to services,
            "receivers" to receivers,
            "providers" to providers,
            "totalTimeInForeground" to (usage?.totalTimeInForeground ?: 0),
            "lastTimeUsed" to (usage?.lastTimeUsed ?: 0),
            "category" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                when (appInfo.category) {
                    ApplicationInfo.CATEGORY_GAME -> "game"
                    ApplicationInfo.CATEGORY_AUDIO -> "audio"
                    ApplicationInfo.CATEGORY_VIDEO -> "video"
                    ApplicationInfo.CATEGORY_IMAGE -> "image"
                    ApplicationInfo.CATEGORY_SOCIAL -> "social"
                    ApplicationInfo.CATEGORY_NEWS -> "news"
                    ApplicationInfo.CATEGORY_MAPS -> "maps"
                    ApplicationInfo.CATEGORY_PRODUCTIVITY -> "productivity"
                    -1 -> "unknown"
                    else -> "tools"
                }
            } else "unknown"),
            "size" to totalSize,
            "appSize" to appSize,
            "dataSize" to dataSize,
            "cacheSize" to cacheSize,
            "externalCacheSize" to externalCacheSize,
            "apkPath" to (appInfo.sourceDir ?: ""),
            "dataDir" to (appInfo.dataDir ?: "")
        )
        
        map.putAll(deepData)
        
        return map
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        var bitmap: Bitmap? = null
        var scaledBitmap: Bitmap? = null
        try {
            if (drawable is BitmapDrawable) {
                bitmap = drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
            
            if (bitmap == null) return ByteArray(0)

            scaledBitmap = Bitmap.createScaledBitmap(bitmap, 96, 96, true)

            val stream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            return stream.toByteArray()
        } catch (e: Exception) {
            return ByteArray(0)
        } finally {
            try {
                if (scaledBitmap != null && scaledBitmap != bitmap) {
                    scaledBitmap.recycle()
                }
                if (bitmap != null && drawable !is BitmapDrawable) {
                    bitmap.recycle()
                }
            } catch (e: Exception) {
            }
        }
    }

    fun shutdown() {
        try {
            scanExecutor.shutdownNow()
        } catch (e: Exception) {
        }
    }
}
