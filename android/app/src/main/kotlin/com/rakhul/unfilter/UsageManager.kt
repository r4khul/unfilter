package com.rakhul.unfilter

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import java.io.ByteArrayOutputStream
import java.util.Calendar

class UsageManager(private val context: Context) {

    private val packageManager: PackageManager = context.packageManager

    fun hasPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun getUsageMap(): Map<String, android.app.usage.UsageStats> {
        if (!hasPermission()) return emptyMap()
        
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.YEAR, -2)
        val startTime = calendar.timeInMillis
        
        return usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
    }

    
    fun getRecentlyActiveApps(hoursAgo: Int = 24): List<Map<String, Any?>> {
        if (!hasPermission()) return emptyList()
        
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.HOUR_OF_DAY, -hoursAgo)
        val startTime = calendar.timeInMillis
        
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        val packageUsageMap = mutableMapOf<String, android.app.usage.UsageStats>()
        for (stats in usageStats) {
            val existing = packageUsageMap[stats.packageName]
            if (existing == null || stats.lastTimeUsed > existing.lastTimeUsed) {
                packageUsageMap[stats.packageName] = stats
            }
        }
        
        val recentApps = packageUsageMap.values
            .filter { it.lastTimeUsed > startTime && it.totalTimeInForeground > 0 }
            .sortedByDescending { it.lastTimeUsed }
            .take(50)
        
        return recentApps.mapNotNull { stats ->
            try {
                val appInfo = packageManager.getApplicationInfo(stats.packageName, 0)
                
                val launchIntent = packageManager.getLaunchIntentForPackage(stats.packageName)
                if (launchIntent == null && (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
                    return@mapNotNull null
                }
                
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val icon = try {
                    val drawable = packageManager.getApplicationIcon(appInfo)
                    drawableToByteArray(drawable)
                } catch (e: Exception) {
                    ByteArray(0)
                }
                
                mapOf(
                    "packageName" to stats.packageName,
                    "appName" to appName,
                    "icon" to icon,
                    "lastTimeUsed" to stats.lastTimeUsed,
                    "totalTimeInForeground" to stats.totalTimeInForeground
                )
            } catch (e: PackageManager.NameNotFoundException) {
                null
            } catch (e: Exception) {
                null
            }
        }
    }
    
    private fun drawableToByteArray(drawable: android.graphics.drawable.Drawable): ByteArray {
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
            
            scaledBitmap = Bitmap.createScaledBitmap(bitmap, 72, 72, true)
            val stream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
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
            } catch (e: Exception) {}
        }
    }

    fun getAppUsageHistory(packageName: String, installTime: Long? = null): List<Map<String, Any>> {
        if (!hasPermission()) return emptyList()

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        
        val startTime = if (installTime != null && installTime > 0) {
            installTime
        } else {
            calendar.add(Calendar.YEAR, -2)
            calendar.timeInMillis
        }

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val dailyUsage = mutableMapOf<Long, Long>()

        for (stats in usageStatsList) {
            if (stats.packageName == packageName) {
                val cal = Calendar.getInstance()
                cal.timeInMillis = stats.firstTimeStamp
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
                val dayStart = cal.timeInMillis

                dailyUsage[dayStart] = (dailyUsage[dayStart] ?: 0L) + stats.totalTimeInForeground
            }
        }

        val result = mutableListOf<Map<String, Any>>()
        val todayCal = Calendar.getInstance()
        
        val daysSinceStart = ((endTime - startTime) / (24 * 60 * 60 * 1000)).toInt().coerceIn(1, 730)

        for (i in 0 until daysSinceStart) {
            val dateCal = Calendar.getInstance()
            dateCal.timeInMillis = todayCal.timeInMillis
            dateCal.add(Calendar.DAY_OF_YEAR, -i)
            dateCal.set(Calendar.HOUR_OF_DAY, 0)
            dateCal.set(Calendar.MINUTE, 0)
            dateCal.set(Calendar.SECOND, 0)
            dateCal.set(Calendar.MILLISECOND, 0)
            val dayStart = dateCal.timeInMillis

            result.add(mapOf(
                "date" to dayStart,
                "usage" to (dailyUsage[dayStart] ?: 0L)
            ))
        }

        return result.reversed()
    }
}

