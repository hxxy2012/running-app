# 贡献指南

感谢您对 Running App 项目的关注！我们欢迎任何形式的贡献。

## 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发环境搭建](#开发环境搭建)
- [提交规范](#提交规范)
- [代码规范](#代码规范)
- [测试要求](#测试要求)
- [文档贡献](#文档贡献)

---

## 行为准则

本项目遵循 [行为准则](CODE_OF_CONDUCT.md)。参与本项目即表示您同意遵守其中的条款。

---

## 如何贡献

### 报告Bug

如果您发现了Bug，请通过以下方式报告：

1. **检查是否已存在**：在 [Issues](https://github.com/your-username/running-app/issues) 中搜索，确保该问题未被报告
2. **创建新Issue**：使用Bug报告模板，提供以下信息：
   - 详细的问题描述
   - 复现步骤
   - 预期行为
   - 实际行为
   - 环境信息（操作系统、浏览器/设备、版本号）
   - 相关日志或截图

### 提出新功能

我们欢迎新功能建议：

1. **检查是否已存在**：在Issues中搜索类似的功能请求
2. **创建Feature Request**：详细描述：
   - 功能的使用场景
   - 预期的实现效果
   - 为什么这个功能对用户有价值

### 提交Pull Request

我们欢迎代码贡献！请遵循以下流程：

#### 1. Fork和Clone

```bash
# Fork 项目到您的账户
# 然后克隆您的 fork
git clone https://github.com/your-username/running-app.git
cd running-app
```

#### 2. 创建分支

基于 `main` 分支创建您的功能分支：

```bash
git checkout -b feature/your-feature-name
```

分支命名规范：
- 新功能：`feature/功能名称`
- Bug修复：`fix/问题描述`
- 文档：`docs/文档说明`
- 性能优化：`perf/优化说明`
- 重构：`refactor/重构说明`

#### 3. 开发

- 遵循[代码规范](#代码规范)
- 编写清晰的代码注释
- 确保代码通过所有测试
- 添加必要的测试用例

#### 4. 提交

遵循[提交规范](#提交规范)：

```bash
git add .
git commit -m "feat: 添加用户头像上传功能"
```

#### 5. 推送

```bash
git push origin feature/your-feature-name
```

#### 6. 创建Pull Request

1. 前往 GitHub 上您的 fork
2. 点击 "New Pull Request"
3. 选择 base 分支为 `main`，compare 分支为您的功能分支
4. 填写 PR 模板：
   - 描述变更内容
   - 关联相关Issue（使用 `Closes #123`）
   - 说明测试情况
   - 附上截图（如有UI变更）

#### 7. Code Review

- 维护者会审查您的代码
- 根据反馈进行必要的修改
- 所有检查通过后，PR将被合并

---

## 开发环境搭建

### 后端开发

```bash
cd backend

# 安装依赖
composer install

# 配置环境
cp .env.example .env
# 编辑 .env 配置数据库等信息

# 导入数据库
mysql -u root -p < database/running_app.sql

# 启动开发服务器
php think run
```

### Android开发

```bash
cd android

# 使用 Android Studio 打开项目
# 修改 API 地址：app/src/main/java/com/runningapp/di/AppModule.kt

# 构建
./gradlew assembleDebug
```

### iOS开发

```bash
cd ios

# 安装依赖
pod install

# 使用 Xcode 打开
open RunningApp.xcworkspace

# 修改 API 地址：RunningApp/Services/NetworkService.swift
```

### 使用 Docker（推荐）

```bash
# 复制环境配置
cp .env.docker .env

# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

详细说明请参考 [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md)

---

## 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范。

### 提交格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

- **feat**: 新功能
- **fix**: Bug修复
- **docs**: 文档变更
- **style**: 代码格式（不影响代码运行）
- **refactor**: 重构（既不是新功能也不是Bug修复）
- **perf**: 性能优化
- **test**: 测试相关
- **chore**: 构建过程或辅助工具的变动

### Scope 范围（可选）

- **backend**: 后端相关
- **android**: Android相关
- **ios**: iOS相关
- **api**: API接口
- **database**: 数据库
- **docs**: 文档

### 示例

```bash
# 新功能
git commit -m "feat(android): 添加跑步记录详情页面"

# Bug修复
git commit -m "fix(backend): 修复用户登录验证码过期问题"

# 文档
git commit -m "docs: 更新Docker部署指南"

# 性能优化
git commit -m "perf(ios): 优化地图渲染性能"
```

---

## 代码规范

### 后端 (PHP)

遵循 [PSR-12](https://www.php-fig.org/psr/psr-12/) 编码规范：

```php
<?php
namespace app\api\controller;

use think\Request;

class User
{
    /**
     * 获取用户信息
     */
    public function profile(Request $request)
    {
        $userId = $request->userId;

        // 业务逻辑

        return json([
            'code' => 200,
            'message' => 'success',
            'data' => $data
        ]);
    }
}
```

**要点**：
- 使用 4 个空格缩进
- 类名使用 PascalCase
- 方法名使用 camelCase
- 添加清晰的注释

### Android (Kotlin)

遵循 [Kotlin 官方编码规范](https://kotlinlang.org/docs/coding-conventions.html)：

```kotlin
class RunningViewModel @Inject constructor(
    private val repository: RunningRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(RunningUiState())
    val uiState: StateFlow<RunningUiState> = _uiState.asStateFlow()

    /**
     * 开始跑步
     */
    fun startRunning() {
        viewModelScope.launch {
            repository.startRunning()
                .collect { result ->
                    // 处理结果
                }
        }
    }
}
```

**要点**：
- 使用 4 个空格缩进
- 类名使用 PascalCase
- 函数名使用 camelCase
- 使用 MVVM 架构
- 使用 Jetpack Compose 构建UI
- 使用 Hilt 进行依赖注入

### iOS (Swift)

遵循 [Swift 官方编码规范](https://swift.org/documentation/api-design-guidelines/)：

```swift
class RunningViewModel: ObservableObject {
    @Published var uiState = RunningUiState()

    private let repository: RunningRepository

    init(repository: RunningRepository = RunningRepository()) {
        self.repository = repository
    }

    /// 开始跑步
    func startRunning() {
        Task {
            do {
                let result = try await repository.startRunning()
                // 处理结果
            } catch {
                Logger.e("Failed to start running", error: error)
            }
        }
    }
}
```

**要点**：
- 使用 4 个空格缩进
- 类名使用 PascalCase
- 函数名使用 camelCase
- 使用 MVVM 架构
- 使用 SwiftUI 构建UI
- 使用 Combine 进行响应式编程

---

## 测试要求

### 单元测试

提交代码时，请确保：

1. **新功能必须包含测试**
2. **Bug修复需要添加回归测试**
3. **所有测试必须通过**

### 后端测试

```bash
cd backend
composer test
```

### Android测试

```bash
cd android
./gradlew test
./gradlew connectedAndroidTest
```

### iOS测试

```bash
cd ios
xcodebuild test -workspace RunningApp.xcworkspace -scheme RunningApp
```

---

## 文档贡献

文档和代码同样重要！

### 文档类型

- **API文档**：更新 `API.md`
- **使用指南**：更新 `QUICK_START.md`
- **部署文档**：更新 `DEPLOYMENT.md` 或 `DOCKER_DEPLOY.md`
- **集成指南**：更新 `INTEGRATION_GUIDE.md`

### 文档规范

- 使用清晰的标题层级
- 提供代码示例
- 添加必要的截图
- 保持与代码同步更新

---

## 许可证

提交代码即表示您同意您的贡献将在 [MIT License](LICENSE) 下发布。

---

## 获取帮助

如有任何问题，可以通过以下方式获取帮助：

- **GitHub Issues**: https://github.com/your-username/running-app/issues
- **GitHub Discussions**: https://github.com/your-username/running-app/discussions
- **Email**: support@your-domain.com

---

再次感谢您的贡献！ 🎉
