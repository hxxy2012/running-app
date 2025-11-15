package com.runningapp.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.runningapp.data.local.dao.*
import com.runningapp.data.local.entity.*

/**
 * 应用数据库
 */
@Database(
    entities = [
        UserEntity::class,
        RunningRecordEntity::class,
        TrackPointEntity::class,
        PostEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun userDao(): UserDao
    abstract fun runningRecordDao(): RunningRecordDao
    abstract fun trackPointDao(): TrackPointDao
    abstract fun postDao(): PostDao

    companion object {
        const val DATABASE_NAME = "running_app.db"
    }
}
