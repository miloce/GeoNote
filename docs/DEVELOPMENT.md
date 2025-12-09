# 开发指南 / Development Guide

## 目录 / Table of Contents

- [环境准备](#环境准备)
- [项目设置](#项目设置)
- [开发工作流](#开发工作流)
- [代码规范](#代码规范)
- [测试指南](#测试指南)
- [调试技巧](#调试技巧)
- [常见问题](#常见问题)

---

## 环境准备 / Environment Setup

### 必需软件 / Required Software

1. **Node.js**
   - 版本：>= 16.0.0
   - 推荐使用 [nvm](https://github.com/nvm-sh/nvm) 管理版本
   
   ```bash
   # 安装 Node.js 18 (推荐)
   nvm install 18
   nvm use 18
   ```

2. **包管理器 / Package Manager**
   - npm (>= 8.0.0) - Node.js 自带
   - 或 yarn (>= 1.22.0)
   - 或 pnpm (>= 7.0.0)

3. **Git**
   - 版本：>= 2.30.0
   - [下载地址](https://git-scm.com/downloads)

4. **代码编辑器 / Code Editor**
   - 推荐：[Visual Studio Code](https://code.visualstudio.com/)
   - 必需扩展：
     - ESLint
     - Prettier
     - EditorConfig

### 可选工具 / Optional Tools

- **Docker** - 用于容器化开发
- **Postman** - API 测试
- **React DevTools** - React 调试
- **Redux DevTools** - 状态管理调试

---

## 项目设置 / Project Setup

### 1. 克隆仓库 / Clone Repository

```bash
git clone https://github.com/miloce/GeoNote.git
cd GeoNote
```

### 2. 安装依赖 / Install Dependencies

```bash
# 使用 npm
npm install

# 或使用 yarn
yarn install

# 或使用 pnpm
pnpm install
```

### 3. 配置环境变量 / Configure Environment Variables

复制环境变量模板并配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
# 开发服务器端口
VITE_PORT=5173

# API 地址
VITE_API_URL=http://localhost:3000

# 地图 API Key (根据使用的地图服务选择)
VITE_MAP_API_KEY=your_api_key_here

# Leaflet / OpenStreetMap (免费，无需 API Key)
VITE_MAP_PROVIDER=openstreetmap

# 或使用 Mapbox
# VITE_MAP_PROVIDER=mapbox
# VITE_MAPBOX_TOKEN=your_mapbox_token

# 或使用 Google Maps
# VITE_MAP_PROVIDER=google
# VITE_GOOGLE_MAPS_KEY=your_google_key

# 日志级别
VITE_LOG_LEVEL=debug

# 是否启用 Mock 数据
VITE_ENABLE_MOCK=true
```

### 4. 启动开发服务器 / Start Development Server

```bash
npm run dev
```

访问 http://localhost:5173

---

## 开发工作流 / Development Workflow

### 分支策略 / Branching Strategy

我们使用 Git Flow 工作流：

```
main (生产分支)
  └── develop (开发分支)
       ├── feature/xxx (功能分支)
       ├── fix/xxx (修复分支)
       └── hotfix/xxx (紧急修复分支)
```

### 创建新功能 / Creating New Feature

1. **从 develop 创建功能分支**

```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

2. **开发并提交**

```bash
# 进行开发...
git add .
git commit -m "feat: add amazing feature"
```

3. **保持分支更新**

```bash
git checkout develop
git pull origin develop
git checkout feature/your-feature-name
git merge develop
```

4. **推送并创建 PR**

```bash
git push origin feature/your-feature-name
```

### 提交信息规范 / Commit Message Convention

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型：**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链
- `perf`: 性能优化

**示例：**

```bash
feat(map): add custom marker icons

- Implemented custom icon system
- Added icon picker component
- Updated marker rendering logic

Closes #123
```

---

## 代码规范 / Code Standards

### ESLint 配置

项目使用 ESLint 进行代码检查：

```bash
# 运行 lint 检查
npm run lint

# 自动修复问题
npm run lint:fix
```

### Prettier 配置

使用 Prettier 保持代码格式一致：

```bash
# 格式化代码
npm run format

# 检查格式
npm run format:check
```

### TypeScript 规范

1. **类型定义**

```typescript
// ✅ 好的做法
interface Note {
  id: string;
  title: string;
  content: string;
  createdAt: Date;
}

// ❌ 避免
const note: any = {};
```

2. **函数类型**

```typescript
// ✅ 明确的函数签名
function createNote(data: NoteData): Promise<Note> {
  // ...
}

// ❌ 隐式 any
function createNote(data) {
  // ...
}
```

3. **组件 Props**

```typescript
// ✅ 定义 Props 接口
interface MapViewProps {
  center: Location;
  zoom: number;
  markers: Marker[];
  onMarkerClick?: (marker: Marker) => void;
}

const MapView: React.FC<MapViewProps> = ({ center, zoom }) => {
  // ...
};
```

### 命名规范

```typescript
// 组件 - PascalCase
const MapComponent = () => {};

// 函数 - camelCase
function getUserNotes() {}

// 常量 - UPPER_SNAKE_CASE
const API_BASE_URL = 'https://api.example.com';

// 接口 - PascalCase with 'I' prefix (可选)
interface IUserData {}
// 或不带前缀
interface UserData {}

// 类型 - PascalCase
type NoteStatus = 'draft' | 'published';

// 枚举 - PascalCase
enum NoteType {
  Text = 'text',
  Image = 'image',
  Video = 'video'
}
```

---

## 测试指南 / Testing Guide

### 运行测试

```bash
# 运行所有测试
npm run test

# 监听模式
npm run test:watch

# 生成覆盖率报告
npm run test:coverage

# 运行特定测试文件
npm run test -- path/to/test.spec.ts
```

### 测试类型

#### 1. 单元测试 (Unit Tests)

测试独立的函数和组件：

```typescript
// utils/formatDate.test.ts
import { formatDate } from './formatDate';

describe('formatDate', () => {
  it('should format date correctly', () => {
    const date = new Date('2025-12-09');
    expect(formatDate(date)).toBe('2025-12-09');
  });

  it('should handle invalid date', () => {
    expect(formatDate(null)).toBe('Invalid Date');
  });
});
```

#### 2. 组件测试 (Component Tests)

```typescript
// components/MapView.test.tsx
import { render, screen } from '@testing-library/react';
import { MapView } from './MapView';

describe('MapView', () => {
  it('should render map container', () => {
    render(<MapView center={{ lat: 0, lng: 0 }} zoom={10} />);
    expect(screen.getByTestId('map-container')).toBeInTheDocument();
  });
});
```

#### 3. 集成测试 (Integration Tests)

```typescript
// tests/note-creation.test.ts
describe('Note Creation Flow', () => {
  it('should create note with location', async () => {
    // Setup
    const noteData = {
      title: 'Test Note',
      location: { lat: 39.9042, lng: 116.4074 }
    };

    // Action
    const result = await createNote(noteData);

    // Assert
    expect(result.success).toBe(true);
    expect(result.data.id).toBeDefined();
  });
});
```

### 测试覆盖率目标

- 语句覆盖率：> 80%
- 分支覆盖率：> 75%
- 函数覆盖率：> 80%
- 行覆盖率：> 80%

---

## 调试技巧 / Debugging Tips

### VS Code 调试配置

创建 `.vscode/launch.json`：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "chrome",
      "request": "launch",
      "name": "Launch Chrome",
      "url": "http://localhost:5173",
      "webRoot": "${workspaceFolder}/src"
    }
  ]
}
```

### 浏览器 DevTools

1. **React DevTools**
   - 安装 React DevTools 扩展
   - 检查组件层次结构
   - 查看 Props 和 State

2. **Redux DevTools**
   - 监控 Action 和 State 变化
   - 时间旅行调试
   - 状态导入导出

3. **Console 调试**

```javascript
// 条件断点
console.log('Debug:', { variable });

// 性能标记
console.time('operationName');
// ... 操作
console.timeEnd('operationName');

// 表格展示
console.table(arrayOfObjects);
```

### 常用调试命令

```javascript
// 仅在开发环境打印
if (import.meta.env.DEV) {
  console.log('Development only log');
}

// 性能监控
performance.mark('start');
// ... 代码
performance.mark('end');
performance.measure('operation', 'start', 'end');
```

---

## 构建优化 / Build Optimization

### 生产构建

```bash
# 构建生产版本
npm run build

# 预览生产构建
npm run preview

# 分析打包大小
npm run build -- --mode analyze
```

### 性能优化技巧

1. **代码分割**

```typescript
// 路由懒加载
const MapView = lazy(() => import('./views/MapView'));
```

2. **图片优化**

```typescript
// 使用 WebP 格式
import imageWebP from './image.webp';
import imagePNG from './image.png';

<picture>
  <source srcSet={imageWebP} type="image/webp" />
  <img src={imagePNG} alt="..." />
</picture>
```

3. **Tree Shaking**

```typescript
// ✅ 具名导入
import { specificFunction } from 'library';

// ❌ 全量导入
import * as library from 'library';
```

---

## 常见问题 / FAQ

### Q: 如何添加新的依赖？

```bash
# 生产依赖
npm install package-name

# 开发依赖
npm install -D package-name
```

### Q: 如何解决端口冲突？

修改 `.env` 文件中的 `VITE_PORT` 或使用命令行参数：

```bash
npm run dev -- --port 3000
```

### Q: 如何清除缓存？

```bash
# 删除 node_modules 和 lock 文件
rm -rf node_modules package-lock.json

# 清除 npm 缓存
npm cache clean --force

# 重新安装
npm install
```

### Q: TypeScript 类型错误？

```bash
# 重新生成类型
npm run type-check
```

---

## 有用的资源 / Useful Resources

- [React 文档](https://react.dev/)
- [TypeScript 手册](https://www.typescriptlang.org/docs/)
- [Vite 指南](https://vitejs.dev/guide/)
- [Leaflet 教程](https://leafletjs.com/examples.html)
- [MDN Web 文档](https://developer.mozilla.org/)

---

## 获取帮助 / Getting Help

- 📚 查看 [文档](../README.md)
- 💬 在 [Discussions](https://github.com/miloce/GeoNote/discussions) 提问
- 🐛 报告 [Issue](https://github.com/miloce/GeoNote/issues)
- 📧 联系维护者：microne@qq.com

---

最后更新：2025-12-09
Last Updated: 2025-12-09
