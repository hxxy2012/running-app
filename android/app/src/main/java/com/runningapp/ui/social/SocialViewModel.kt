package com.runningapp.ui.social

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.runningapp.data.remote.model.Comment
import com.runningapp.data.remote.model.Post
import com.runningapp.data.repository.SocialRepository
import com.runningapp.utils.Result
import com.runningapp.utils.toErrorMessage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

/**
 * 社交模块ViewModel
 */
@HiltViewModel
class SocialViewModel @Inject constructor(
    private val socialRepository: SocialRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<UiState>(UiState.Idle)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val _posts = MutableStateFlow<List<Post>>(emptyList())
    val posts: StateFlow<List<Post>> = _posts.asStateFlow()

    private val _comments = MutableStateFlow<List<Comment>>(emptyList())
    val comments: StateFlow<List<Comment>> = _comments.asStateFlow()

    init {
        // 默认加载关注动态
        loadFeed("following")
    }

    /**
     * 获取动态流
     */
    fun loadFeed(type: String = "following", page: Int = 1) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = socialRepository.getFeed(type, page, 20)) {
                is Result.Success -> {
                    if (page == 1) {
                        _posts.value = result.data.list
                    } else {
                        _posts.value = _posts.value + result.data.list
                    }
                    _uiState.value = UiState.Idle
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 创建动态
     */
    fun createPost(content: String, images: List<File>? = null, recordId: Int? = null) {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = socialRepository.createPost(content, images, recordId)) {
                is Result.Success -> {
                    _uiState.value = UiState.PostCreated
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    /**
     * 点赞
     */
    fun likePost(postId: Int) {
        viewModelScope.launch {
            when (socialRepository.likePost(postId)) {
                is Result.Success -> {
                    // 更新本地列表
                    _posts.value = _posts.value.map { post ->
                        if (post.id == postId) {
                            post.copy(isLiked = true, likeCount = post.likeCount + 1)
                        } else {
                            post
                        }
                    }
                }
                is Result.Error -> {
                    // 静默处理
                }
                else -> {}
            }
        }
    }

    /**
     * 取消点赞
     */
    fun unlikePost(postId: Int) {
        viewModelScope.launch {
            when (socialRepository.unlikePost(postId)) {
                is Result.Success -> {
                    _posts.value = _posts.value.map { post ->
                        if (post.id == postId) {
                            post.copy(isLiked = false, likeCount = post.likeCount - 1)
                        } else {
                            post
                        }
                    }
                }
                is Result.Error -> {
                    // 静默处理
                }
                else -> {}
            }
        }
    }

    /**
     * 加载评论
     */
    fun loadComments(postId: Int, page: Int = 1) {
        viewModelScope.launch {
            when (val result = socialRepository.getComments(postId, page, 20)) {
                is Result.Success -> {
                    if (page == 1) {
                        _comments.value = result.data.list
                    } else {
                        _comments.value = _comments.value + result.data.list
                    }
                }
                is Result.Error -> {
                    // 静默处理
                }
                else -> {}
            }
        }
    }

    /**
     * 评论
     */
    fun comment(postId: Int, content: String, replyToUserId: Int? = null) {
        viewModelScope.launch {
            when (val result = socialRepository.commentPost(postId, content, replyToUserId)) {
                is Result.Success -> {
                    _comments.value = listOf(result.data) + _comments.value
                }
                is Result.Error -> {
                    _uiState.value = UiState.Error(result.exception.toErrorMessage())
                }
                else -> {}
            }
        }
    }

    sealed class UiState {
        object Idle : UiState()
        object Loading : UiState()
        object PostCreated : UiState()
        data class Error(val message: String) : UiState()
    }
}
