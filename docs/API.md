# API 文档 / API Documentation

## 概述 / Overview

GeoNote API 提供了与后端服务交互的接口，支持笔记管理、地理位置服务、媒体上传等功能。

## 基础信息 / Base Information

### Base URL
```
开发环境 / Development: http://localhost:3000/api/v1
生产环境 / Production: https://api.geonote.com/v1
```

### 认证 / Authentication

API 使用 JWT (JSON Web Token) 进行身份验证。

```http
Authorization: Bearer <your_access_token>
```

### 响应格式 / Response Format

所有 API 响应遵循统一格式：

```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "timestamp": "2025-12-09T12:00:00Z"
}
```

错误响应：

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述"
  },
  "timestamp": "2025-12-09T12:00:00Z"
}
```

### 状态码 / Status Codes

- `200 OK` - 请求成功
- `201 Created` - 资源创建成功
- `400 Bad Request` - 请求参数错误
- `401 Unauthorized` - 未授权
- `403 Forbidden` - 禁止访问
- `404 Not Found` - 资源不存在
- `500 Internal Server Error` - 服务器错误

---

## 笔记 API / Notes API

### 获取笔记列表 / Get Notes List

获取用户的笔记列表。

```http
GET /notes
```

**查询参数 / Query Parameters:**

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| page | number | 否 | 页码，默认 1 |
| limit | number | 否 | 每页数量，默认 20 |
| tag | string | 否 | 标签筛选 |
| search | string | 否 | 搜索关键词 |
| startDate | string | 否 | 开始日期 (ISO 8601) |
| endDate | string | 否 | 结束日期 (ISO 8601) |

**响应示例 / Response Example:**

```json
{
  "success": true,
  "data": {
    "notes": [
      {
        "id": "note_123",
        "title": "美丽的日落",
        "content": "在海边看到了美丽的日落",
        "location": {
          "lat": 39.9042,
          "lng": 116.4074,
          "address": "北京市朝阳区"
        },
        "tags": ["旅行", "风景"],
        "media": [
          {
            "id": "media_456",
            "type": "image",
            "url": "https://cdn.example.com/image.jpg"
          }
        ],
        "createdAt": "2025-12-09T10:00:00Z",
        "updatedAt": "2025-12-09T10:00:00Z"
      }
    ],
    "pagination": {
      "total": 100,
      "page": 1,
      "limit": 20,
      "totalPages": 5
    }
  }
}
```

### 创建笔记 / Create Note

创建新的笔记。

```http
POST /notes
```

**请求体 / Request Body:**

```json
{
  "title": "笔记标题",
  "content": "笔记内容",
  "location": {
    "lat": 39.9042,
    "lng": 116.4074,
    "address": "北京市朝阳区"
  },
  "tags": ["标签1", "标签2"],
  "mediaIds": ["media_123", "media_456"]
}
```

**响应示例 / Response Example:**

```json
{
  "success": true,
  "data": {
    "id": "note_789",
    "title": "笔记标题",
    "createdAt": "2025-12-09T12:00:00Z"
  },
  "message": "笔记创建成功"
}
```

### 获取笔记详情 / Get Note Details

获取特定笔记的详细信息。

```http
GET /notes/:id
```

**路径参数 / Path Parameters:**

| 参数 | 类型 | 描述 |
|------|------|------|
| id | string | 笔记 ID |

### 更新笔记 / Update Note

更新现有笔记。

```http
PUT /notes/:id
```

**请求体 / Request Body:**

```json
{
  "title": "更新的标题",
  "content": "更新的内容",
  "tags": ["新标签"]
}
```

### 删除笔记 / Delete Note

删除指定笔记。

```http
DELETE /notes/:id
```

---

## 媒体 API / Media API

### 上传媒体文件 / Upload Media

上传图片、视频等媒体文件。

```http
POST /media/upload
```

**请求格式 / Request Format:**

使用 `multipart/form-data` 格式上传文件。

```javascript
const formData = new FormData();
formData.append('file', fileBlob);
formData.append('type', 'image');
```

**响应示例 / Response Example:**

```json
{
  "success": true,
  "data": {
    "id": "media_123",
    "url": "https://cdn.example.com/uploads/abc123.jpg",
    "thumbnail": "https://cdn.example.com/uploads/abc123_thumb.jpg",
    "type": "image",
    "size": 1024000
  }
}
```

### 删除媒体文件 / Delete Media

删除指定的媒体文件。

```http
DELETE /media/:id
```

---

## 地理位置 API / Location API

### 地理编码 / Geocoding

将地址转换为经纬度坐标。

```http
GET /location/geocode
```

**查询参数 / Query Parameters:**

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| address | string | 是 | 地址字符串 |

**响应示例 / Response Example:**

```json
{
  "success": true,
  "data": {
    "lat": 39.9042,
    "lng": 116.4074,
    "address": "北京市朝阳区",
    "formattedAddress": "中国北京市朝阳区"
  }
}
```

### 逆地理编码 / Reverse Geocoding

将经纬度坐标转换为地址。

```http
GET /location/reverse-geocode
```

**查询参数 / Query Parameters:**

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| lat | number | 是 | 纬度 |
| lng | number | 是 | 经度 |

### 附近搜索 / Nearby Search

搜索指定位置附近的笔记。

```http
GET /location/nearby
```

**查询参数 / Query Parameters:**

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| lat | number | 是 | 纬度 |
| lng | number | 是 | 经度 |
| radius | number | 否 | 搜索半径（米），默认 1000 |

---

## 用户 API / User API

### 用户注册 / Register

创建新用户账户。

```http
POST /auth/register
```

**请求体 / Request Body:**

```json
{
  "username": "user123",
  "email": "user@example.com",
  "password": "securePassword123"
}
```

### 用户登录 / Login

用户登录获取访问令牌。

```http
POST /auth/login
```

**请求体 / Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**响应示例 / Response Example:**

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user_123",
      "username": "user123",
      "email": "user@example.com"
    }
  }
}
```

