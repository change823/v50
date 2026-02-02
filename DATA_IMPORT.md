# 数据导入脚本使用指南

## 功能说明

`scripts/import-data.js` 是一个批量导入文案数据的脚本，可以从 `data.json` 文件中读取数据并批量插入到 Supabase 数据库。

## 准备工作

### 1. 安装依赖

```bash
npm install
```

确保安装了 `dotenv` 依赖，用于读取环境变量。

### 2. 配置环境变量

确保 `.env` 文件中已配置 Supabase 凭证：

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. 准备数据文件

在项目根目录创建 `data.json` 文件，格式参考 `data.example.json`。

## data.json 格式说明

### 方式 1: 对象数组（推荐）

```json
[
  {
    "content": "文案内容",
    "status": "pending"
  },
  {
    "content": "另一条文案\n支持换行符",
    "status": "active"
  }
]
```

**字段说明：**
- `content`: 文案内容（必填）
- `status`: 状态，可选值：`pending`（待审核）、`active`（已通过）、`rejected`（已拒绝）
  - 默认值：`pending`

### 方式 2: 字符串数组（简化）

```json
[
  "第一条文案",
  "第二条文案\n可以包含换行",
  "第三条文案"
]
```

字符串会自动转换为 `{ content: "...", status: "pending" }`

### 方式 3: 混合使用

```json
[
  "简单的文案",
  {
    "content": "需要直接设为通过的文案",
    "status": "active"
  },
  "又一条简单的文案"
]
```

## 使用方法

### 1. 运行导入脚本

```bash
npm run import
```

或者直接运行：

```bash
node scripts/import-data.js
```

### 2. 查看导入结果

脚本会输出导入进度和结果：

```
✅ 成功读取 data.json，共 100 条数据

🚀 开始导入数据...

✓ 第 1-100 条导入成功

==================================================
📊 导入完成！
   成功: 100 条
   失败: 0 条
   总计: 100 条
==================================================

✅ 数据导入任务完成
```

### 3. 在管理后台审核

导入完成后：

1. 登录管理后台
2. 切换到"待审核"标签
3. 查看并审核导入的文案
4. 将合适的文案改为"已通过"

## 注意事项

### 1. 数据格式

- JSON 文件必须是有效的 JSON 格式
- 建议使用 UTF-8 编码
- 换行符使用 `\n`（会自动转换为真实换行）

### 2. 批量处理

- 脚本每次批量插入 100 条数据
- 适合大量数据导入
- 如果部分批次失败，会继续处理后续批次

### 3. 状态控制

默认所有导入的数据状态为 `pending`，原因：

- **安全性**：避免未审核的内容直接展示给用户
- **质量控制**：管理员可以先审核再发布
- **灵活性**：可以在 JSON 中单独指定某条数据的状态

如果你有可信的数据源，可以在 JSON 中将 `status` 设为 `active`：

```json
[
  {
    "content": "已经审核过的文案",
    "status": "active"
  }
]
```

### 4. 数据去重

脚本不会自动去重，相同的文案会被重复插入。如需去重：

**方式 1：手动检查**
在导入前检查 data.json 中是否有重复内容。

**方式 2：数据库约束**
在 Supabase 中为 `content` 字段添加唯一约束：

```sql
ALTER TABLE copywriting ADD CONSTRAINT unique_content UNIQUE (content);
```

添加后，重复的文案会导入失败（但不影响其他数据）。

### 5. 错误处理

如果导入失败，检查：

1. `.env` 文件是否正确配置
2. Supabase 凭证是否有效
3. `data.json` 格式是否正确
4. 网络连接是否正常
5. Supabase RLS 策略是否允许插入

## 示例数据

### 示例 1：简单导入

```json
[
  "今天是疯狂星期四！",
  "V我50，请我吃肯德基！",
  "肯德基疯狂星期四，有人请客吗？"
]
```

### 示例 2：带换行的文案

```json
[
  {
    "content": "今天是星期四\n肯德基疯狂星期四\nV我50\n我请你吃\n开个玩笑\n其实是你请我",
    "status": "pending"
  }
]
```

### 示例 3：混合状态

```json
[
  {
    "content": "已审核通过的文案",
    "status": "active"
  },
  {
    "content": "待审核的文案",
    "status": "pending"
  },
  "默认待审核的文案"
]
```

## 常见问题

### Q1: 导入后看不到数据？

**A:** 默认导入状态为 `pending`，需要在管理后台审核后才会在首页显示。

### Q2: 如何批量设置为已通过？

**A:** 在 `data.json` 中将所有项的 `status` 设为 `active`：

```json
[
  { "content": "文案1", "status": "active" },
  { "content": "文案2", "status": "active" }
]
```

### Q3: 可以导入多少条数据？

**A:** 理论上无限制，但建议：
- 单次导入不超过 10000 条
- Supabase 免费版有存储和请求限制
- 大量数据可能需要较长时间

### Q4: 导入失败怎么办？

**A:** 检查错误信息：
- "读取 data.json 失败" → 检查文件路径和格式
- "环境变量未配置" → 检查 .env 文件
- "插入失败" → 检查 Supabase 连接和 RLS 策略

### Q5: 如何重新导入？

**A:**
1. 删除之前导入的数据（在管理后台或 Supabase Dashboard）
2. 修改 `data.json`
3. 重新运行 `npm run import`

## 高级用法

### 从其他来源导入

如果你的数据来自其他格式（如 CSV、Excel），可以先转换为 JSON：

**使用 Node.js 脚本：**

```javascript
import fs from 'fs'

// 假设你有一个数组
const rawData = [
  '文案1',
  '文案2',
  '文案3'
]

// 转换为 JSON 格式
const jsonData = rawData.map(content => ({
  content,
  status: 'pending'
}))

// 写入文件
fs.writeFileSync('data.json', JSON.stringify(jsonData, null, 2))
```

### 自定义导入逻辑

如果需要修改导入行为，编辑 `scripts/import-data.js`：

- 修改批量大小：`const batchSize = 100`
- 添加数据验证
- 添加去重逻辑
- 自定义状态映射

## 安全提示

⚠️ **重要：**

1. 不要将 `data.json` 提交到 Git（已添加到 `.gitignore`）
2. 导入前检查数据内容，避免恶意内容
3. 建议使用 `pending` 状态，人工审核后再发布
4. 定期备份 Supabase 数据库

## 相关命令

| 命令 | 说明 |
|------|------|
| `npm run import` | 导入数据 |
| `npm run dev` | 启动开发服务器 |
| `npm run build` | 构建生产版本 |

## 下一步

导入数据后：

1. 访问管理后台（参考 `ADMIN_SETUP.md`）
2. 登录管理员账号
3. 在"待审核"标签中查看导入的文案
4. 审核并通过合适的文案
5. 在首页查看已通过的文案
