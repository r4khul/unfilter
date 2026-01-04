package com.rakhul.unfilter

import java.io.BufferedReader
import java.io.InputStreamReader

class ProcessManager {

    fun getRunningProcesses(): List<Map<String, String>> {
        val processes = mutableListOf<Map<String, String>>()
        try {
            // Try 'top' first as it gives CPU usage
            // -b: Batch mode
            // -n 1: Single iteration
            val process = Runtime.getRuntime().exec("top -b -n 1")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            
            var line: String?
            var headers: List<String>? = null
            
            // Limit to prevent freezing in case of infinite stream
            var count = 0
            while (reader.readLine().also { line = it } != null && count < 500) {
                 val trimmed = line?.trim() ?: continue
                 if (trimmed.isEmpty()) continue
                 
                 // Skip meta info lines (Tasks:, Mem:, Swap:)
                 if (trimmed.startsWith("Tasks:") || trimmed.startsWith("Mem:") || trimmed.startsWith("Swap:") || trimmed.contains("User") && trimmed.contains("System")) {
                     continue
                 }

                 // Detect header
                 // Typical header: PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ ARGS
                 if (trimmed.contains("PID") && trimmed.contains("USER")) {
                     headers = trimmed.split("\\s+".toRegex())
                     continue
                 }
                 
                 if (headers != null) {
                     val parts = trimmed.split("\\s+".toRegex())
                     // Ensure we have enough parts to cover the essential columns
                     if (parts.size >= 5) { 
                         val map = mutableMapOf<String, String>()
                         
                         // Dynamic column mapping
                         fun getCol(colName: String, altName: String = ""): String {
                             var idx = headers!!.indexOf(colName)
                             if (idx == -1 && altName.isNotEmpty()) idx = headers!!.indexOfFirst { it.contains(altName) }
                             if (idx != -1 && idx < parts.size) return parts[idx]
                             return "?"
                         }

                         val pid = getCol("PID")
                         if (pid == "?" || pid.toIntOrNull() == null) continue // Skip invalid lines

                         map["pid"] = pid
                         map["user"] = getCol("USER")
                         map["cpu"] = getCol("CPU", "%CPU")
                         map["mem"] = getCol("MEM", "%MEM")
                         map["res"] = getCol("RES", "RSS")
                         
                         // Name is tricky. 'top' puts it at the end.
                         // ARGS/NAME column index
                         var nameIdx = headers!!.indexOf("ARGS")
                         if (nameIdx == -1) nameIdx = headers!!.indexOf("NAME")
                         if (nameIdx == -1) nameIdx = headers!!.indexOf("COMMAND")
                         
                         if (nameIdx != -1 && nameIdx < parts.size) {
                             // Join all remaining parts as name/args
                             map["name"] = parts.subList(nameIdx, parts.size).joinToString(" ")
                         } else {
                             // Fallback to last column
                             map["name"] = parts.last()
                         }

                         processes.add(map)
                         count++
                     }
                 }
            }
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
    
    private fun getProcessesViaPs(): List<Map<String, String>> {
        val processes = mutableListOf<Map<String, String>>()
        try {
             // ps -A -o PID,USER,RSS,VSZ,NAME
             val process = Runtime.getRuntime().exec(arrayOf("ps", "-A", "-o", "PID,USER,RSS,VSZ,NAME"))
             val reader = BufferedReader(InputStreamReader(process.inputStream))
             var line: String?
             reader.readLine() // Skip header: PID USER RSS VSZ NAME
             
             while (reader.readLine().also { line = it } != null) {
                 val parts = line?.trim()?.split("\\s+".toRegex()) ?: continue
                 if (parts.size < 5) continue
                 
                 val map = mutableMapOf<String, String>()
                 map["pid"] = parts[0]
                 map["user"] = parts[1]
                 map["res"] = parts[2] // RSSInK
                 map["vsz"] = parts[3]
                 map["name"] = parts[4]
                 map["cpu"] = "0.0" // ps doesn't give CPU usually
                 map["mem"] = "0.0"
                 
                 processes.add(map)
             }
             process.waitFor()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return processes
    }
}
