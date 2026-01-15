package com.rakhul.unfilter

import java.io.BufferedReader
import java.io.InputStreamReader

class ProcessManager {

    fun getRunningProcesses(): List<Map<String, Any?>> {
        val processes = mutableListOf<Map<String, Any?>>()
        try {
            // Try 'top' first as it gives CPU usage and more details
            // -b: Batch mode
            // -n 1: Single iteration
            val process = Runtime.getRuntime().exec("top -b -n 1")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            
            var line: String?
            var headers: List<String>? = null
            var headerIndexMap: Map<String, Int>? = null
            
            // Limit to prevent freezing in case of infinite stream
            var count = 0
            val maxProcesses = 500
            
            while (reader.readLine().also { line = it } != null && count < maxProcesses) {
                 val trimmed = line?.trim() ?: continue
                 if (trimmed.isEmpty()) continue
                 
                 // Skip meta info lines (Tasks:, Mem:, Swap:)
                 if (trimmed.startsWith("Tasks:") || 
                     trimmed.startsWith("Mem:") || 
                     trimmed.startsWith("Swap:") || 
                     trimmed.startsWith("%Cpu") ||
                     (trimmed.contains("User") && trimmed.contains("System"))) {
                     continue
                 }

                 // Detect header - more robust detection
                 if (trimmed.contains("PID") && (trimmed.contains("USER") || trimmed.contains("UID"))) {
                     headers = trimmed.split("\\s+".toRegex())
                     headerIndexMap = headers.mapIndexed { index, col -> col.uppercase() to index }.toMap()
                     continue
                 }
                 
                 if (headers != null && headerIndexMap != null) {
                     val parts = trimmed.split("\\s+".toRegex())
                     // Ensure we have enough parts to cover the essential columns
                     if (parts.size >= 5) { 
                         val map = mutableMapOf<String, Any?>()
                         
                         // Column accessor with fallbacks
                         fun getCol(vararg colNames: String): String? {
                             for (colName in colNames) {
                                 val idx = headerIndexMap!![colName.uppercase()]
                                 if (idx != null && idx < parts.size) {
                                     return parts[idx]
                                 }
                             }
                             return null
                         }

                         val pid = getCol("PID")
                         if (pid == null || pid.toIntOrNull() == null) continue // Skip invalid lines

                         map["pid"] = pid
                         map["user"] = getCol("USER", "UID") ?: "?"
                         map["cpu"] = getCol("%CPU", "CPU") ?: "0.0"
                         map["mem"] = getCol("%MEM", "MEM") ?: "0.0"
                         map["res"] = getCol("RES", "RSS") ?: "0"
                         map["vsz"] = getCol("VIRT", "VSZ") ?: "0"
                         map["s"] = getCol("S", "STATE") ?: "S"
                         
                         // Extended fields
                         map["threads"] = getCol("THR", "THREADS", "NR")?.toIntOrNull()
                         map["nice"] = getCol("NI", "NICE")?.toIntOrNull()
                         map["priority"] = getCol("PR", "PRI", "PRIO")?.toIntOrNull()
                         map["startTime"] = getCol("TIME+", "TIME", "ELAPSED")
                         
                         // Name/Args - tricky as it's usually at the end
                         // Find where command/args start
                         var nameIdx = headerIndexMap!!["ARGS"] 
                             ?: headerIndexMap!!["COMMAND"] 
                             ?: headerIndexMap!!["NAME"]
                         
                         if (nameIdx != null && nameIdx < parts.size) {
                             // Join all remaining parts as name/args
                             val fullCommand = parts.subList(nameIdx, parts.size).joinToString(" ")
                             map["name"] = fullCommand.split("/").lastOrNull()?.split(" ")?.firstOrNull() ?: fullCommand
                             map["args"] = fullCommand
                         } else {
                             // Fallback to last column
                             map["name"] = parts.last()
                             map["args"] = parts.last()
                         }

                         processes.add(map)
                         count++
                     }
                 }
            }
            
            reader.close()
            process.waitFor()
            
        } catch (e: Exception) {
            e.printStackTrace()
             // Fallback to ps if top fails or returns minimal info
             return getProcessesViaPs()
        }
        
        if (processes.isEmpty()) {
            return getProcessesViaPs()
        }
        
        return processes
    }
    
    private fun getProcessesViaPs(): List<Map<String, Any?>> {
        val processes = mutableListOf<Map<String, Any?>>()
        try {
             // ps with extended columns
             // -A: All processes
             // -o: Output format
             val columns = "PID,USER,RSS,VSZ,STAT,NI,PRI,NLWP,ELAPSED,ARGS"
             val process = Runtime.getRuntime().exec(arrayOf("ps", "-A", "-o", columns))
             val reader = BufferedReader(InputStreamReader(process.inputStream))
             var line: String?
             
             // Skip header
             reader.readLine()
             
             var count = 0
             val maxProcesses = 500
             
             while (reader.readLine().also { line = it } != null && count < maxProcesses) {
                 val trimmed = line?.trim() ?: continue
                 if (trimmed.isEmpty()) continue
                 
                 // Split with limit to preserve ARGS which may have spaces
                 val parts = trimmed.split("\\s+".toRegex(), limit = 10)
                 if (parts.size < 9) continue
                 
                 val map = mutableMapOf<String, Any?>()
                 map["pid"] = parts[0]
                 map["user"] = parts[1]
                 map["res"] = parts[2] // RSS in KB
                 map["vsz"] = parts[3]
                 map["s"] = parts.getOrNull(4)?.firstOrNull()?.toString() ?: "S"
                 map["nice"] = parts.getOrNull(5)?.toIntOrNull()
                 map["priority"] = parts.getOrNull(6)?.toIntOrNull()
                 map["threads"] = parts.getOrNull(7)?.toIntOrNull()
                 map["startTime"] = parts.getOrNull(8)
                 
                 val fullCommand = parts.getOrNull(9) ?: parts.last()
                 map["name"] = fullCommand.split("/").lastOrNull()?.split(" ")?.firstOrNull() ?: fullCommand
                 map["args"] = fullCommand
                 
                 // ps doesn't directly give CPU percentage
                 map["cpu"] = "0.0"
                 map["mem"] = "0.0"
                 
                 processes.add(map)
                 count++
             }
             
             reader.close()
             process.waitFor()
             
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return processes
    }
}
