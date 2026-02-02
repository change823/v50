# RLS 策略优化指南

## 📁 文件说明

本目录包含 3 个 SQL 脚本文件：

1. **`check-rls-policies.sql`** - 查询当前 RLS 策略
2. **`optimize-rls-policies.sql`** - 基础优化版本（推荐）
3. **`optimize-rls-policies-with-soft-delete.sql`** - 高级版本（含软删除）

## 🎯 选择哪个版本？

### 方案 A：基础优化版本（推荐大多数用户）

**文件**: `optimize-rls-policies.sql`

**优点**:
- ✅ 简单易懂，维护成本低
- ✅ 直接删除不需要的数据
- ✅ 数据库占用空间小
- ✅ 不需要修改前端代码

**适用场景**:
- 小型项目
- 文案数据不是特别重要
- 不需要恢复已删除的数据
- 数据量不大

**功能**:
- 优化角色配置（使用 `authenticated` 角色）
- 添加 DELETE 策略（只能删除 pending 状态）
- 限制 UPDATE 操作的状态值
- 管理员可以直接删除待审核文案

---

### 方案 B：高级版本（软删除）

**文件**: `optimize-rls-policies-with-soft-delete.sql`

**优点**:
- ✅ 数据可恢复，防止误删
- ✅ 保留删除记录用于审计
- ✅ 支持定期自动清理旧数据
- ✅ 更安全的删除机制

**缺点**:
- ⚠️ 需要修改前端代码（调用软删除函数）
- ⚠️ 数据库占用空间稍大
- ⚠️ 查询时需要过滤 deleted_at

**适用场景**:
- 生产环境
- 需要数据审计功能
- 文案数据比较重要
- 需要防止误删

**新增功能**:
- 所有基础版本的功能
- 添加 `deleted_at` 字段
- 软删除/恢复/永久删除函数
- 便捷查询视图（active_copywriting, pending_copywriting, deleted_copywriting）
- 自动清理超过 90 天的删除记录

---

## 🚀 执行步骤

### 步骤 1：备份数据（重要！）

在执行任何操作前，先备份您的数据：

```sql
-- 在 Supabase SQL Editor 中执行
CREATE TABLE copywriting_backup AS
SELECT * FROM copywriting;
```

### 步骤 2：选择并执行脚本

#### 选项 A：基础优化版本

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 进入您的项目 → **SQL Editor**
3. 复制 `optimize-rls-policies.sql` 的全部内容
4. 粘贴并点击 **Run**
5. 检查输出信息确认成功

#### 选项 B：高级版本（软删除）

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 进入您的项目 → **SQL Editor**
3. 复制 `optimize-rls-policies-with-soft-delete.sql` 的全部内容
4. 粘贴并点击 **Run**
5. 检查输出信息确认成功

### 步骤 3：验证策略

执行查询确认策略已正确创建：

```sql
SELECT 
  policyname AS "策略名称",
  cmd AS "操作",
  roles AS "角色",
  CASE 
    WHEN qual IS NOT NULL THEN LEFT(qual, 80)
    ELSE '(无限制)'
  END AS "USING条件",
  CASE 
    WHEN with_check IS NOT NULL THEN LEFT(with_check, 80)
    ELSE '(无限制)'
  END AS "CHECK条件"
FROM pg_policies
WHERE tablename = 'copywriting'
ORDER BY cmd, policyname;
```

---

## 🔧 前端代码修改（仅高级版本需要）

如果您选择了高级版本（软删除），需要修改 `AdminPanel.vue` 中的删除逻辑：

### 当前代码（物理删除）:

```javascript
async deleteCopywriting(id) {
  const { error } = await supabase
    .from('copywriting')
    .delete()
    .eq('id', id)
  
  if (error) {
    console.error('删除失败:', error)
    return
  }
  
  // 刷新列表
  await this.fetchCopywriting()
}
```

### 修改为（软删除）:

