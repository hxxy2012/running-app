# 错误处理文档

本文档说明Running App项目中的错误处理机制。

## 目录

- [概述](#概述)
- [Android错误处理](#android错误处理)
- [iOS错误处理](#ios错误处理)
- [后端错误处理](#后端错误处理)
- [常见错误场景](#常见错误场景)
- [最佳实践](#最佳实践)

---

## 概述

项目采用统一的错误处理机制，将各种底层异常转换为用户友好的错误消息，提升用户体验。

### 核心原则

1. **用户友好** - 所有错误消息都经过转换，避免显示技术性错误
2. **统一处理** - 使用ErrorHandler工具类集中处理错误
3. **类型区分** - 区分网络错误、服务器错误、业务错误等
4. **可重试** - 对可重试的错误提供重试机制

---

## Android错误处理

### ErrorHandler工具类

位置：`android/app/src/main/java/com/runningapp/utils/ErrorHandler.kt`

#### 主要功能

1. **getErrorMessage()** - 获取用户友好的错误消息
2. **getSuggestion()** - 获取错误处理建议
3. **isNetworkError()** - 判断是否为网络错误
4. **isServerError()** - 判断是否为服务器错误
5. **needsReLogin()** - 判断是否需要重新登录
6. **isRetryable()** - 判断错误是否可重试

#### 使用示例

```kotlin
// 在ViewModel中使用
import com.runningapp.utils.toErrorMessage

when (val result = repository.login(phone, password)) {
    is Result.Success -> {
        // 处理成功
    }
    is Result.Error -> {
        // 使用ErrorHandler获取友好的错误消息
        val errorMessage = result.exception.toErrorMessage()
        _uiState.value = UiState.Error(errorMessage)
    }
}
```

#### 错误类型映射

| 异常类型 | 用户消息 |
|---------|---------|
| UnknownHostException | 网络连接失败，请检查网络设置 |
| SocketTimeoutException | 网络请求超时，请稍后重试 |
| IOException | 网络异常，请检查网络连接 |
| HttpException(400) | 请求参数错误 |
| HttpException(401) | 未授权，请重新登录 |
| HttpException(403) | 禁止访问 |
| HttpException(404) | 请求的资源不存在 |
| HttpException(500) | 服务器内部错误 |

### 自定义异常

```kotlin
class ApiException(
    override val message: String,
    val code: Int = -1,
    val data: Any? = null
) : Exception(message)
```

用于包装业务逻辑错误，例如：
- 验证码错误
- 手机号已注册
- 用户不存在

---

## iOS错误处理

### ErrorHandler工具类

位置：`ios/RunningApp/Utils/ErrorHandler.swift`

#### 主要功能

与Android版本功能一致，适配iOS的错误类型。

#### 使用示例

```swift
do {
    let response = try await networkService.request(...)
    // 处理成功
} catch {
    // 使用Error扩展获取友好的错误消息
    errorMessage = error.userFriendlyMessage

    // 获取建议
    if let suggestion = error.suggestion {
        print("建议：\(suggestion)")
    }

    // 判断是否需要重新登录
    if error.needsReLogin {
        // 跳转到登录页
    }
}
```

#### Error扩展属性

```swift
extension Error {
    var userFriendlyMessage: String    // 友好的错误消息
    var suggestion: String?            // 建议操作
    var isNetworkError: Bool          // 是否为网络错误
    var isServerError: Bool           // 是否为服务器错误
    var needsReLogin: Bool            // 是否需要重新登录
    var isRetryable: Bool             // 是否可重试
}
```

### 错误类型

```swift
enum NetworkError: LocalizedError {
    case apiError(String)      // API返回的业务错误
    case invalidResponse       // 无效的响应
    case decodingError        // 数据解析失败
}
```

---

## 后端错误处理

### 统一响应格式

```json
{
  "code": 200,
  "message": "成功",
  "data": { ... }
}
```

### 错误响应

```json
{
  "code": 400,
  "message": "手机号格式错误",
  "data": null
}
```

### HTTP状态码

| 状态码 | 说明 | 使用场景 |
|--------|------|---------|
| 200 | 成功 | 请求成功 |
| 400 | 参数错误 | 请求参数验证失败 |
| 401 | 未授权 | Token无效或过期 |
| 403 | 禁止访问 | 无权限访问资源 |
| 404 | 资源不存在 | 找不到请求的资源 |
| 429 | 请求过于频繁 | 超过速率限制 |
| 500 | 服务器错误 | 服务器内部错误 |

---

## 常见错误场景

### 1. 网络连接失败

**Android:**
```kotlin
UnknownHostException
```

**iOS:**
```swift
URLError.Code.notConnectedToInternet
```

**用户消息:** "网络连接失败，请检查网络设置"

**建议:** "请确认已连接到互联网"

---

### 2. 请求超时

**Android:**
```kotlin
SocketTimeoutException
```

**iOS:**
```swift
URLError.Code.timedOut
```

**用户消息:** "网络请求超时，请稍后重试"

**建议:** "网络较慢，建议切换到更稳定的网络"

**可重试:** 是

---

### 3. Token过期

**HTTP状态码:** 401

**用户消息:** "未授权，请重新登录"

**建议:** "请重新登录"

**处理方式:**
- Android: 清除token，跳转到登录页
- iOS: 清除Keychain，发送登出通知
- 自动重试: Token自动刷新机制

---

### 4. 服务器错误

**HTTP状态码:** 500-599

**用户消息:** "服务器内部错误" / "服务暂时不可用，请稍后重试"

**建议:** "服务器繁忙，请稍后再试"

**可重试:** 是

---

### 5. 业务逻辑错误

**示例:** 手机号已注册、验证码错误等

**处理方式:** 后端返回code=400和具体的错误消息

```json
{
  "code": 400,
  "message": "该手机号已注册",
  "data": null
}
```

**客户端:** 直接显示message字段内容

---

## 最佳实践

### 1. 在ViewModel中处理错误

**Android:**
```kotlin
viewModelScope.launch {
    _uiState.value = UiState.Loading
    when (val result = repository.getData()) {
        is Result.Success -> {
            _uiState.value = UiState.Success(result.data)
        }
        is Result.Error -> {
            val errorMessage = result.exception.toErrorMessage()
            _uiState.value = UiState.Error(errorMessage)

            // 根据错误类型采取不同行动
            if (ErrorHandler.needsReLogin(result.exception)) {
                // 清除登录状态
                logout()
            }
        }
    }
}
```

**iOS:**
```swift
@Published var errorMessage: String?
@Published var isLoading = false

func loadData() {
    isLoading = true
    errorMessage = nil

    Task {
        do {
            let data = try await networkService.getData()
            // 处理成功
        } catch {
            await MainActor.run {
                errorMessage = error.userFriendlyMessage
                isLoading = false

                // 根据错误类型采取不同行动
                if error.needsReLogin {
                    logout()
                }
            }
        }
    }
}
```

### 2. 在UI中显示错误

**Android Compose:**
```kotlin
when (val state = uiState) {
    is UiState.Error -> {
        Snackbar(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = state.message)
        }
    }
}
```

**iOS SwiftUI:**
```swift
.alert("错误", isPresented: $showError) {
    Button("确定") {
        showError = false
    }
} message: {
    if let errorMessage = errorMessage {
        Text(errorMessage)
    }
}
```

### 3. 实现重试机制

```kotlin
// Android
var retryCount = 0
fun loadDataWithRetry() {
    viewModelScope.launch {
        try {
            val result = repository.getData()
            retryCount = 0  // 重置计数
        } catch (e: Exception) {
            if (ErrorHandler.isRetryable(e) && retryCount < 3) {
                retryCount++
                delay(2000L * retryCount)  // 指数退避
                loadDataWithRetry()
            } else {
                _uiState.value = UiState.Error(e.toErrorMessage())
            }
        }
    }
}
```

### 4. 日志记录

在捕获错误时记录详细的错误信息用于调试：

```kotlin
// Android
is Result.Error -> {
    Log.e("LoginViewModel", "Login failed", result.exception)
    _uiState.value = UiState.Error(result.exception.toErrorMessage())
}
```

```swift
// iOS
} catch {
    print("Login failed: \(error)")
    errorMessage = error.userFriendlyMessage
}
```

### 5. 全局错误处理

对于未捕获的异常，可以设置全局错误处理器：

**Android:**
```kotlin
Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
    Log.e("UncaughtException", "Thread: ${thread.name}", throwable)
    // 记录到日志服务
}
```

**iOS:**
```swift
NSSetUncaughtExceptionHandler { exception in
    print("Uncaught exception: \(exception)")
    // 记录到日志服务
}
```

---

## 总结

通过使用ErrorHandler工具类和统一的错误处理机制：

1. ✅ 提升用户体验 - 显示友好的错误消息而非技术错误
2. ✅ 简化开发 - 统一的API，减少重复代码
3. ✅ 易于维护 - 集中管理错误消息和处理逻辑
4. ✅ 智能处理 - 自动判断错误类型和是否可重试
5. ✅ 增强可靠性 - 自动重试机制和Token刷新机制

---

**相关文档:**
- [API文档](API.md)
- [部署指南](DEPLOYMENT.md)
- [Bug修复报告](BUG_FIXES_REPORT.md)
