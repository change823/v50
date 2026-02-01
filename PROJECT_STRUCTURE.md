# 项目结构

```
v50/
├── public/                          # 静态资源目录
│   └── ICONS.md                     # PWA 图标说明文档
│
├── src/                             # 源代码目录
│   ├── components/                  # Vue 组件
│   │   ├── AdminPanel.vue           # 管理后台组件（可选）
│   │   ├── HomePage.vue             # 首页组件
│   │   ├── SubmitModal.vue          # 投稿弹窗组件
│   │   └── Toast.vue                # Toast 提示组件
│   ├── App.vue                      # 根组件
│   ├── main.js                      # 应用入口
│   ├── style.css                    # 全局样式（Tailwind）
│   └── supabase.js                  # Supabase 客户端配置
│
├── .env.example                     # 环境变量模板
├── .gitignore                       # Git 忽略文件
├── ADMIN_SETUP.md                   # 管理后台设置指南
├── CHECKLIST.md                     # 项目启动清单
├── DEPLOYMENT.md                    # Cloudflare Pages 部署指南
├── README.md                        # 项目说明文档
├── index.html                       # HTML 入口文件
├── package.json                     # NPM 依赖配置
├── postcss.config.js                # PostCSS 配置
├── supabase-init.sql                # Supabase 数据库初始化脚本
├── tailwind.config.js               # Tailwind CSS 配置
└── vite.config.js                   # Vite 配置（含 PWA）
```

## 核心文件说明

### 配置文件

| 文件 | 说明 |
|------|------|
| `vite.config.js` | Vite 构建配置，包含 PWA 插件设置 |
| `tailwind.config.js` | Tailwind CSS 配置，定义主题颜色等 |
| `postcss.config.js` | PostCSS 配置，用于 Tailwind 编译 |
| `package.json` | 项目依赖和脚本定义 |
| `.env.example` | 环境变量模板，需复制为 `.env` 并填写实际值 |

### 源代码文件

| 文件 | 说明 |
|------|------|
| `src/main.js` | 应用入口，挂载 Vue 应用 |
| `src/App.vue` | 根组件，包含布局和路由逻辑 |
| `src/supabase.js` | Supabase 客户端初始化 |
| `src/style.css` | Tailwind CSS 导入和全局样式 |

### 组件文件

| 文件 | 说明 |
|------|------|
| `HomePage.vue` | 首页组件：显示随机文案、换一句、复制功能 |
| `SubmitModal.vue` | 投稿弹窗：用户提交新文案 |
| `Toast.vue` | Toast 提示：通用消息提示组件 |
| `AdminPanel.vue` | 管理后台：审核文案（可选，需配置路由） |

### 文档文件

| 文件 | 说明 |
|------|------|
| `README.md` | 项目概述、技术栈、快速开始指南 |
| `CHECKLIST.md` | 项目启动清单，逐步完成部署 |
| `DEPLOYMENT.md` | Cloudflare Pages 详细部署指南 |
| `ADMIN_SETUP.md` | 管理后台添加指南（可选功能） |
| `public/ICONS.md` | PWA 图标准备说明 |
| `supabase-init.sql` | Supabase 数据库初始化 SQL 脚本 |

## 部署后的目录结构

运行 `npm run build` 后会生成：

```
dist/
├── assets/
│   ├── index-[hash].css       # 编译后的 CSS
│   └── index-[hash].js        # 编译后的 JS
├── manifest.webmanifest       # PWA manifest
├── sw.js                      # Service Worker
├── workbox-[hash].js          # Workbox 运行时
├── index.html                 # 入口 HTML
└── [静态资源文件]
```

`dist/` 目录的内容会被部署到 Cloudflare Pages。

## 添加新功能

### 添加新组件

1. 在 `src/components/` 下创建 `.vue` 文件
2. 在需要使用的地方导入：`import MyComponent from './components/MyComponent.vue'`

### 添加新样式

- **全局样式**：在 `src/style.css` 中添加
- **组件样式**：在组件的 `<style>` 标签中添加
- **Tailwind 工具类**：直接在模板中使用

### 添加新路由（可选）

如果需要多页面应用：

1. 安装 `vue-router`
2. 创建 `src/router.js`
3. 在 `src/main.js` 中使用路由
4. 参考 `ADMIN_SETUP.md` 中的路由配置

## 依赖说明

### 生产依赖

- `vue`: Vue 3 框架
- `@supabase/supabase-js`: Supabase 客户端库

### 开发依赖

- `vite`: 构建工具
- `@vitejs/plugin-vue`: Vite 的 Vue 插件
- `tailwindcss`: CSS 框架
- `autoprefixer`: CSS 自动添加浏览器前缀
- `postcss`: CSS 处理工具
- `vite-plugin-pwa`: PWA 插件

## 环境变量

| 变量名 | 说明 | 是否必需 |
|--------|------|----------|
| `VITE_SUPABASE_URL` | Supabase 项目 URL | 是 |
| `VITE_SUPABASE_ANON_KEY` | Supabase 匿名密钥 | 是 |

> 所有以 `VITE_` 开头的环境变量会在构建时被注入到客户端代码中。

## Git 版本控制

已配置 `.gitignore` 忽略：

- `node_modules/`
- `dist/`
- `.env`
- `.env.local`
- IDE 配置文件
- 系统文件（.DS_Store 等）

## 下一步

1. 按照 `CHECKLIST.md` 完成项目设置
2. 参考 `README.md` 了解技术细节
3. 使用 `DEPLOYMENT.md` 部署到 Cloudflare Pages
4. （可选）根据 `ADMIN_SETUP.md` 添加管理后台
