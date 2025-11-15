package com.runningapp.data.repository

import com.runningapp.data.local.dao.PostDao
import com.runningapp.data.remote.ApiService
import com.runningapp.data.remote.model.*
import com.runningapp.utils.Result
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 社交仓库
 */
@Singleton
class SocialRepository @Inject constructor(
    private val apiService: ApiService,
    private val postDao: PostDao
) {

    /**
     * 创建动态
     */
    suspend fun createPost(content: String, images: List<File>?, recordId: Int?): Result<Post> {
        return try {
            val imageParts = images?.map { file ->
                val requestFile = file.asRequestBody("image/*".toMediaTypeOrNull())
                MultipartBody.Part.createFormData("images[]", file.name, requestFile)
            }

            val response = apiService.createPost(content, recordId, imageParts)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取动态流
     */
    suspend fun getFeed(type: String, page: Int, pageSize: Int): Result<PageResponse<Post>> {
        return try {
            val response = apiService.getFeed(type, page, pageSize)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取广场动态
     */
    suspend fun getSquare(page: Int, pageSize: Int): Result<PageResponse<Post>> {
        return try {
            val response = apiService.getSquare(page, pageSize)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取动态详情
     */
    suspend fun getPostDetail(postId: Int): Result<Post> {
        return try {
            val response = apiService.getPostDetail(postId)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 删除动态
     */
    suspend fun deletePost(postId: Int): Result<Unit> {
        return try {
            val response = apiService.deletePost(postId)
            if (response.code == 200) {
                postDao.deletePostById(postId)
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 点赞动态
     */
    suspend fun likePost(postId: Int): Result<Unit> {
        return try {
            val response = apiService.likePost(postId)
            if (response.code == 200) {
                postDao.updateLikeStatus(postId, true, 1)
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 取消点赞
     */
    suspend fun unlikePost(postId: Int): Result<Unit> {
        return try {
            val response = apiService.unlikePost(postId)
            if (response.code == 200) {
                postDao.updateLikeStatus(postId, false, -1)
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 评论动态
     */
    suspend fun commentPost(postId: Int, content: String, replyToUserId: Int?): Result<Comment> {
        return try {
            val response = apiService.commentPost(
                mapOf(
                    "post_id" to postId,
                    "content" to content,
                    "reply_to_user_id" to (replyToUserId ?: 0)
                )
            )
            if (response.code == 200 && response.data != null) {
                postDao.updateCommentCount(postId, 1)
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取评论列表
     */
    suspend fun getComments(postId: Int, page: Int, pageSize: Int): Result<PageResponse<Comment>> {
        return try {
            val response = apiService.getComments(postId, page, pageSize)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 关注用户
     */
    suspend fun followUser(userId: Int): Result<Unit> {
        return try {
            val response = apiService.followUser(mapOf("user_id" to userId))
            if (response.code == 200) {
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 取消关注
     */
    suspend fun unfollowUser(userId: Int): Result<Unit> {
        return try {
            val response = apiService.unfollowUser(mapOf("user_id" to userId))
            if (response.code == 200) {
                Result.Success(Unit)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取关注列表
     */
    suspend fun getFollowing(userId: Int, page: Int, pageSize: Int): Result<PageResponse<User>> {
        return try {
            val response = apiService.getFollowing(userId, page, pageSize)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * 获取粉丝列表
     */
    suspend fun getFollowers(userId: Int, page: Int, pageSize: Int): Result<PageResponse<User>> {
        return try {
            val response = apiService.getFollowers(userId, page, pageSize)
            if (response.code == 200 && response.data != null) {
                Result.Success(response.data)
            } else {
                Result.Error(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }
}
