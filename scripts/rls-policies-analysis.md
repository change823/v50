# Copywriting 表 RLS 策略分析

## 当前策略（2026-02-02）

### 1. Anyone can read active copywriting (SELECT)
- **角色**: `{public}`
- **USING**: `(status = 'active'::text)`
- **CHECK**: `NULL`
- **说明**: 任何人都可以读取已激活的文案

### 2. Anyone can insert pending copywriting (INSERT)
- **角色**: `{public}`
- **USING**: `NULL`
- **CHECK**: `(status = 'pending'::text)`
- **说明**: 任何人都可以提交文案，但必须为待审核状态

### 3. Only authenticated users can update copywriting (UPDATE)
- **角色**: `{public}`
- **USING**: `(auth.role() = 'authenticated'::text)`
- **CHECK**: `NULL`
- **说明**: 只有已认证用户可以更新文案

### 4. Authenticated users can read all copywriting (SELECT)
- **角色**: `{public}`
- **USING**: `(auth.role() = 'authenticated'::text)`
- **CHECK**: `NULL`
- **说明**: 已认证用户可以读取所有文案

---

## 问题和建议

### ⚠️ 问题 1：角色配置不规范
**现状**: 所有策略都应用于 `{public}` 角色，通过 `auth.role()` 函数来检查认证状态

**建议**: 将策略直接应用到正确的角色

```sql
-- 删除现有策略 3 和 4，重新创建为：

DROP POLICY "Only authenticated users can update copywriting" ON copywriting;
DROP POLICY "Authenticated users can read all copywriting" ON copywriting;

-- 重新创建，直接应用到 authenticated 角色
CREATE POLICY "Only authenticated users can update copywriting"
ON copywriting FOR UPDATE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can read all copywriting"
ON copywriting FOR SELECT
TO authenticated
USING (true);
```

### ⚠️ 问题 2：缺少 DELETE 策略
**现状**: 没有任何 DELETE 策略，无人可以删除记录

**建议**: 添加 DELETE 策略

```sql
-- 选项 1: 只允许已认证用户删除
CREATE POLICY "Only authenticated users can delete copywriting"
ON copywriting FOR DELETE
TO authenticated
USING (true);

-- 选项 2: 只允许删除待审核的文案（更安全）
CREATE POLICY "Only authenticated users can delete pending copywriting"
ON copywriting FOR DELETE
TO authenticated
USING (status = 'pending');
```

### ⚠️ 问题 3：UPDATE 权限过于宽松
**现状**: 已认证用户可以更新任何字段和状态

**建议**: 添加更细粒度的控制

```sql
-- 限制只能从 pending 改为 active（审核操作）
DROP POLICY "Only authenticated users can update copywriting" ON copywriting;

CREATE POLICY "Authenticated users can approve pending copywriting"
ON copywriting FOR UPDATE
TO authenticated
USING (status = 'pending')
WITH CHECK (status IN ('active', 'pending', 'rejected'));
```

### 💡 建议 4：添加软删除支持
考虑使用软删除而不是真实删除：

```sql
-- 添加 deleted_at 字段
ALTER TABLE copywriting ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 修改 SELECT 策略，排除已删除的记录
DROP POLICY "Anyone can read active copywriting" ON copywriting;
DROP POLICY "Authenticated users can read all copywriting" ON copywriting;

CREATE POLICY "Anyone can read active copywriting"
ON copywriting FOR SELECT
TO public
USING (status = 'active' AND deleted_at IS NULL);

CREATE POLICY "Authenticated users can read all copywriting"
ON copywriting FOR SELECT
TO authenticated
USING (deleted_at IS NULL);

-- UPDATE 策略：软删除
CREATE POLICY "Authenticated users can soft delete copywriting"
ON copywriting FOR UPDATE
TO authenticated
USING (deleted_at IS NULL)
WITH CHECK (deleted_at IS NOT NULL OR deleted_at IS NULL);
```

---

## 推荐的完整策略配置

```sql
-- 1. 确保 RLS 已启用
ALTER TABLE copywriting ENABLE ROW LEVEL SECURITY;

-- 2. 删除所有现有策略
DROP POLICY IF EXISTS "Anyone can read active copywriting" ON copywriting;
DROP POLICY IF EXISTS "Anyone can insert pending copywriting" ON copywriting;
DROP POLICY IF EXISTS "Only authenticated users can update copywriting" ON copywriting;
DROP POLICY IF EXISTS "Authenticated users can read all copywriting" ON copywriting;

-- 3. 创建新策略

-- 3.1 公开读取已激活的文案
CREATE POLICY "public_read_active"
ON copywriting FOR SELECT
TO public
USING (status = 'active');

-- 3.2 任何人可以提交待审核文案
CREATE POLICY "public_insert_pending"
ON copywriting FOR INSERT
TO public
WITH CHECK (status = 'pending');

-- 3.3 已认证用户可以读取所有文案
CREATE POLICY "authenticated_read_all"
ON copywriting FOR SELECT
TO authenticated
USING (true);

-- 3.4 已认证用户可以审核文案（更新状态）
CREATE POLICY "authenticated_update_status"
ON copywriting FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (status IN ('active', 'pending', 'rejected'));

-- 3.5 已认证用户可以删除待审核的文案
CREATE POLICY "authenticated_delete_pending"
ON copywriting FOR DELETE
TO authenticated
USING (status = 'pending');
```

---

## 测试清单

执行以上更改后，请测试：

- [ ] 未登录用户可以看到 active 文案
- [ ] 未登录用户不能看到 pending 文案
- [ ] 未登录用户可以提交新文案（自动 pending）
- [ ] 未登录用户不能更新或删除文案
- [ ] 已登录用户可以看到所有文案
- [ ] 已登录用户可以审核文案（改状态）
- [ ] 已登录用户可以删除 pending 文案
- [ ] 已登录用户不能删除 active 文案（如果使用建议 3.5）

---

## 相关文档

- [Supabase RLS 文档](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policy 文档](https://www.postgresql.org/docs/current/sql-createpolicy.html)
