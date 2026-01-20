package com.rakhul.unfilter


data class StorageBreakdown(
    
    
    val apkSize: Long = 0L,
    
    
    val codeSize: Long = 0L,
    
    
    val appDataInternal: Long = 0L,
    
    
    val cacheInternal: Long = 0L,
    
    
    val cacheExternal: Long = 0L,
    
    
    val obbSize: Long = 0L,
    
    
    val externalDataSize: Long = 0L,
    
    
    val mediaSize: Long = 0L,
    
    
    val databasesSize: Long = 0L,
    
    
    val logsSize: Long = 0L,
    
    
    val residualSize: Long = 0L,
    
    
    val mediaBreakdown: MediaBreakdown = MediaBreakdown(),
    
    
    val databaseBreakdown: Map<String, Long> = emptyMap(),
    
    
    val totalExact: Long = 0L,
    
    
    val totalEstimated: Long = 0L,
    
    
    val totalCombined: Long = 0L,
    
    
    val scanTimestamp: Long = System.currentTimeMillis(),
    
    
    val confidenceLevel: Float = 0.0f,
    
    
    val limitations: List<String> = emptyList(),
    
    
    val packageName: String = ""
) {
    
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "packageName" to packageName,
            "apkSize" to apkSize,
            "codeSize" to codeSize,
            "appDataInternal" to appDataInternal,
            "cacheInternal" to cacheInternal,
            "cacheExternal" to cacheExternal,
            "obbSize" to obbSize,
            "externalDataSize" to externalDataSize,
            "mediaSize" to mediaSize,
            "databasesSize" to databasesSize,
            "logsSize" to logsSize,
            "residualSize" to residualSize,
            "mediaBreakdown" to mediaBreakdown.toMap(),
            "databaseBreakdown" to databaseBreakdown,
            "totalExact" to totalExact,
            "totalEstimated" to totalEstimated,
            "totalCombined" to totalCombined,
            "scanTimestamp" to scanTimestamp,
            "confidenceLevel" to confidenceLevel,
            "limitations" to limitations
        )
    }
    
    companion object {
        
        fun minimal(packageName: String, basicSize: Long): StorageBreakdown {
            return StorageBreakdown(
                packageName = packageName,
                apkSize = basicSize,
                totalExact = basicSize,
                totalCombined = basicSize,
                confidenceLevel = 0.3f,
                limitations = listOf("Unable to perform detailed analysis")
            )
        }
    }
}


data class MediaBreakdown(
    val images: Long = 0L,
    val videos: Long = 0L,
    val audio: Long = 0L,
    val documents: Long = 0L
) {
    fun toMap(): Map<String, Long> {
        return mapOf(
            "images" to images,
            "videos" to videos,
            "audio" to audio,
            "documents" to documents
        )
    }
    
    val total: Long
        get() = images + videos + audio + documents
}


data class CachedBreakdown(
    val breakdown: StorageBreakdown,
    val cachedAt: Long = System.currentTimeMillis()
) {
    companion object {
        const val CACHE_VALIDITY_MS = 5 * 60 * 1000L
    }
    
    fun isValid(): Boolean {
        return (System.currentTimeMillis() - cachedAt) < CACHE_VALIDITY_MS
    }
}
