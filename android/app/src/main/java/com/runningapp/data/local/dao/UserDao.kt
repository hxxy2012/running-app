package com.runningapp.data.local.dao

import androidx.room.*
import com.runningapp.data.local.entity.UserEntity
import kotlinx.coroutines.flow.Flow

/**
 * 用户数据访问对象
 */
@Dao
interface UserDao {

    @Query("SELECT * FROM user WHERE id = :userId")
    suspend fun getUserById(userId: Int): UserEntity?

    @Query("SELECT * FROM user WHERE id = :userId")
    fun getUserByIdFlow(userId: Int): Flow<UserEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsers(users: List<UserEntity>)

    @Update
    suspend fun updateUser(user: UserEntity)

    @Query("DELETE FROM user WHERE id = :userId")
    suspend fun deleteUser(userId: Int)

    @Query("DELETE FROM user")
    suspend fun deleteAllUsers()
}
