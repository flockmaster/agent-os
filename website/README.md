# Antigravity Agent OS 官网

## 🎨 设计特性

- **现代科技感界面**：深色主题 + 霓虹色渐变
- **酷炫动画效果**：
  - 星空粒子背景动画
  - 3D 大脑神经网络动画
  - Hero 文字 Glitch 故障效果
  - 卡片悬浮和 3D 旋转
  - 平滑滚动和渐入动画
  - 终端命令逐行显示
  - 鼠标跟随光效
  
- **响应式设计**：支持桌面、平板、手机
- **交互体验**：
  - 代码一键复制
  - 标签页切换
  - 导航栏滚动变化
  - 元素进入视口动画

## 🚀 快速预览

### 方式 1：直接打开
双击 `index.html` 文件在浏览器中打开

### 方式 2：本地服务器（推荐）
```bash
# 使用 Python 启动简单服务器
python -m http.server 8000

# 或使用 Node.js
npx serve .

# 或使用 PHP
php -S localhost:8000
```

然后访问 `http://localhost:8000`

## 📁 文件结构

```
website/
├── index.html      # 主页面
├── style.css       # 样式表（包含所有动画效果）
├── script.js       # JavaScript 交互逻辑
└── README.md       # 本文档
```

## 🎯 功能亮点

### 1. Hero Section
- 大标题 Glitch 故障艺术效果
- 3D 旋转的大脑神经网络动画
- 多轨道绕行的节点
- 脉冲呼吸效果

### 2. Pain Points 展示
- 火焰强度可视化
- 悬浮卡片效果
- 光晕特效

### 3. Features 展示
- 4 个核心功能模块
- 3D 翻转卡片
- 动态光效

### 4. Architecture 架构图
- 分层展示系统架构
- 箭头动画
- 悬浮交互

### 5. Demo 终端
- 模拟真实终端界面
- 逐行显示命令输出
- 光标闪烁效果

### 6. Installation
- 多平台安装指南
- Tab 切换
- 一键复制代码

## 🎨 自定义配置

### 修改配色
编辑 `style.css` 中的 CSS 变量：

```css
:root {
    --primary-color: #ff6b35;      /* 主色调 */
    --secondary-color: #7c3aed;    /* 次要色 */
    --success-color: #10b981;      /* 成功色 */
    /* ... */
}
```

### 修改粒子数量
编辑 `script.js`：

```javascript
const particleCount = 50;  // 调整粒子数量
```

### 禁用鼠标光效
在 `script.js` 中注释掉鼠标跟随代码：

```javascript
// document.addEventListener('mousemove', (e) => { ... });
```

## 🐛 彩蛋

尝试输入 Konami Code：`↑ ↑ ↓ ↓ ← → ← → B A`

## 📝 TODO

- [ ] 添加移动端导航菜单
- [ ] 添加更多交互动画
- [ ] 集成实际数据统计
- [ ] 添加暗黑/明亮主题切换
- [ ] 添加多语言支持
- [ ] 性能优化（懒加载、预加载）

## 📄 License

MIT License
