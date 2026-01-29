package com.rakhul.unfilter

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import java.io.File
import java.io.BufferedReader
import java.io.FileReader

class SystemDetailReader(private val context: Context) {

    fun getMemInfo(): Map<String, Long> {
        val info = mutableMapOf<String, Long>()
        try {
            File("/proc/meminfo").forEachLine { line ->
                val parts = line.split("\\s+".toRegex())
                if (parts.size >= 2) {
                    val key = parts[0].replace(":", "")
                    val value = parts[1].toLongOrNull() ?: 0L
                    info[key] = value
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return info
    }

    fun getCpuTemp(): Double {
        var maxTemp = 0.0
        
        // Expanded search for thermal zones
        for (i in 0..20) {
            val path = "/sys/class/thermal/thermal_zone$i"
            try {
                val dir = File(path)
                if (dir.exists() && dir.isDirectory) {
                    val typeFile = File(dir, "type")
                    val tempFile = File(dir, "temp")
                    
                    if (tempFile.exists() && tempFile.canRead()) {
                        val type = if (typeFile.exists() && typeFile.canRead()) {
                            typeFile.readText().trim().lowercase()
                        } else {
                            ""
                        }
                        
                        // Skip battery thermal zones in this pass
                        if (type.contains("batt") || type.contains("battery") || type.contains("chg")) {
                            continue
                        }

                        val tempStr = tempFile.readText().trim()
                        val rawTemp = tempStr.toDoubleOrNull()
                        
                        if (rawTemp != null && rawTemp > 0) {
                            val normalized = if (rawTemp > 1000) rawTemp / 1000.0 else rawTemp
                            
                            // High priority types
                            if (type.contains("cpu") || 
                                type.contains("soc") || 
                                type.contains("processor") ||
                                type.contains("ap_therm") ||
                                type.contains("mtk_ts_cpu")) {
                                return normalized
                            }
                            
                            // Keep track of the highest non-battery temp as fallback
                            if (normalized > maxTemp) {
                                maxTemp = normalized
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore permissions/IO errors for specific zones
            }
        }
        
        // If we still found nothing, fallback to battery temperature
        if (maxTemp <= 0) {
            return getBatteryTemp()
        }
        
        return maxTemp
    }

    private fun getBatteryTemp(): Double {
        try {
            val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val tempInt = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
            // Battery temp is usually in deci-digits (e.g. 300 for 30.0C)
            return tempInt / 10.0
        } catch (e: Exception) {
            return 0.0
        }
    }

    fun getGpuUsage(): String {
        val paths = listOf(
            "/sys/class/kgsl/kgsl-3d0/gpu_busy_percentage",
            "/sys/class/kgsl/kgsl-3d0/gpubusy",
            "/sys/kernel/gpu/gpu_busy",
            "/sys/module/mali/parameters/gpu_utilization",
            "/sys/devices/platform/gpusysfs/gpu_busy_level"
        )

        for (path in paths) {
            try {
                val file = File(path)
                if (file.exists() && file.canRead()) {
                    val content = file.readText().trim()
                    return content
                }
            } catch (e: Exception) {
                continue
            }
        }
        return "N/A"
    }

    fun getKernelVersion(): String {
        try {
            val version = System.getProperty("os.version")
            if (!version.isNullOrBlank() && version != "?") {
                return "Linux $version"
            }
        } catch (_: Exception) {}
        
        try {
            val file = File("/proc/version")
            if (file.exists() && file.canRead()) {
                file.readLines().firstOrNull()?.let {
                    return it.split(" ").take(3).joinToString(" ")
                }
            }
        } catch (_: Exception) {
        }
        
        return "Linux ${android.os.Build.VERSION.RELEASE}"
    }

    fun getCpuCoreCount(): Int {
        return Runtime.getRuntime().availableProcessors()
    }
}
