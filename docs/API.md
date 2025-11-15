# Running App API 接口文档

## 基础信息

**Base URL**: `https://api.yourapp.com/api`

**请求格式**: JSON

**响应格式**: JSON

**认证方式**: Bearer Token (JWT)

## 统一响应格式

### 成功响应
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1234567890
}
```

### 错误响应
```json
{
  "code": 400,
  "message": "错误描述",
  "data": {},
  "timestamp": 1234567890
}
```

### 分页响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "list": [],
    "pagination": {
      "total": 100,
      "page": 1,
      "page_size": 20,
      "total_page": 5
    }
  },
  "timestamp": 1234567890
}
```

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200    | 成功 |
| 400    | 参数错误 |
| 401    | 未授权/Token无效 |
| 403    | 禁止访问 |
| 404    | 资源不存在 |
| 500    | 服务器错误 |

---

## 1. 认证相关接口

### 1.1 发送验证码

**接口**: `POST /auth/send-code`

**说明**: 发送短信验证码

**请求参数**:
```json
{
  "phone": "13800138000",
  "type": 1
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| type | int | 否 | 类型：1注册 2登录 3重置密码，默认1 |

**响应示例**:
```json
{
  "code": 200,
  "message": "验证码发送成功",
  "data": {
    "code": "123456"
  },
  "timestamp": 1234567890
}
```

**注意**: `code`字段仅开发环境返回

---

### 1.2 注册

**接口**: `POST /auth/register`

**说明**: 用户注册

**请求参数**:
```json
{
  "phone": "13800138000",
  "code": "123456",
  "password": "password123",
  "nickname": "跑友"
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| code | string | 是 | 验证码 |
| password | string | 是 | 密码（至少6位） |
| nickname | string | 否 | 昵称 |

**响应示例**:
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "user": {
      "id": 1,
      "phone": "13800138000",
      "nickname": "跑友",
      "avatar": "http://..."
    },
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  },
  "timestamp": 1234567890
}
```

---

### 1.3 登录

**接口**: `POST /auth/login`

**说明**: 用户登录

**请求参数**:
```json
{
  "phone": "13800138000",
  "password": "password123"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "user": {
      "id": 1,
      "phone": "13800138000",
      "nickname": "跑友",
      "avatar": "http://...",
      "gender": 1,
      "city": "北京",
      "level": 5,
      "total_distance": 123.45,
      "total_time": 12345,
      "total_count": 50
    },
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  },
  "timestamp": 1234567890
}
```

---

### 1.4 刷新Token

**接口**: `POST /auth/refresh-token`

**说明**: 刷新Token

**请求头**:
```
Authorization: Bearer {old_token}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "Token刷新成功",
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  },
  "timestamp": 1234567890
}
```

---

## 2. 跑步记录接口

**所有跑步记录接口需要在请求头中携带Token**

### 2.1 开始跑步

**接口**: `POST /running/start`

**请求参数**:
```json
{
  "type": 1
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | int | 否 | 运动类型：1跑步 2骑行 3健走 4登山 5室内跑 |

**响应示例**:
```json
{
  "code": 200,
  "message": "开始跑步",
  "data": {
    "record_id": 123
  },
  "timestamp": 1234567890
}
```

---

### 2.2 上传轨迹点

**接口**: `POST /running/upload-point`

**说明**: 批量上传GPS轨迹点

**请求参数**:
```json
{
  "record_id": 123,
  "points": [
    {
      "latitude": 39.9042,
      "longitude": 116.4074,
      "altitude": 50.5,
      "accuracy": 10.0,
      "speed": 5.5,
      "heart_rate": 120,
      "timestamp": 1234567890000,
      "distance_from_start": 1.23
    }
  ]
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "total_points": 150,
    "distance": 1.23
  },
  "timestamp": 1234567890
}
```

---

### 2.3 结束跑步

**接口**: `POST /running/finish`

**请求参数**:
```json
{
  "record_id": 123,
  "distance": 5.12,
  "duration": 1800,
  "avg_pace": 352,
  "best_pace": 320,
  "avg_speed": 10.24,
  "step_count": 6000,
  "step_frequency": 180,
  "calories": 350,
  "climb": 50.5,
  "descent": 45.2,
  "avg_heart_rate": 135,
  "max_heart_rate": 160,
  "end_time": "2025-11-15 10:30:00",
  "start_location": "北京市朝阳区",
  "city": "北京",
  "weather": "晴",
  "temperature": 20
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "跑步完成",
  "data": {
    "record": {
      "id": 123,
      "distance": 5.12,
      "duration": 1800,
      ...
    }
  },
  "timestamp": 1234567890
}
```

---

### 2.4 获取记录列表

**接口**: `GET /running/records`

**请求参数**:
```
?page=1&page_size=20&type=1&start_date=2025-11-01&end_date=2025-11-15
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认1 |
| page_size | int | 否 | 每页数量，默认20 |
| type | int | 否 | 运动类型筛选 |
| start_date | string | 否 | 开始日期 YYYY-MM-DD |
| end_date | string | 否 | 结束日期 YYYY-MM-DD |

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "list": [
      {
        "id": 123,
        "type": 1,
        "type_text": "跑步",
        "distance": 5.12,
        "duration": 1800,
        "duration_text": "00:30:00",
        "avg_pace": 352,
        "calories": 350,
        "start_time": "2025-11-15 09:00:00",
        "city": "北京",
        "weather": "晴"
      }
    ],
    "pagination": {
      "total": 50,
      "page": 1,
      "page_size": 20,
      "total_page": 3
    }
  },
  "timestamp": 1234567890
}
```

---

### 2.5 记录详情

**接口**: `GET /running/record/{id}`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 123,
    "distance": 5.12,
    "duration": 1800,
    "track_points": [
      {
        "latitude": 39.9042,
        "longitude": 116.4074,
        "altitude": 50.5,
        "timestamp": 1234567890000
      }
    ],
    ...
  },
  "timestamp": 1234567890
}
```

---

### 2.6 统计数据

**接口**: `GET /running/statistics`

**请求参数**:
```
?type=month
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 否 | today/week/month/year，默认today |

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "count": 15,
    "total_distance": 75.5,
    "total_duration": 27000,
    "avg_pace": 357,
    "best_pace": 320
  },
  "timestamp": 1234567890
}
```

---

### 2.7 日历数据

**接口**: `GET /running/calendar`

**请求参数**:
```
?year=2025&month=11
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "date": "2025-11-01",
      "distance": 5.0,
      "count": 1
    },
    {
      "date": "2025-11-03",
      "distance": 10.2,
      "count": 2
    }
  ],
  "timestamp": 1234567890
}
```

---

### 2.8 PB记录

**接口**: `GET /running/pb`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "fastest_pace": {
      "id": 45,
      "distance": 5.0,
      "best_pace": 300,
      "start_time": "2025-11-10 09:00:00"
    },
    "longest_distance": {
      "id": 88,
      "distance": 21.0975,
      "duration": 7200,
      "start_time": "2025-10-01 07:00:00"
    },
    "longest_duration": {
      "id": 88,
      "duration": 7200,
      "distance": 21.0975,
      "start_time": "2025-10-01 07:00:00"
    }
  },
  "timestamp": 1234567890
}
```

