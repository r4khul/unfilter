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
                
                if (trimmed.startsWith("Tasks:") || trimmed.startsWith("Mem:") || 
                    trimmed.startsWith("Swap:") || trimmed.startsWith("User") || trimmed.contains("System")) {
                    continue
                }

                if (trimmed.contains("PID") && (trimmed.contains("USER") || trimmed.contains("CPU"))) {
                    headers = trimmed.split("\\s+".toRegex())
                    headerIndexMap.clear()
                    var hasMergedCpuColumn = false
                    headers.forEachIndexed { index, col -> 
                        var normalized = col.uppercase()
                            .replace("%", "")
                            .replace("[", "")
                            .replace("]", "")
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
                    headerIndexMap["_HAS_MERGED_CPU"] = if (hasMergedCpuColumn) 1 else 0

                    processes.clear()
                    count = 0
                    continue
                }

                if (headerIndexMap.isNotEmpty() && count < maxProcesses) {
                    val parts = trimmed.split("\\s+".toRegex())
                    if (parts.size >= headerIndexMap.size - 2) {
                        try {
                            val hasMergedCpu = (headerIndexMap["_HAS_MERGED_CPU"] as? Int) == 1
                            val cpuOffset = if (hasMergedCpu) 1 else 0
                            
                            val pidIdx = headerIndexMap["PID"]
                            val userIdx = headerIndexMap["USER"] ?: headerIndexMap["UID"]
                            val cpuIdx = headerIndexMap["CPU"]?.let { it + cpuOffset }
                            val memIdx = headerIndexMap["MEM"]?.let { it + cpuOffset }
                            val resIdx = (headerIndexMap["RES"] ?: headerIndexMap["RSS"])
                            val thrIdx = headerIndexMap["THR"] ?: headerIndexMap["S"]
                            val nameIdx = (headerIndexMap["ARGS"] ?: headerIndexMap["NAME"] ?: headerIndexMap["COMMAND"])?.let { it + cpuOffset } ?: (parts.size - 1)
                            
                            if (pidIdx != null && pidIdx < parts.size) {
                                val pidStr = parts[pidIdx]
                                if (pidStr.toIntOrNull() == null) continue

                                val map = mutableMapOf<String, Any?>()
                                map["pid"] = pidStr
                                map["user"] = if (userIdx != null && userIdx < parts.size) parts[userIdx] else "?"
                                
                                var cpuStr = if (cpuIdx != null && cpuIdx < parts.size) parts[cpuIdx] else "0.0"
                                cpuStr = cpuStr.replace("%", "")
                                map["cpu"] = cpuStr
                                

                                var memStr = if (memIdx != null && memIdx < parts.size) parts[memIdx] else "0.0"
                                memStr = memStr.replace("%", "")
                                map["mem"] = memStr
                                
                                map["res"] = if (resIdx != null && resIdx < parts.size) parts[resIdx] else "0"
                                map["threads"] = if (thrIdx != null && thrIdx < parts.size) parts[thrIdx].toIntOrNull() else null
                                
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
                        }
                    }
                }
            }
            reader.close()
            process.waitFor()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error running top", e)
        }
        
        if (processes.isEmpty()) {
             Log.d(TAG, "top returned 0 processes, falling back to ps")
             return getProcessesViaPs()
        }

        val sorted = processes.sortedByDescending { 
            (it["cpu"] as? String)?.toDoubleOrNull() ?: 0.0 
        }
        
        val maxCpu = sorted.firstOrNull()?.let { (it["cpu"] as? String)?.toDoubleOrNull() } ?: 0.0
        Log.d(TAG, "Returning ${sorted.size} processes, max CPU: $maxCpu")
        
        return sorted
    }

    private fun getProcessesViaPs(): List<Map<String, Any?>> {
         val processes = mutableListOf<Map<String, Any?>>()
         try {
             val process = Runtime.getRuntime().exec(arrayOf("ps", "-A", "-o", "PID,USER,RSS,VSZ,NAME"))
             val reader = BufferedReader(InputStreamReader(process.inputStream))
             reader.readLine()
             var line: String?
             while (reader.readLine().also { line = it } != null) {
                 val parts = line?.trim()?.split("\\s+".toRegex()) ?: continue
                 if (parts.size < 5) continue
                 val map = mutableMapOf<String, Any?>()
                 map["pid"] = parts[0]
                 map["user"] = parts[1]
                 map["res"] = parts[2]
                 map["name"] = parts.last()
                 map["cpu"] = "0.0"
                 map["mem"] = "0.0"
                 processes.add(map)
             }
             reader.close()
         } catch (e: Exception) {}
         return processes
    }
}