### 获取用户信息 / Get User Profile

获取当前用户信息。

```http
GET /user/profile
```

### 更新用户信息 / Update User Profile

更新用户资料。

```http
PUT /user/profile
```

---

## 标签 API / Tags API

### 获取标签列表 / Get Tags

获取所有标签。

```http
GET /tags
```

### 创建标签 / Create Tag

创建新标签。

```http
POST /tags
```

---

## 错误代码 / Error Codes

| 错误码 | 描述 |
|--------|------|
| AUTH_001 | 未提供认证令牌 |
| AUTH_002 | 认证令牌无效 |
| AUTH_003 | 认证令牌已过期 |
| NOTE_001 | 笔记不存在 |
| NOTE_002 | 笔记创建失败 |
| MEDIA_001 | 不支持的文件类型 |
| MEDIA_002 | 文件大小超过限制 |
| LOC_001 | 地理编码失败 |
| USER_001 | 用户不存在 |
| USER_002 | 邮箱已被使用 |

---

## 速率限制 / Rate Limiting

API 实施速率限制以保护服务：

- 未认证用户：100 请求/小时
- 认证用户：1000 请求/小时
- 上传接口：50 请求/小时

响应头包含速率限制信息：

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1638360000
```

---

## SDK 示例 / SDK Examples

### JavaScript / TypeScript

```javascript
import { GeoNoteClient } from '@geonote/client';

const client = new GeoNoteClient({
  apiKey: 'your_api_key',
  baseURL: 'https://api.geonote.com/v1'
});

// 创建笔记
const note = await client.notes.create({
  title: '我的笔记',
  content: '内容...',
  location: { lat: 39.9042, lng: 116.4074 }
});

// 获取笔记列表
const notes = await client.notes.list({
  page: 1,
  limit: 20
});
```

### Python

```python
from geonote import GeoNoteClient

client = GeoNoteClient(
    api_key='your_api_key',
    base_url='https://api.geonote.com/v1'
)

# 创建笔记
note = client.notes.create(
    title='我的笔记',
    content='内容...',
    location={'lat': 39.9042, 'lng': 116.4074}
)

# 获取笔记列表
notes = client.notes.list(page=1, limit=20)
```

---

## 更新日志 / Changelog

### v0.1.0 (开发中)
- 初始 API 设计
- 基础 CRUD 操作接口定义
- 地理位置服务接口规划

---

最后更新：2025-12-09
Last Updated: 2025-12-09
