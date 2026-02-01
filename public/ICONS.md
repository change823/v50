# PWA 图标说明

为了完整支持 PWA 功能，你需要在 `public/` 目录下添加以下图标文件：

## 必需的图标文件

1. **favicon.ico** (32x32)
   - 网站图标

2. **icon-192.png** (192x192)
   - PWA 小图标

3. **icon-512.png** (512x512)
   - PWA 大图标

4. **apple-touch-icon.png** (180x180，可选)
   - iOS 设备添加到主屏幕时使用

## 生成图标的方法

### 方法 1: 使用在线工具

访问 [Favicon Generator](https://realfavicongenerator.net/) 或 [PWA Asset Generator](https://www.pwabuilder.com/imageGenerator)

1. 上传一个 512x512 的源图片（建议使用肯德基红色主题）
2. 工具会自动生成所有需要的尺寸
3. 下载并放入 `public/` 目录

### 方法 2: 使用 Figma/Sketch/PS

创建一个 512x512 的设计：
- 背景色: #E4002B (肯德基红)
- 文字: "疯四" 或 "🍗"
- 导出为 PNG
- 使用工具缩放到不同尺寸

### 方法 3: 使用 CLI 工具

```bash
npm install -g pwa-asset-generator
pwa-asset-generator source-image.png public/ --icon-only
```

## 临时方案

如果暂时没有图标，可以先创建简单的纯色图标：

```bash
# macOS/Linux
convert -size 192x192 xc:#E4002B public/icon-192.png
convert -size 512x512 xc:#E4002B public/icon-512.png
```

或者使用 https://placeholder.com/ 生成占位符：
- https://via.placeholder.com/192/E4002B/FFFFFF?text=疯四
- https://via.placeholder.com/512/E4002B/FFFFFF?text=疯四
