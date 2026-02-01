# Cloudflare Pages 部署指南

## 部署配置

### 构建设置

- **框架预设**: `Vue`
- **构建命令**: `npm run build`
- **构建输出目录**: `dist`
- **Node 版本**: 18 或更高

### 环境变量

在 Cloudflare Pages 项目设置中添加以下环境变量：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `VITE_SUPABASE_URL` | Supabase 项目 URL | `https://xxxxx.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | Supabase 匿名密钥 | `eyJhbGci...` |

> 注意：Cloudflare Pages 会自动识别 `VITE_` 前缀的环境变量

## 部署步骤

### 方式 1: Git 集成（推荐）

1. 将代码推送到 GitHub/GitLab
2. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
3. 进入 **Pages** → **Create a project**
4. 选择 **Connect to Git**
5. 授权并选择仓库
6. 配置构建设置（见上方）
7. 添加环境变量
8. 点击 **Save and Deploy**

每次推送到主分支，Cloudflare 会自动重新部署。

### 方式 2: Wrangler CLI

```bash
# 安装 Wrangler
npm install -g wrangler

# 登录 Cloudflare
wrangler login

# 构建项目
npm run build

# 部署到 Pages
wrangler pages deploy dist --project-name=crazy-thursday
```

### 方式 3: 拖拽部署

1. 本地执行 `npm run build`
2. 登录 Cloudflare Dashboard
3. 进入 Pages → Create a project → Upload assets
4. 拖拽 `dist` 文件夹

> 注意：这种方式无法配置环境变量，需要在部署前手动修改代码中的 Supabase 配置

## 自定义域名

1. 在 Cloudflare Pages 项目中，进入 **Custom domains**
2. 点击 **Set up a custom domain**
3. 输入你的域名（如 `crazy-thursday.example.com`）
4. 按照提示配置 DNS 记录
5. 等待 SSL 证书自动签发（通常几分钟内完成）

## PWA 测试

部署完成后，测试 PWA 功能：

1. 在 Chrome/Edge 中打开网站
2. 按 F12 打开开发者工具
3. 进入 **Application** 标签
4. 检查：
   - ✅ Manifest 已加载
   - ✅ Service Worker 已注册
   - ✅ 可以离线访问
5. 点击地址栏右侧的"安装"图标测试安装

在移动设备上：
1. 使用 Chrome/Safari 打开网站
2. 点击"添加到主屏幕"
3. 应用图标会出现在主屏幕上

## 性能优化建议

### 缓存策略

Cloudflare Pages 自动提供：
- 静态资源 CDN 缓存
- Brotli/Gzip 压缩
- HTTP/2 支持

### 进一步优化

在 `vite.config.js` 中：

```javascript
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vue': ['vue'],
          'supabase': ['@supabase/supabase-js']
        }
      }
    }
  }
})
```

## 常见问题

### 部署后环境变量不生效

- 确认变量名以 `VITE_` 开头
- 在 Cloudflare Pages 设置中检查环境变量
- 重新部署项目（环境变量修改后需要重新构建）

### Service Worker 没有更新

- 清除浏览器缓存
- 在开发者工具中 Unregister Service Worker
- 刷新页面

### PWA 无法安装

- 检查是否使用 HTTPS（Cloudflare Pages 自动提供）
- 确认 manifest.json 正确加载
- 查看浏览器控制台错误信息

## 监控和分析

Cloudflare Pages 提供：
- 部署历史
- 构建日志
- 流量分析（通过 Cloudflare Analytics）

建议集成：
- Google Analytics
- Sentry（错误追踪）
- Umami（轻量级分析）