---

## 3. 文件上传接口

### 3.1 上传图片

**接口**: `POST /upload/image`

**说明**: 上传图片文件

**Content-Type**: `multipart/form-data`

**请求参数**:
- file: 图片文件
- type: 类型（avatar/post/track）

**响应示例**:
```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "url": "http://api.yourapp.com/uploads/post/20251115/abc123.jpg",
    "path": "post/20251115/abc123.jpg",
    "size": 102400,
    "ext": "jpg"
  },
  "timestamp": 1234567890
}
```

---

## 4. 其他接口

### 4.1 获取配置

**接口**: `GET /config`

**说明**: 获取系统配置（无需Token）

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "app_name": "Running App",
    "version": "1.0.0",
    "upload_max_size": 5242880
  },
  "timestamp": 1234567890
}
```

---

### 4.2 版本检测

**接口**: `GET /version`

**请求参数**:
```
?platform=android&version=1.0.0
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "latest_version": "1.0.1",
    "current_version": "1.0.0",
    "need_update": true,
    "force_update": false,
    "download_url": "http://...",
    "update_log": [
      "修复已知问题",
      "优化性能"
    ]
  },
  "timestamp": 1234567890
}
```

---

### 4.3 获取天气

**接口**: `GET /common/weather`

**请求参数**:
```
?city=北京&lat=39.9042&lon=116.4074
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "city": "北京",
    "temperature": 20,
    "weather": "晴",
    "wind": "东南风 2级",
    "humidity": "60%",
    "running_index": "适宜",
    "running_index_desc": "天气晴朗，适合户外运动"
  },
  "timestamp": 1234567890
}
```

---

## 请求示例

### cURL示例

```bash
# 注册
curl -X POST http://api.yourapp.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "code": "123456",
    "password": "password123",
    "nickname": "跑友"
  }'

# 登录
curl -X POST http://api.yourapp.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "password": "password123"
  }'

# 获取记录列表（需要Token）
curl -X GET http://api.yourapp.com/api/running/records \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

---

## 附录

### 运动类型枚举
- 1: 跑步
- 2: 骑行
- 3: 健走
- 4: 登山
- 5: 室内跑

### 感觉枚举
- 0: 一般
- 1: 轻松
- 2: 良好
- 3: 困难
- 4: 痛苦

### 性别枚举
- 0: 未知
- 1: 男
- 2: 女

---

**更新日期**: 2025-11-15
**文档版本**: v1.0
