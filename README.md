# 🍗 疯四文案 - 肯德基疯狂星期四文案生成器

一个基于 Vue 3 + Supabase 的轻量级 PWA 应用，用于展示和收集"肯德基疯狂星期四"搞笑文案。

## 技术栈

- **前端**: Vue 3 (Composition API) + Vite
- **UI**: Tailwind CSS
- **数据库**: Supabase
- **部署**: Cloudflare Pages
- **PWA**: vite-plugin-pwa

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置 Supabase

#### 创建数据库表

在 Supabase SQL Editor 中执行以下 SQL：

```sql
-- 创建 copywriting 表
CREATE TABLE copywriting (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引以提升查询性能
CREATE INDEX idx_copywriting_status ON copywriting(status);
CREATE INDEX idx_copywriting_created_at ON copywriting(created_at DESC);
```

#### 配置 Row Level Security (RLS) 策略

```sql
-- 启用 RLS
ALTER TABLE copywriting ENABLE ROW LEVEL SECURITY;

-- 1. 允许所有人读取 status = 'active' 的文案（首页展示）
CREATE POLICY "Anyone can read active copywriting"
ON copywriting
FOR SELECT
USING (status = 'active');

-- 2. 允许所有人插入新文案（投稿功能）
CREATE POLICY "Anyone can insert pending copywriting"
ON copywriting
FOR INSERT
WITH CHECK (status = 'pending');

-- 3. 只有认证用户可以更新文案状态（管理员审核）
-- 注意：你需要先在 Supabase Auth 中创建管理员账号
CREATE POLICY "Only authenticated users can update copywriting"
ON copywriting
FOR UPDATE
USING (auth.role() = 'authenticated');

-- 4. 只有认证用户可以查看所有文案（管理后台）
CREATE POLICY "Authenticated users can read all copywriting"
ON copywriting
FOR SELECT
USING (auth.role() = 'authenticated');
```

### 3. 设置环境变量

复制 `.env.example` 为 `.env`：

```bash
cp .env.example .env
```

在 `.env` 中填入你的 Supabase 配置：

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

> 你可以在 Supabase 项目设置 → API 中找到这些值

### 4. 运行开发服务器

```bash
npm run dev
```

### 5. 构建生产版本

```bash
npm run build
```

## 部署到 Cloudflare Pages

### 方法 1: 通过 Git 集成（推荐）

1. 将代码推送到 GitHub
2. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
3. 进入 Pages → Create a project
4. 连接你的 GitHub 仓库
5. 配置构建设置：
   - **构建命令**: `npm run build`
   - **构建输出目录**: `dist`
   - **环境变量**: 添加 `VITE_SUPABASE_URL` 和 `VITE_SUPABASE_ANON_KEY`
6. 点击 Save and Deploy

### 方法 2: 使用 Wrangler CLI

```bash
npm install -g wrangler
wrangler pages publish dist
```

## 功能特性

- ✅ 随机展示审核通过的文案
- ✅ 一键复制到剪贴板
- ✅ 用户投稿功能
- ✅ PWA 支持（可安装到主屏幕）
- ✅ 响应式设计（移动端友好）
- ✅ Toast 消息提示

## 项目结构

```
v50/
├── public/                 # 静态资源
├── src/
│   ├── components/
│   │   ├── HomePage.vue    # 首页组件
│   │   ├── SubmitModal.vue # 投稿弹窗
│   │   └── Toast.vue       # Toast 提示组件
│   ├── App.vue             # 根组件
│   ├── main.js             # 应用入口
│   ├── style.css           # 全局样式
│   └── supabase.js         # Supabase 客户端配置
├── index.html
├── vite.config.js          # Vite 配置（含 PWA）
├── tailwind.config.js      # Tailwind CSS 配置
└── package.json
```

## 管理后台（TODO）

目前项目只实现了用户端功能。管理员可以通过以下方式审核文案：

### 临时方案：直接在 Supabase Dashboard 操作

1. 登录 Supabase Dashboard
2. 进入 Table Editor → copywriting
3. 查看 `status = 'pending'` 的记录
4. 手动将 `status` 改为 `active`（通过）或 `rejected`（拒绝）

### 未来增强

可以添加一个管理后台页面：
- 登录功能（Supabase Auth）
- 待审核文案列表
- 批量审核操作
- 文案统计数据

## RLS 安全说明

当前 RLS 策略：
- 普通用户：只能看到 `active` 状态的文案，可以投稿（插入 `pending` 记录）
- 认证用户（管理员）：可以查看所有文案，可以更新文案状态

**注意**：`VITE_SUPABASE_ANON_KEY` 是公开的，所有安全策略依赖 RLS。请勿在客户端代码中使用 `service_role` key。

## License

MIT
