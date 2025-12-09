# 贡献指南 / Contributing Guide

[English](#english) | [简体中文](#简体中文)

---

## 简体中文

感谢您考虑为 GeoNote 做出贡献！我们欢迎任何形式的贡献，无论是报告 Bug、提出新功能建议，还是提交代码。

### 行为准则

参与此项目即表示您同意遵守我们的行为准则。请尊重所有贡献者，营造友好、包容的社区环境。

### 如何贡献

#### 报告 Bug

如果您发现了 Bug，请通过 GitHub Issues 报告，并包含以下信息：

1. **Bug 描述**：清晰简洁地描述问题
2. **复现步骤**：详细说明如何复现该问题
3. **期望行为**：描述您期望的正确行为
4. **实际行为**：描述实际发生的情况
5. **环境信息**：
   - 操作系统和版本
   - 浏览器和版本
   - Node.js 版本
   - 项目版本
6. **截图**：如果适用，添加截图帮助说明问题
7. **额外信息**：任何可能有助于解决问题的其他信息

#### 建议新功能

我们欢迎新功能建议！请通过 GitHub Issues 提交，并说明：

1. **功能描述**：详细描述您建议的功能
2. **使用场景**：说明该功能的使用场景和价值
3. **替代方案**：您是否考虑过其他替代方案
4. **实现思路**：如果有想法，可以描述可能的实现方式

#### 提交代码

1. **Fork 仓库**
   ```bash
   # 在 GitHub 上点击 Fork 按钮创建您的副本
   # 然后克隆到本地（将 YOUR_USERNAME 替换为您的 GitHub 用户名）
   git clone https://github.com/YOUR_USERNAME/GeoNote.git
   cd GeoNote
   ```

2. **创建分支**
   ```bash
   # 为您的功能或修复创建新分支
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/your-bug-fix
   ```

3. **安装依赖**
   ```bash
   npm install
   ```

4. **进行更改**
   - 遵循项目的代码规范
   - 编写清晰的代码和注释
   - 确保代码通过所有测试
   - 添加必要的测试用例

5. **提交更改**
   ```bash
   # 暂存更改
   git add .
   
   # 提交更改（遵循 Conventional Commits 规范）
   git commit -m "feat: add amazing feature"
   ```

   提交信息格式：
   - `feat:` 新增功能
   - `fix:` 修复 Bug
   - `docs:` 文档更新
   - `style:` 代码格式调整（不影响功能）
   - `refactor:` 代码重构
   - `test:` 测试相关
   - `chore:` 构建流程或辅助工具变动
   - `perf:` 性能优化

6. **推送更改**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **创建 Pull Request**
   - 在 GitHub 上打开 Pull Request
   - 填写 PR 模板，详细描述您的更改
   - 链接相关的 Issue（如果有）
   - 等待代码审查

### 代码规范

#### 代码风格

- 使用 ESLint 和 Prettier 保持代码风格一致
- 运行 `npm run lint` 检查代码
- 运行 `npm run format` 格式化代码

#### 命名规范

- **变量和函数**：使用 camelCase（小驼峰）
  ```javascript
  const userName = 'John';
  function getUserInfo() {}
  ```

- **类和组件**：使用 PascalCase（大驼峰）
  ```javascript
  class UserProfile {}
  const MapComponent = () => {};
  ```

- **常量**：使用 UPPER_SNAKE_CASE（大写下划线）
  ```javascript
  const API_BASE_URL = 'https://api.example.com';
  const MAX_RETRY_COUNT = 3;
  ```

- **文件名**：
  - 组件文件：PascalCase，如 `MapView.jsx`
  - 工具文件：camelCase，如 `formatDate.js`
  - 常量文件：camelCase，如 `constants.js`

#### 注释规范

- 为复杂逻辑添加注释
- 使用 JSDoc 格式为函数添加文档注释
- 保持注释简洁明了

```javascript
/**
 * 计算两点之间的距离
 * @param {Object} point1 - 第一个点的坐标 {lat, lng}
 * @param {Object} point2 - 第二个点的坐标 {lat, lng}
 * @returns {number} 距离（单位：米）
 */
function calculateDistance(point1, point2) {
  // 实现逻辑...
}
```

### 测试

- 为新功能编写测试用例
- 确保所有测试通过：`npm run test`
- 保持测试覆盖率：`npm run test:coverage`

### 文档

- 更新相关文档以反映您的更改
- 如果添加新功能，请更新 README.md
- 为复杂功能编写详细的使用文档

### Pull Request 准则

一个好的 Pull Request 应该：

1. **专注于单一目标**：一个 PR 只解决一个问题或添加一个功能
2. **包含测试**：新功能和 Bug 修复都应包含测试
3. **更新文档**：如果更改影响用户使用，应更新文档
4. **清晰的描述**：说明为什么需要这个更改以及如何实现
5. **通过 CI 检查**：确保所有自动化检查通过
6. **代码审查**：积极响应审查意见，进行必要的修改

### 开发流程

1. **查看 Issues**：从 Issues 列表中选择要处理的问题
2. **讨论方案**：对于重大更改，先在 Issue 中讨论实现方案
3. **开发实现**：按照上述指南进行开发
4. **提交 PR**：创建 Pull Request 并等待审查
5. **代码审查**：根据反馈进行调整
6. **合并代码**：审查通过后，维护者会合并您的代码

### 需要帮助？

如果您在贡献过程中遇到任何问题：

- 查看 [Issues](https://github.com/miloce/GeoNote/issues)
- 在 Issue 中提问
- 联系维护者：microne@qq.com

### 贡献者列表

感谢所有为 GeoNote 做出贡献的人！

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

---

## English

Thank you for considering contributing to GeoNote! We welcome contributions of all kinds, whether it's reporting bugs, suggesting new features, or submitting code.

### Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful to all contributors and help us create a friendly and inclusive community.

### How to Contribute

#### Reporting Bugs

If you find a bug, please report it via GitHub Issues with the following information:

1. **Bug Description**: Clear and concise description of the issue
2. **Steps to Reproduce**: Detailed steps to reproduce the problem
3. **Expected Behavior**: Describe what you expected to happen
4. **Actual Behavior**: Describe what actually happened
5. **Environment**:
   - Operating system and version
   - Browser and version
   - Node.js version
   - Project version
6. **Screenshots**: If applicable, add screenshots to help explain
7. **Additional Context**: Any other information that might help

#### Suggesting Features

We welcome feature suggestions! Please submit via GitHub Issues and include:

1. **Feature Description**: Detailed description of your suggested feature
2. **Use Case**: Explain the use case and value of this feature
3. **Alternatives**: Have you considered any alternative solutions
4. **Implementation Ideas**: If you have ideas, describe possible implementation

#### Submitting Code

1. **Fork the Repository**
   ```bash
   # Fork the repository on GitHub
   # Then clone to your local machine
   git clone https://github.com/YOUR_USERNAME/GeoNote.git
   cd GeoNote
   ```

2. **Create a Branch**
   ```bash
   # Create a new branch for your feature or fix
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Install Dependencies**
   ```bash
   npm install
   ```

4. **Make Changes**
   - Follow the project's code style
   - Write clear code and comments
   - Ensure code passes all tests
   - Add necessary test cases

5. **Commit Changes**
   ```bash
   # Stage changes
   git add .
   
   # Commit changes (follow Conventional Commits)
   git commit -m "feat: add amazing feature"
   ```

   Commit message format:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation update
   - `style:` Code style changes (no functionality change)
   - `refactor:` Code refactoring
   - `test:` Test related
   - `chore:` Build process or tool changes
   - `perf:` Performance optimization

6. **Push Changes**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Open a Pull Request on GitHub
   - Fill in the PR template with detailed description
   - Link related Issues (if any)
   - Wait for code review

### Code Standards

#### Code Style

- Use ESLint and Prettier for consistent code style
- Run `npm run lint` to check code
- Run `npm run format` to format code

#### Naming Conventions

- **Variables and Functions**: Use camelCase
  ```javascript
  const userName = 'John';
  function getUserInfo() {}
  ```

- **Classes and Components**: Use PascalCase
  ```javascript
  class UserProfile {}
  const MapComponent = () => {};
  ```

- **Constants**: Use UPPER_SNAKE_CASE
  ```javascript
  const API_BASE_URL = 'https://api.example.com';
  const MAX_RETRY_COUNT = 3;
  ```

- **File Names**:
  - Component files: PascalCase, e.g., `MapView.jsx`
  - Utility files: camelCase, e.g., `formatDate.js`
  - Constant files: camelCase, e.g., `constants.js`

#### Comments

- Add comments for complex logic
- Use JSDoc format for function documentation
- Keep comments concise and clear

```javascript
/**
 * Calculate distance between two points
 * @param {Object} point1 - First point coordinates {lat, lng}
 * @param {Object} point2 - Second point coordinates {lat, lng}
 * @returns {number} Distance in meters
 */
function calculateDistance(point1, point2) {
  // Implementation...
}
```

### Testing

- Write test cases for new features
- Ensure all tests pass: `npm run test`
- Maintain test coverage: `npm run test:coverage`

### Documentation

- Update relevant documentation to reflect your changes
- If adding new features, update README.md
- Write detailed usage documentation for complex features

### Pull Request Guidelines

A good Pull Request should:

1. **Focus on Single Goal**: One PR should solve one problem or add one feature
2. **Include Tests**: New features and bug fixes should include tests
3. **Update Documentation**: If changes affect users, update documentation
4. **Clear Description**: Explain why this change is needed and how it's implemented
5. **Pass CI Checks**: Ensure all automated checks pass
6. **Code Review**: Actively respond to review comments and make necessary changes

### Development Workflow

1. **Check Issues**: Select an issue to work on from the Issues list
2. **Discuss Approach**: For major changes, discuss implementation in the Issue first
3. **Develop**: Follow the guidelines above for development
4. **Submit PR**: Create a Pull Request and wait for review
5. **Code Review**: Make adjustments based on feedback
6. **Merge**: After approval, maintainers will merge your code

### Need Help?

If you encounter any issues during contribution:

- Check [Issues](https://github.com/miloce/GeoNote/issues)
- Ask questions in Issues
- Contact maintainer: microne@qq.com

### Contributors

Thanks to all contributors to GeoNote!

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

---

<div align="center">

Made with ❤️ by the GeoNote community

</div>
