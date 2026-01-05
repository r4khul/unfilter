package com.rakhul.unfilter

import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Phaser
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Result of directory scan with categorized sizes.
 */
data class ScanResult(
    val totalSize: Long = 0L,
    val databasesSize: Long = 0L,
    val logsSize: Long = 0L,
    val mediaSize: Long = 0L,
    val imagesSize: Long = 0L,
    val videosSize: Long = 0L,
    val audioSize: Long = 0L,
    val documentsSize: Long = 0L,
    val residualSize: Long = 0L,
    val databaseBreakdown: Map<String, Long> = emptyMap(),
    val filesScanned: Int = 0,
    val limitReached: Boolean = false
)

/**
 * Safe, bounded, and concurrent directory scanner with depth limits and cancellation support.
 * Optimized for speed by using a work-stealing thread pool to parallelize I/O operations.
 * Designed to prevent ANRs, OOMs, and excessive I/O.
 */
class DirectoryScanner {

    internal data class ScanTask(val dir: File, val depth: Int)

    companion object {
        // Safety limits
        private const val MAX_TRAVERSAL_DEPTH = 5
        private const val MAX_FILES_TO_SCAN = 5000
        private const val MAX_FILE_SIZE_TO_CATEGORIZE = 100 * 1024 * 1024L // 100 MB

        // File extensions for categorization
        private val DATABASE_EXTENSIONS = setOf("db", "sqlite", "sqlite3", "realm", "db-shm", "db-wal")
        private val LOG_EXTENSIONS = setOf("log", "txt", "trace")
        private val IMAGE_EXTENSIONS = setOf("jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif")
        private val VIDEO_EXTENSIONS = setOf("mp4", "mkv", "avi", "mov", "webm", "3gp", "flv")
        private val AUDIO_EXTENSIONS = setOf("mp3", "m4a", "wav", "flac", "ogg", "aac", "opus")
        private val DOCUMENT_EXTENSIONS = setOf("pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx")

        private val threadPool: ExecutorService by lazy {
            Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())
        }
    }

    fun scanDirectory(
        rootDir: File,
        maxDepth: Int = MAX_TRAVERSAL_DEPTH,
        maxFiles: Int = MAX_FILES_TO_SCAN,
        checkCancelled: () -> Boolean = { Thread.currentThread().isInterrupted }
    ): ScanResult {
        if (!rootDir.exists() || !rootDir.isDirectory || !rootDir.canRead()) {
            return ScanResult(limitReached = !rootDir.canRead())
        }

        val fileCounter = AtomicInteger(0)
        val totalSize = AtomicLong(0L)
        val databasesSize = AtomicLong(0L)
        val logsSize = AtomicLong(0L)
        val imagesSize = AtomicLong(0L)
        val videosSize = AtomicLong(0L)
        val audioSize = AtomicLong(0L)
        val documentsSize = AtomicLong(0L)
        val residualSize = AtomicLong(0L)
        val databaseFiles = ConcurrentHashMap<String, Long>()
        val limitReached = AtomicBoolean(false)

        val tasks = ConcurrentLinkedQueue<ScanTask>().apply { add(ScanTask(rootDir, 0)) }
        val phaser = Phaser(1)

        val taskProcessor = Runnable {
            var currentTask = tasks.poll()
            while (currentTask != null) {
                if (limitReached.get() || checkCancelled()) {
                    phaser.arriveAndDeregister()
                    while (tasks.poll() != null) {
                        phaser.arriveAndDeregister()
                    }
                    break
                }

                scanDirectoryConcurrent(
                    task = currentTask,
                    maxDepth = maxDepth,
                    fileCounter = fileCounter,
                    maxFiles = maxFiles,
                    totalSize = totalSize,
                    databasesSize = databasesSize,
                    logsSize = logsSize,
                    imagesSize = imagesSize,
                    videosSize = videosSize,
                    audioSize = audioSize,
                    documentsSize = documentsSize,
                    residualSize = residualSize,
                    databaseFiles = databaseFiles,
                    limitReached = limitReached,
                    tasks = tasks,
                    phaser = phaser
                )
                
                phaser.arriveAndDeregister()
                currentTask = tasks.poll()
            }
        }

        repeat(Runtime.getRuntime().availableProcessors()) {
            threadPool.submit(taskProcessor)
        }

        try {
            phaser.arriveAndAwaitAdvance()
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
            limitReached.set(true)
        }
        
        val mediaSize = imagesSize.get() + videosSize.get() + audioSize.get() + documentsSize.get()
        
        return ScanResult(
            totalSize = totalSize.get(),
            databasesSize = databasesSize.get(),
            logsSize = logsSize.get(),
            mediaSize = mediaSize,
            imagesSize = imagesSize.get(),
            videosSize = videosSize.get(),
            audioSize = audioSize.get(),
            documentsSize = documentsSize.get(),
            residualSize = residualSize.get(),
            databaseBreakdown = databaseFiles,
            filesScanned = fileCounter.get(),
            limitReached = limitReached.get()
        )
    }
    
    private fun scanDirectoryConcurrent(
        task: ScanTask,
        maxDepth: Int,
        fileCounter: AtomicInteger,
        maxFiles: Int,
        totalSize: AtomicLong,
        databasesSize: AtomicLong,
        logsSize: AtomicLong,
        imagesSize: AtomicLong,
        videosSize: AtomicLong,
        audioSize: AtomicLong,
        documentsSize: AtomicLong,
        residualSize: AtomicLong,
        databaseFiles: MutableMap<String, Long>,
        limitReached: AtomicBoolean,
        tasks: ConcurrentLinkedQueue<ScanTask>,
        phaser: Phaser
    ) {
        val (dir, depth) = task
        
        if (depth > maxDepth || !dir.canRead()) {
            limitReached.set(true)
            return
        }

        val files = try {
            dir.listFiles()
        } catch (e: Exception) {
            null
        } ?: return
        
        for (file in files) {
            if (limitReached.get()) break
            if (fileCounter.get() >= maxFiles) {
                limitReached.set(true)
                break
            }
            fileCounter.incrementAndGet()
            
            try {
                if (file.isDirectory) {
                    phaser.register()
                    tasks.add(ScanTask(file, depth + 1))
                } else {
                    processFile(file, totalSize, databasesSize, logsSize, imagesSize, videosSize, audioSize, documentsSize, residualSize, databaseFiles)
                }
            } catch (e: Exception) {
                // Skip file on error
            }
        }
    }
    
    private fun processFile(
        file: File,
        totalSize: AtomicLong,
        databasesSize: AtomicLong,
        logsSize: AtomicLong,
        imagesSize: AtomicLong,
        videosSize: AtomicLong,
        audioSize: AtomicLong,
        documentsSize: AtomicLong,
        residualSize: AtomicLong,
        databaseFiles: MutableMap<String, Long>
    ) {
        val fileSize = file.length()
        totalSize.addAndGet(fileSize)
        
        if (fileSize > MAX_FILE_SIZE_TO_CATEGORIZE) {
            residualSize.addAndGet(fileSize)
            return
        }

        when (file.extension.lowercase()) {
            in DATABASE_EXTENSIONS -> {
                databasesSize.addAndGet(fileSize)
                databaseFiles[file.name] = fileSize
            }
            in LOG_EXTENSIONS -> logsSize.addAndGet(fileSize)
            in IMAGE_EXTENSIONS -> imagesSize.addAndGet(fileSize)
            in VIDEO_EXTENSIONS -> videosSize.addAndGet(fileSize)
            in AUDIO_EXTENSIONS -> audioSize.addAndGet(fileSize)
            in DOCUMENT_EXTENSIONS -> documentsSize.addAndGet(fileSize)
            else -> residualSize.addAndGet(fileSize)
        }
    }

    fun quickSizeCalculation(
        rootDir: File,
        maxDepth: Int = MAX_TRAVERSAL_DEPTH,
        maxFiles: Int = MAX_FILES_TO_SCAN,
        checkCancelled: () -> Boolean = { Thread.currentThread().isInterrupted }
    ): Long {
        if (!rootDir.exists() || !rootDir.canRead()) return 0L

        val fileCounter = AtomicInteger(0)
        val totalSize = AtomicLong(0L)
        val limitReached = AtomicBoolean(false)

        val tasks = ConcurrentLinkedQueue<ScanTask>().apply { add(ScanTask(rootDir, 0)) }
        val phaser = Phaser(1)

        val taskProcessor = Runnable {
            var currentTask = tasks.poll()
            while (currentTask != null) {
                if (limitReached.get() || checkCancelled()) {
                    phaser.arriveAndDeregister()
                    while (tasks.poll() != null) {
                        phaser.arriveAndDeregister()
                    }
                    break
                }
                
                quickSizeConcurrent(
                    task = currentTask,
                    maxDepth = maxDepth,
                    fileCounter = fileCounter,
                    maxFiles = maxFiles,
                    totalSize = totalSize,
                    limitReached = limitReached,
                    tasks = tasks,
                    phaser = phaser
                )

                phaser.arriveAndDeregister()
                currentTask = tasks.poll()
            }
        }

        repeat(Runtime.getRuntime().availableProcessors()) {
            threadPool.submit(taskProcessor)
        }

        try {
            phaser.arriveAndAwaitAdvance()
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        return totalSize.get()
    }

    private fun quickSizeConcurrent(
        task: ScanTask,
        maxDepth: Int,
        fileCounter: AtomicInteger,
        maxFiles: Int,
        totalSize: AtomicLong,
        limitReached: AtomicBoolean,
        tasks: ConcurrentLinkedQueue<ScanTask>,
        phaser: Phaser
    ) {
        val (dir, depth) = task

        if (depth > maxDepth || !dir.canRead()) {
            limitReached.set(true)
            return
        }

        val files = try {
            dir.listFiles()
        } catch (e: Exception) {
            null
        } ?: return

        for (file in files) {
            if (limitReached.get() || fileCounter.get() >= maxFiles) {
                limitReached.set(true)
                break
            }
            fileCounter.incrementAndGet()

            try {
                if (file.isDirectory) {
                    phaser.register()
                    tasks.add(ScanTask(file, depth + 1))
                } else {
                    totalSize.addAndGet(file.length())
                }
            } catch (e: Exception) {
                // Skip file
            }
        }
    }
}