package com.runningapp.data.local.dao

import androidx.room.*
import com.runningapp.data.local.entity.PostEntity
import kotlinx.coroutines.flow.Flow

/**
 * 动态帖子数据访问对象
 */
@Dao
interface PostDao {

    @Query("SELECT * FROM post ORDER BY createdAt DESC LIMIT :limit OFFSET :offset")
    suspend fun getPostsPage(limit: Int, offset: Int): List<PostEntity>

    @Query("SELECT * FROM post WHERE userId = :userId ORDER BY createdAt DESC")
    fun getPostsByUserId(userId: Int): Flow<List<PostEntity>>

    @Query("SELECT * FROM post WHERE id = :postId")
    suspend fun getPostById(postId: Int): PostEntity?

    @Query("SELECT * FROM post WHERE id = :postId")
    fun getPostByIdFlow(postId: Int): Flow<PostEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPost(post: PostEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPosts(posts: List<PostEntity>)

    @Update
    suspend fun updatePost(post: PostEntity)

    @Query("UPDATE post SET isLiked = :isLiked, likeCount = likeCount + :delta WHERE id = :postId")
    suspend fun updateLikeStatus(postId: Int, isLiked: Boolean, delta: Int)

    @Query("UPDATE post SET commentCount = commentCount + :delta WHERE id = :postId")
    suspend fun updateCommentCount(postId: Int, delta: Int)

    @Delete
    suspend fun deletePost(post: PostEntity)

    @Query("DELETE FROM post WHERE id = :postId")
    suspend fun deletePostById(postId: Int)

    @Query("DELETE FROM post")
    suspend fun deleteAllPosts()
}
