package com.rakhul.unfilter

import android.util.Log
import java.io.BufferedReader
import java.io.InputStreamReader

class ProcessManager {
    companion object {
        private const val TAG = "ProcessManager"
    }

    fun getRunningProcesses(): List<Map<String, Any?>> {
        val processes = mutableListOf<Map<String, Any?>>()
        try {
            // Run top with 2 iterations (-n 2) and 1 second delay (-d 1)
            // The first iteration has no baseline for CPU calculation (shows 0%),
            // so we discard it and only keep the second iteration's accurate data.
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", "top -b -n 2 -d 1"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            

            
            var line: String?
            var headers: List<String>? = null
            var headerIndexMap = mutableMapOf<String, Int>()
            
            var count = 0
            val maxProcesses = 400
            
            while (reader.readLine().also { line = it } != null) {
                val trimmed = line?.trim() ?: continue
                if (trimmed.isEmpty()) continue
                
                // Skip metadata lines
                if (trimmed.startsWith("Tasks:") || trimmed.startsWith("Mem:") || 
                    trimmed.startsWith("Swap:") || trimmed.startsWith("User") || trimmed.contains("System")) {
                    continue
                }

                // Detect Header - this marks start of a new iteration
                if (trimmed.contains("PID") && (trimmed.contains("USER") || trimmed.contains("CPU"))) {
                    headers = trimmed.split("\\s+".toRegex())
                    headerIndexMap.clear()
                    var hasMergedCpuColumn = false
                    headers.forEachIndexed { index, col -> 
                        // Normalize column name: S[%CPU] -> CPU, %MEM -> MEM, etc.
                        var normalized = col.uppercase()
                            .replace("%", "")
                            .replace("[", "")
                            .replace("]", "")
                        // Handle merged columns like "SCPU" -> extract CPU
                        // Also detect if this is a merged S+CPU column (data will have them separate)
                        if (normalized.length > 3 && normalized.endsWith("CPU")) {
                            if (normalized.startsWith("S")) {
                                hasMergedCpuColumn = true
                            }
                            normalized = "CPU"
                        }
                        if (normalized.length > 3 && normalized.endsWith("MEM")) {
                            normalized = "MEM"
                        }
                        headerIndexMap[normalized] = index 
                    }
                    // Store whether we have a merged CPU column (need offset when parsing data)
                    headerIndexMap["_HAS_MERGED_CPU"] = if (hasMergedCpuColumn) 1 else 0

                    // Clear previous iteration data - we only want the last (most accurate) iteration
                    processes.clear()
                    count = 0
                    continue
                }

                // Parse Process Line (limit to maxProcesses per iteration)
                if (headerIndexMap.isNotEmpty() && count < maxProcesses) {
                    val parts = trimmed.split("\\s+".toRegex())
                    // Need at least PID, user, CPU, mem
                    if (parts.size >= headerIndexMap.size - 2) {
                        try {
                            // Check if we need to apply offset for merged S[CPU] header
                            val hasMergedCpu = (headerIndexMap["_HAS_MERGED_CPU"] as? Int) == 1
                            val cpuOffset = if (hasMergedCpu) 1 else 0
                            
                            // Find indices
                            val pidIdx = headerIndexMap["PID"]
                            val userIdx = headerIndexMap["USER"] ?: headerIndexMap["UID"]
                            // CPU and subsequent columns need offset if header had merged S[CPU]
                            val cpuIdx = headerIndexMap["CPU"]?.let { it + cpuOffset }
                            val memIdx = headerIndexMap["MEM"]?.let { it + cpuOffset }
                            val resIdx = (headerIndexMap["RES"] ?: headerIndexMap["RSS"])
                            val thrIdx = headerIndexMap["THR"] ?: headerIndexMap["S"] // Fallback
                            val nameIdx = (headerIndexMap["ARGS"] ?: headerIndexMap["NAME"] ?: headerIndexMap["COMMAND"])?.let { it + cpuOffset } ?: (parts.size - 1)
                            
                            if (pidIdx != null && pidIdx < parts.size) {
                                val pidStr = parts[pidIdx]
                                if (pidStr.toIntOrNull() == null) continue

                                val map = mutableMapOf<String, Any?>()
                                map["pid"] = pidStr
                                map["user"] = if (userIdx != null && userIdx < parts.size) parts[userIdx] else "?"
                                
                                // Parse CPU - strip %
                                var cpuStr = if (cpuIdx != null && cpuIdx < parts.size) parts[cpuIdx] else "0.0"
                                cpuStr = cpuStr.replace("%", "")
                                map["cpu"] = cpuStr
                                


                                // Parse MEM - strip %
                                var memStr = if (memIdx != null && memIdx < parts.size) parts[memIdx] else "0.0"
                                memStr = memStr.replace("%", "")
                                map["mem"] = memStr
                                
                                map["res"] = if (resIdx != null && resIdx < parts.size) parts[resIdx] else "0"
                                map["threads"] = if (thrIdx != null && thrIdx < parts.size) parts[thrIdx].toIntOrNull() else null
                                
                                // Name might be the last part(s)
                                val namePart = if (nameIdx < parts.size) {
                                    parts.subList(nameIdx, parts.size).joinToString(" ")
                                } else {
                                    parts.last()
                                }
                                map["name"] = namePart.split("/").last().split(" ").first()
                                map["args"] = namePart
                                
                                processes.add(map)
                                count++
                            }
                        } catch (e: Exception) {
                            // Ignore parsing errors for single lines
                        }
                    }
                }
            }
            reader.close()
            process.waitFor()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error running top", e)
        }
        
        // Fallback to simple ps if top failed completely
        if (processes.isEmpty()) {
             Log.d(TAG, "top returned 0 processes, falling back to ps")
             return getProcessesViaPs()
        }

        // Sort by CPU usage
        val sorted = processes.sortedByDescending { 
            (it["cpu"] as? String)?.toDoubleOrNull() ?: 0.0 
        }
        
        // Debug summary
        val maxCpu = sorted.firstOrNull()?.let { (it["cpu"] as? String)?.toDoubleOrNull() } ?: 0.0
        Log.d(TAG, "Returning ${sorted.size} processes, max CPU: $maxCpu")
        
        return sorted
    }

    private fun getProcessesViaPs(): List<Map<String, Any?>> {
         val processes = mutableListOf<Map<String, Any?>>()
         try {
             // ps -A -o PID,USER,RSS,VSZ,NAME
             val process = Runtime.getRuntime().exec(arrayOf("ps", "-A", "-o", "PID,USER,RSS,VSZ,NAME"))
             val reader = BufferedReader(InputStreamReader(process.inputStream))
             reader.readLine() // skip header
             var line: String?
             while (reader.readLine().also { line = it } != null) {
                 val parts = line?.trim()?.split("\\s+".toRegex()) ?: continue
                 if (parts.size < 5) continue
                 val map = mutableMapOf<String, Any?>()
                 map["pid"] = parts[0]
                 map["user"] = parts[1]
                 map["res"] = parts[2]
                 map["name"] = parts.last()
                 map["cpu"] = "0.0" // PS doesn't support CPU on all devices
                 map["mem"] = "0.0"
                 processes.add(map)
             }
             reader.close()
         } catch (e: Exception) {}
         return processes
    }
}
