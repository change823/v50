-- ============================================================================
-- Copywriting 表 RLS 策略优化脚本
-- 创建日期: 2026-02-02
-- 说明: 优化现有 RLS 策略，添加删除功能，改进权限控制
-- ============================================================================

-- 步骤 1: 删除所有现有策略
-- ============================================================================
DO $$ 
BEGIN
    -- 删除现有的 4 个策略
    DROP POLICY IF EXISTS "Anyone can read active copywriting" ON copywriting;
    DROP POLICY IF EXISTS "Anyone can insert pending copywriting" ON copywriting;
    DROP POLICY IF EXISTS "Only authenticated users can update copywriting" ON copywriting;
    DROP POLICY IF EXISTS "Authenticated users can read all copywriting" ON copywriting;
    
    RAISE NOTICE '✓ 已删除旧策略';
END $$;

-- 步骤 2: 确保 RLS 已启用
-- ============================================================================
ALTER TABLE copywriting ENABLE ROW LEVEL SECURITY;

-- 步骤 3: 创建优化后的策略
-- ============================================================================

-- 3.1 公开读取：任何人都可以读取已激活的文案
CREATE POLICY "public_read_active"
ON copywriting FOR SELECT
TO public
USING (status = 'active');

COMMENT ON POLICY "public_read_active" ON copywriting IS 
'允许未登录用户读取状态为 active 的文案（公开展示）';

-- 3.2 公开插入：任何人都可以提交待审核的文案
CREATE POLICY "public_insert_pending"
ON copywriting FOR INSERT
TO public
WITH CHECK (status = 'pending');

COMMENT ON POLICY "public_insert_pending" ON copywriting IS 
'允许任何人提交文案，但必须设置为 pending 状态（待审核）';

-- 3.3 已认证用户读取：可以读取所有状态的文案
CREATE POLICY "authenticated_read_all"
ON copywriting FOR SELECT
TO authenticated
USING (true);

COMMENT ON POLICY "authenticated_read_all" ON copywriting IS 
'允许已登录用户（管理员）读取所有状态的文案';

-- 3.4 已认证用户更新：可以审核文案（修改状态）
CREATE POLICY "authenticated_update"
ON copywriting FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (status IN ('active', 'pending', 'rejected'));

COMMENT ON POLICY "authenticated_update" ON copywriting IS 
'允许已登录用户更新文案，状态只能是 active/pending/rejected 之一';

-- 3.5 已认证用户删除：只能删除待审核的文案（防止误删已发布内容）
CREATE POLICY "authenticated_delete_pending"
ON copywriting FOR DELETE
TO authenticated
USING (status = 'pending');

COMMENT ON POLICY "authenticated_delete_pending" ON copywriting IS 
'允许已登录用户删除待审核文案，已发布的文案不能删除（防止误删）';

-- 步骤 4: 验证策略创建成功
-- ============================================================================
DO $$ 
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'copywriting';
    
    IF policy_count = 5 THEN
        RAISE NOTICE '✓ 成功创建 5 个新策略';
    ELSE
        RAISE WARNING '⚠ 预期 5 个策略，实际创建了 % 个', policy_count;
    END IF;
END $$;

-- 步骤 5: 显示当前策略列表
-- ============================================================================
SELECT 
    policyname AS "策略名称",
    cmd AS "操作类型",
    roles AS "应用角色",
    CASE 
        WHEN qual IS NOT NULL THEN LEFT(qual, 50) || '...'
        ELSE '(无限制)'
    END AS "USING条件",
    CASE 
        WHEN with_check IS NOT NULL THEN LEFT(with_check, 50) || '...'
        ELSE '(无限制)'
    END AS "CHECK条件"
FROM pg_policies
WHERE tablename = 'copywriting'
ORDER BY cmd, policyname;

-- ============================================================================
-- 完成！
-- ============================================================================
-- 
-- 📝 更改摘要:
-- 
-- ✅ 优化了策略角色配置（authenticated 策略直接应用到 authenticated 角色）
-- ✅ 添加了 DELETE 策略（只能删除 pending 状态的文案）
-- ✅ 改进了 UPDATE 策略（限制只能设置有效的状态值）
-- ✅ 添加了策略注释，便于后续维护
-- 
-- 🔍 建议测试项目:
-- 
-- 1. 未登录用户测试:
--    - 可以看到 active 文案 ✓
--    - 不能看到 pending 文案 ✓
--    - 可以提交新文案（自动 pending）✓
--    - 不能更新或删除任何文案 ✓
-- 
-- 2. 已登录用户测试:
--    - 可以看到所有状态的文案 ✓
--    - 可以审核文案（修改状态）✓
--    - 可以删除 pending 文案 ✓
--    - 不能删除 active 文案 ✓
-- 
-- ============================================================================