```javascript
async deleteCopywriting(id) {
  // 调用软删除函数
  const { data, error } = await supabase
    .rpc('soft_delete_copywriting', { copywriting_id: id })
  
  if (error) {
    console.error('软删除失败:', error)
    return
  }
  
  if (data) {
    console.log('软删除成功')
    // 刷新列表
    await this.fetchCopywriting()
  } else {
    console.error('文案不存在或已被删除')
  }
}

// 新增：恢复功能
async restoreCopywriting(id) {
  const { data, error } = await supabase
    .rpc('restore_copywriting', { copywriting_id: id })
  
  if (error) {
    console.error('恢复失败:', error)
    return
  }
  
  if (data) {
    console.log('恢复成功')
    await this.fetchCopywriting()
  }
}

// 新增：查看已删除文案
async fetchDeletedCopywriting() {
  const { data, error } = await supabase
    .from('deleted_copywriting')
    .select('*')
    .order('deleted_at', { ascending: false })
  
  if (error) {
    console.error('查询失败:', error)
    return []
  }
  
  return data
}
```

---

## 📊 测试清单

执行脚本后，请测试以下功能：

### 未登录用户测试

- [ ] 打开首页，只能看到 `status = 'active'` 的文案
- [ ] 提交新文案，确认能成功提交
- [ ] 检查新提交的文案状态为 `pending`
- [ ] 确认看不到待审核的文案
- [ ] 确认无法直接访问管理面板

### 已登录用户测试

- [ ] 登录管理面板
- [ ] 可以看到所有状态（active + pending）的文案
- [ ] 可以审核文案（pending → active）
- [ ] 可以拒绝文案（pending → rejected）
- [ ] 可以删除 pending 状态的文案 ✓
- [ ] 不能删除 active 状态的文案（基础版）

### 软删除功能测试（仅高级版本）

- [ ] 删除文案后，前端列表中消失
- [ ] 数据库中 `deleted_at` 字段有值
- [ ] 可以查看已删除的文案列表
- [ ] 可以恢复已删除的文案
- [ ] 恢复后 `deleted_at` 变为 NULL

---

## 🛠️ 常见问题

### Q1: 执行脚本后报错 "permission denied"

**原因**: 您当前使用的数据库用户没有足够权限

**解决方案**: 
- 使用 Supabase Dashboard 的 SQL Editor（推荐）
- 或使用具有 `postgres` 角色权限的用户

### Q2: 前端无法删除文案

**可能原因**:
1. 用户未登录（检查认证状态）
2. 尝试删除 `active` 状态的文案（基础版只能删除 pending）
3. RLS 策略未正确应用

**排查步骤**:
```javascript
// 在浏览器控制台检查
const { data: { user } } = await supabase.auth.getUser()
console.log('当前用户:', user) // 应该有值

// 检查删除错误
const { error } = await supabase
  .from('copywriting')
  .delete()
  .eq('id', 'xxx')
console.log('删除错误:', error) // 查看具体错误信息
```

### Q3: 想要回滚到旧策略

```sql
-- 恢复备份（如果创建了）
DROP TABLE copywriting;
ALTER TABLE copywriting_backup RENAME TO copywriting;

-- 或手动删除新策略
DROP POLICY IF EXISTS "public_read_active" ON copywriting;
DROP POLICY IF EXISTS "public_insert_pending" ON copywriting;
DROP POLICY IF EXISTS "authenticated_read_all" ON copywriting;
DROP POLICY IF EXISTS "authenticated_update" ON copywriting;
DROP POLICY IF EXISTS "authenticated_delete_pending" ON copywriting;

-- 然后重新创建旧策略...
```

---

## 📚 相关资源

- [Supabase RLS 官方文档](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policy 文档](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [项目管理面板文档](../ADMIN_SETUP.md)

---

## 💡 建议

1. **生产环境**: 建议使用高级版本（软删除），更安全
2. **开发/测试**: 可以先用基础版本，简单快速
3. **定期清理**: 如果使用软删除，建议每月执行一次清理：
   ```sql
   SELECT permanently_delete_old_copywriting(90); -- 删除 90 天前的记录
   ```
4. **监控**: 定期检查 RLS 策略是否正常工作
5. **备份**: 重要操作前务必备份数据

---

## ✅ 推荐方案

**对于您的项目，我推荐使用「基础优化版本」**，理由：

1. ✅ 当前是简单的文案展示项目
2. ✅ 不需要复杂的数据恢复功能
3. ✅ 维护成本低，不需要修改前端代码
4. ✅ 只删除 pending 文案，active 文案受保护

如果未来需要更高级的功能，随时可以升级到软删除版本。

---

**需要帮助？** 如有问题，请参考项目文档或联系开发者。
