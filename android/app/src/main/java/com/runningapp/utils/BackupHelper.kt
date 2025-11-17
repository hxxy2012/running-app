package com.runningapp.utils

import android.content.Context
import android.os.Environment
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 数据备份和恢复工具
 * 支持导出跑步数据、设置等
 */
@Singleton
class BackupHelper @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        private const val BACKUP_DIR = "RunningApp_Backup"
        private const val BACKUP_FILE_PREFIX = "backup_"
        private const val BACKUP_FILE_EXT = ".zip"
    }

    // MARK: - 备份数据

    /**
     * 备份所有数据
     */
    suspend fun backupAllData(): Result<File> = withContext(Dispatchers.IO) {
        try {
            val backupFile = createBackupFile()
            val dataJson = collectAllData()

            // 创建ZIP文件
            ZipOutputStream(FileOutputStream(backupFile)).use { zipOut ->
                // 添加数据JSON
                zipOut.putNextEntry(ZipEntry("data.json"))
                zipOut.write(dataJson.toString().toByteArray())
                zipOut.closeEntry()

                // 添加设置
                val prefsJson = exportPreferences()
                zipOut.putNextEntry(ZipEntry("preferences.json"))
                zipOut.write(prefsJson.toString().toByteArray())
                zipOut.closeEntry()

                // 添加元数据
                val metaJson = createMetadata()
                zipOut.putNextEntry(ZipEntry("metadata.json"))
                zipOut.write(metaJson.toString().toByteArray())
                zipOut.closeEntry()
            }

            Logger.d("BackupHelper", "Backup created: ${backupFile.absolutePath}")
            Result.success(backupFile)
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Backup failed", e)
            Result.failure(e)
        }
    }

    /**
     * 收集所有数据
     */
    private suspend fun collectAllData(): JSONObject = withContext(Dispatchers.IO) {
        val dataJson = JSONObject()

        try {
            // 这里应该从数据库读取数据
            // 示例结构
            dataJson.put("version", 1)
            dataJson.put("runningRecords", JSONArray())
            dataJson.put("achievements", JSONArray())
            dataJson.put("trainingPlans", JSONArray())

            Logger.d("BackupHelper", "Data collected")
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Collect data failed", e)
        }

        dataJson
    }

    /**
     * 导出偏好设置
     */
    private fun exportPreferences(): JSONObject {
        val prefsJson = JSONObject()
        val prefs = context.getSharedPreferences("app_preferences", Context.MODE_PRIVATE)

        try {
            prefs.all.forEach { (key, value) ->
                when (value) {
                    is String -> prefsJson.put(key, value)
                    is Int -> prefsJson.put(key, value)
                    is Long -> prefsJson.put(key, value)
                    is Float -> prefsJson.put(key, value)
                    is Boolean -> prefsJson.put(key, value)
                }
            }
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Export preferences failed", e)
        }

        return prefsJson
    }

    /**
     * 创建元数据
     */
    private fun createMetadata(): JSONObject {
        return JSONObject().apply {
            put("appVersion", DeviceHelper(context).getVersionName())
            put("backupTime", System.currentTimeMillis())
            put("deviceModel", DeviceHelper(context).getDeviceName())
            put("androidVersion", DeviceHelper(context).getAndroidVersion())
        }
    }

    /**
     * 创建备份文件
     */
    private fun createBackupFile(): File {
        val backupDir = File(
            context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS),
            BACKUP_DIR
        )
        if (!backupDir.exists()) {
            backupDir.mkdirs()
        }

        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
            .format(Date())
        val fileName = "$BACKUP_FILE_PREFIX$timestamp$BACKUP_FILE_EXT"

        return File(backupDir, fileName)
    }

    // MARK: - 恢复数据

    /**
     * 从备份文件恢复数据
     */
    suspend fun restoreFromBackup(backupFile: File): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            if (!backupFile.exists()) {
                return@withContext Result.failure(Exception("Backup file not found"))
            }

            var dataJson: JSONObject? = null
            var prefsJson: JSONObject? = null
            var metaJson: JSONObject? = null

            // 解压ZIP文件
            ZipInputStream(FileInputStream(backupFile)).use { zipIn ->
                var entry = zipIn.nextEntry
                while (entry != null) {
                    val content = zipIn.readBytes().toString(Charsets.UTF_8)

                    when (entry.name) {
                        "data.json" -> dataJson = JSONObject(content)
                        "preferences.json" -> prefsJson = JSONObject(content)
                        "metadata.json" -> metaJson = JSONObject(content)
                    }

                    zipIn.closeEntry()
                    entry = zipIn.nextEntry
                }
            }

            // 恢复数据
            dataJson?.let { restoreData(it) }
            prefsJson?.let { restorePreferences(it) }

            Logger.d("BackupHelper", "Restore completed")
            Result.success(Unit)
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Restore failed", e)
            Result.failure(e)
        }
    }

    /**
     * 恢复数据
     */
    private suspend fun restoreData(dataJson: JSONObject) = withContext(Dispatchers.IO) {
        try {
            // 这里应该将数据写入数据库
            Logger.d("BackupHelper", "Data restored")
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Restore data failed", e)
        }
    }

    /**
     * 恢复偏好设置
     */
    private fun restorePreferences(prefsJson: JSONObject) {
        val prefs = context.getSharedPreferences("app_preferences", Context.MODE_PRIVATE)
        val editor = prefs.edit()

        try {
            prefsJson.keys().forEach { key ->
                when (val value = prefsJson.get(key)) {
                    is String -> editor.putString(key, value)
                    is Int -> editor.putInt(key, value)
                    is Long -> editor.putLong(key, value)
                    is Double -> editor.putFloat(key, value.toFloat())
                    is Boolean -> editor.putBoolean(key, value)
                }
            }
            editor.apply()

            Logger.d("BackupHelper", "Preferences restored")
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Restore preferences failed", e)
        }
    }

    // MARK: - 导出数据

    /**
     * 导出跑步数据为CSV
     */
    suspend fun exportRunningDataToCsv(): Result<File> = withContext(Dispatchers.IO) {
        try {
            val exportFile = createExportFile("running_data", "csv")

            // CSV头部
            val csv = StringBuilder()
            csv.append("日期,距离(km),时长(秒),配速(min/km),卡路里,平均心率\n")

            // 这里应该从数据库读取数据并写入CSV
            // 示例数据
            csv.append("2025-11-17,5.2,1800,5.77,300,145\n")

            FileOutputStream(exportFile).use { out ->
                out.write(csv.toString().toByteArray())
            }

            Logger.d("BackupHelper", "CSV exported: ${exportFile.absolutePath}")
            Result.success(exportFile)
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Export CSV failed", e)
            Result.failure(e)
        }
    }

    /**
     * 导出跑步数据为JSON
     */
    suspend fun exportRunningDataToJson(): Result<File> = withContext(Dispatchers.IO) {
        try {
            val exportFile = createExportFile("running_data", "json")
            val dataJson = collectAllData()

            FileOutputStream(exportFile).use { out ->
                out.write(dataJson.toString(2).toByteArray())
            }

            Logger.d("BackupHelper", "JSON exported: ${exportFile.absolutePath}")
            Result.success(exportFile)
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Export JSON failed", e)
            Result.failure(e)
        }
    }

    /**
     * 创建导出文件
     */
    private fun createExportFile(name: String, extension: String): File {
        val exportDir = File(
            context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS),
            "Exports"
        )
        if (!exportDir.exists()) {
            exportDir.mkdirs()
        }

        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
            .format(Date())
        val fileName = "${name}_$timestamp.$extension"

        return File(exportDir, fileName)
    }

    // MARK: - 备份管理

    /**
     * 获取所有备份文件
     */
    fun getAllBackups(): List<File> {
        val backupDir = File(
            context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS),
            BACKUP_DIR
        )

        return if (backupDir.exists()) {
            backupDir.listFiles { file ->
                file.name.startsWith(BACKUP_FILE_PREFIX) &&
                        file.name.endsWith(BACKUP_FILE_EXT)
            }?.sortedByDescending { it.lastModified() } ?: emptyList()
        } else {
            emptyList()
        }
    }

    /**
     * 删除备份文件
     */
    fun deleteBackup(backupFile: File): Boolean {
        return try {
            backupFile.delete()
        } catch (e: Exception) {
            Logger.e("BackupHelper", "Delete backup failed", e)
            false
        }
    }

    /**
     * 清理旧备份（保留最近N个）
     */
    fun cleanOldBackups(keepCount: Int = 5) {
        val backups = getAllBackups()
        if (backups.size > keepCount) {
            backups.drop(keepCount).forEach { it.delete() }
            Logger.d("BackupHelper", "Cleaned ${backups.size - keepCount} old backups")
        }
    }

    /**
     * 获取备份文件大小
     */
    fun getBackupSize(backupFile: File): Long {
        return backupFile.length()
    }

    /**
     * 获取备份文件信息
     */
    fun getBackupInfo(backupFile: File): Map<String, String> {
        return mapOf(
            "name" to backupFile.name,
            "size" to FormatUtils(context).formatFileSize(backupFile.length()),
            "date" to SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                .format(Date(backupFile.lastModified()))
        )
    }
}
