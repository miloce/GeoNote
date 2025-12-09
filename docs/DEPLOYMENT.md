# 部署指南 / Deployment Guide

## 目录 / Table of Contents

- [部署概述](#部署概述)
- [环境准备](#环境准备)
- [前端部署](#前端部署)
- [后端部署](#后端部署)
- [数据库配置](#数据库配置)
- [CDN 配置](#cdn-配置)
- [监控与日志](#监控与日志)
- [常见问题](#常见问题)

---

## 部署概述 / Deployment Overview

GeoNote 支持多种部署方式，可以部署到传统服务器、云平台或使用容器化部署。

### 部署架构

```
┌─────────────────┐
│   用户浏览器     │
└────────┬────────┘
         │
    ┌────┴────┐
    │   CDN   │ (静态资源)
    └────┬────┘
         │
┌────────┴─────────┐
│   负载均衡器      │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Nginx   │ (Web 服务器)
    └────┬────┘
         │
┌────────┴─────────┐
│  应用服务器群组   │
│  (Node.js)       │
└────────┬─────────┘
         │
    ┌────┴────────────┐
    │   PostgreSQL    │ (数据库)
    └─────────────────┘
```

---

## 环境准备 / Environment Setup

### 系统要求

#### 最低配置
- CPU: 2 核
- 内存: 4GB
- 硬盘: 20GB SSD
- 操作系统: Ubuntu 20.04+ / CentOS 8+ / Debian 11+

#### 推荐配置
- CPU: 4 核
- 内存: 8GB
- 硬盘: 50GB SSD
- 操作系统: Ubuntu 22.04 LTS

### 软件要求

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必需软件
sudo apt install -y curl git build-essential

# 安装 Node.js (使用 nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18

# 安装 Nginx
sudo apt install -y nginx

# 安装 PostgreSQL
sudo apt install -y postgresql postgresql-contrib
```

---

## 前端部署 / Frontend Deployment

### 方式一：静态网站托管

#### 1. 构建生产版本

```bash
# 安装依赖
npm ci

# 构建
npm run build

# 构建产物在 dist/ 目录
```

#### 2. Vercel 部署

```bash
# 安装 Vercel CLI
npm i -g vercel

# 登录
vercel login

# 部署
vercel --prod
```

#### 3. Netlify 部署

```bash
# 安装 Netlify CLI
npm i -g netlify-cli

# 登录
netlify login

# 部署
netlify deploy --prod --dir=dist
```

#### 4. GitHub Pages 部署

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
          
      - name: Install and Build
        run: |
          npm ci
          npm run build
          
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

### 方式二：自建服务器部署

#### 1. Nginx 配置

创建配置文件 `/etc/nginx/sites-available/geonote`：

```nginx
server {
    listen 80;
    server_name geonote.com www.geonote.com;
    
    root /var/www/geonote/dist;
    index index.html;
    
    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/javascript application/json;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

#### 2. 启用站点

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/geonote /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

#### 3. SSL 证书配置（Let's Encrypt）

```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d geonote.com -d www.geonote.com

# 自动续期
sudo certbot renew --dry-run
```

### 方式三：Docker 部署

#### Dockerfile

```dockerfile
# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# 生产阶段
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### 构建和运行

```bash
# 构建镜像
docker build -t geonote-frontend:latest .

# 运行容器
docker run -d \
  --name geonote-frontend \
  -p 80:80 \
  geonote-frontend:latest
```

---

## 后端部署 / Backend Deployment

### Node.js 应用部署

#### 1. 使用 PM2 管理进程

```bash
# 安装 PM2
npm install -g pm2

# 启动应用
pm2 start npm --name "geonote-api" -- start

# 查看状态
pm2 status

# 查看日志
pm2 logs geonote-api

# 设置开机自启
pm2 startup
pm2 save

# 重启应用
pm2 restart geonote-api

# 停止应用
pm2 stop geonote-api
```

#### 2. PM2 配置文件

创建 `ecosystem.config.js`：

```javascript
module.exports = {
  apps: [{
    name: 'geonote-api',
    script: './dist/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    max_memory_restart: '1G'
  }]
};
```

使用配置文件：

```bash
pm2 start ecosystem.config.js
```

#### 3. Nginx 反向代理

```nginx
upstream geonote_api {
    least_conn;
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
    server 127.0.0.1:3002;
}

server {
    listen 80;
    server_name api.geonote.com;
    
    location / {
        proxy_pass http://geonote_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

---

## 数据库配置 / Database Configuration

### PostgreSQL 设置

#### 1. 创建数据库和用户

```bash
# 切换到 postgres 用户
sudo -u postgres psql

# 创建数据库
CREATE DATABASE geonote;

# 创建用户
CREATE USER geonote_user WITH PASSWORD 'secure_password';

# 授予权限
GRANT ALL PRIVILEGES ON DATABASE geonote TO geonote_user;

# 启用 PostGIS 扩展
\c geonote
CREATE EXTENSION postgis;

# 退出
\q
```

#### 2. 数据库优化

编辑 `/etc/postgresql/14/main/postgresql.conf`：

```conf
# 内存设置
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 16MB

# 连接设置
max_connections = 100

# 日志设置
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
```

#### 3. 备份策略

```bash
# 每日备份脚本
#!/bin/bash
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="geonote_$DATE.sql.gz"

# 创建备份
pg_dump -U geonote_user geonote | gzip > "$BACKUP_DIR/$FILENAME"

# 保留最近 7 天的备份
find "$BACKUP_DIR" -name "geonote_*.sql.gz" -mtime +7 -delete
```

添加到 crontab：

```bash
# 每天凌晨 2 点备份
0 2 * * * /path/to/backup-script.sh
```

---

## CDN 配置 / CDN Configuration

### Cloudflare 配置

1. **添加站点到 Cloudflare**
2. **配置 DNS 记录**
3. **设置缓存规则**

```
路径: /assets/*
缓存级别: Standard
边缘缓存 TTL: 1 month
浏览器缓存 TTL: 1 year
```

4. **启用优化功能**
   - Auto Minify (JS, CSS, HTML)
   - Brotli 压缩
   - HTTP/3 (QUIC)

---

## 监控与日志 / Monitoring & Logging

### 应用监控

#### 1. 使用 PM2 Plus

```bash
# 连接到 PM2 Plus
pm2 link <secret_key> <public_key>
```

#### 2. 自定义监控

```javascript
// 健康检查端点
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});
```

### 日志管理

#### 1. Winston 配置

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ 
      filename: 'error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: 'combined.log' 
    })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}
```

#### 2. 日志轮转

使用 `logrotate` 管理日志文件：

```bash
# /etc/logrotate.d/geonote
/var/log/geonote/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 www-data www-data
    sharedscripts
    postrotate
        pm2 reloadLogs
    endscript
}
```

---

## 常见问题 / Troubleshooting

### Q: 构建失败

```bash
# 清除缓存重试
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Q: Nginx 502 Bad Gateway

```bash
# 检查后端服务是否运行
pm2 status

# 检查端口是否被占用
netstat -tlnp | grep 3000

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

### Q: 数据库连接失败

```bash
# 检查 PostgreSQL 状态
sudo systemctl status postgresql

# 测试连接
psql -U geonote_user -d geonote -h localhost

# 查看日志
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

---

## 性能优化清单 / Performance Checklist

- [ ] 启用 Gzip/Brotli 压缩
- [ ] 配置静态资源缓存
- [ ] 使用 CDN 加速
- [ ] 启用 HTTP/2 或 HTTP/3
- [ ] 数据库查询优化和索引
- [ ] 实现应用缓存（Redis）
- [ ] 代码分割和懒加载
- [ ] 图片优化和懒加载
- [ ] 启用服务端渲染（SSR）或静态生成（SSG）
- [ ] 配置负载均衡

---

## 安全清单 / Security Checklist

- [ ] 使用 HTTPS (SSL/TLS)
- [ ] 配置安全响应头
- [ ] 实施 CORS 策略
- [ ] SQL 注入防护
- [ ] XSS 防护
- [ ] CSRF 防护
- [ ] 限流和防 DDoS
- [ ] 定期更新依赖
- [ ] 环境变量安全管理
- [ ] 数据库访问控制

---

最后更新：2025-12-09
Last Updated: 2025-12-09
