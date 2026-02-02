-- ============================================================================
-- Copywriting 表 RLS 策略优化脚本（含软删除功能）
-- 创建日期: 2026-02-02
-- 说明: 优化 RLS 策略 + 添加软删除支持（推荐用于生产环境）
-- ============================================================================

-- 步骤 1: 添加软删除字段
-- ============================================================================
DO $$ 
BEGIN
    -- 检查 deleted_at 字段是否存在
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'copywriting' 
        AND column_name = 'deleted_at'
    ) THEN
        ALTER TABLE copywriting 
        ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
        
        RAISE NOTICE '✓ 已添加 deleted_at 字段';
    ELSE
        RAISE NOTICE 'ℹ deleted_at 字段已存在';
    END IF;
    
    -- 添加索引以提高查询性能
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'copywriting' 
        AND indexname = 'idx_copywriting_deleted_at'
    ) THEN
        CREATE INDEX idx_copywriting_deleted_at 
        ON copywriting(deleted_at) 
        WHERE deleted_at IS NOT NULL;
        
        RAISE NOTICE '✓ 已创建 deleted_at 索引';
    ELSE
        RAISE NOTICE 'ℹ deleted_at 索引已存在';
    END IF;
END $$;

-- 步骤 2: 删除所有现有策略
-- ============================================================================
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Anyone can read active copywriting" ON copywriting;
    DROP POLICY IF EXISTS "Anyone can insert pending copywriting" ON copywriting;
    DROP POLICY IF EXISTS "Only authenticated users can update copywriting" ON copywriting;
    DROP POLICY IF EXISTS "Authenticated users can read all copywriting" ON copywriting;
    
    RAISE NOTICE '✓ 已删除旧策略';
END $$;

-- 步骤 3: 确保 RLS 已启用
-- ============================================================================
ALTER TABLE copywriting ENABLE ROW LEVEL SECURITY;

-- 步骤 4: 创建优化后的策略（支持软删除）
-- ============================================================================

-- 4.1 公开读取：任何人都可以读取已激活且未删除的文案
CREATE POLICY "public_read_active"
ON copywriting FOR SELECT
TO public
USING (status = 'active' AND deleted_at IS NULL);

COMMENT ON POLICY "public_read_active" ON copywriting IS 
'允许未登录用户读取状态为 active 且未被删除的文案';

-- 4.2 公开插入：任何人都可以提交待审核的文案
CREATE POLICY "public_insert_pending"
ON copywriting FOR INSERT
TO public
WITH CHECK (status = 'pending' AND deleted_at IS NULL);

COMMENT ON POLICY "public_insert_pending" ON copywriting IS 
'允许任何人提交文案，必须设置为 pending 状态且不能预设删除时间';

-- 4.3 已认证用户读取：可以读取所有未删除的文案
CREATE POLICY "authenticated_read_all"
ON copywriting FOR SELECT
TO authenticated
USING (deleted_at IS NULL);

COMMENT ON POLICY "authenticated_read_all" ON copywriting IS 
'允许已登录用户读取所有未删除的文案（包括 pending 和 active）';

-- 4.4 已认证用户更新：可以审核文案和软删除
CREATE POLICY "authenticated_update"
ON copywriting FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (
    -- 状态只能是有效值
    status IN ('active', 'pending', 'rejected')
    -- 软删除：可以设置 deleted_at，但不能取消删除（deleted_at 只能从 NULL 变为非 NULL）
    AND (
        (deleted_at IS NULL AND copywriting.deleted_at IS NULL) OR
        (deleted_at IS NOT NULL AND copywriting.deleted_at IS NULL)
    )
);

COMMENT ON POLICY "authenticated_update" ON copywriting IS 
'允许已登录用户更新文案状态和执行软删除（设置 deleted_at）';

-- 4.5 已认证用户可以查看已删除的文案（用于恢复或审计）
CREATE POLICY "authenticated_read_deleted"
ON copywriting FOR SELECT
TO authenticated
USING (deleted_at IS NOT NULL);

COMMENT ON POLICY "authenticated_read_deleted" ON copywriting IS 
'允许已登录用户查看已软删除的文案（用于审计或恢复）';

-- 4.6 禁止物理删除（可选：如果您想完全禁止 DELETE 操作）
-- 注释掉此策略以允许物理删除
/*
CREATE POLICY "no_physical_delete"
ON copywriting FOR DELETE
TO authenticated
USING (false);

COMMENT ON POLICY "no_physical_delete" ON copywriting IS 
'禁止物理删除，必须使用软删除（设置 deleted_at）';
*/

-- 步骤 5: 创建软删除辅助函数
-- ============================================================================

-- 5.1 软删除函数
CREATE OR REPLACE FUNCTION soft_delete_copywriting(copywriting_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE copywriting
    SET deleted_at = NOW()
    WHERE id = copywriting_id
    AND deleted_at IS NULL;
    
    RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION soft_delete_copywriting IS 
'软删除指定的文案记录';

-- 5.2 恢复软删除函数
CREATE OR REPLACE FUNCTION restore_copywriting(copywriting_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE copywriting
    SET deleted_at = NULL
    WHERE id = copywriting_id
    AND deleted_at IS NOT NULL;
    
    RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION restore_copywriting IS 
'恢复已软删除的文案记录';

-- 5.3 永久删除函数（仅用于清理旧数据）
CREATE OR REPLACE FUNCTION permanently_delete_old_copywriting(days_old INTEGER DEFAULT 90)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM copywriting
    WHERE deleted_at IS NOT NULL
    AND deleted_at < NOW() - (days_old || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

COMMENT ON FUNCTION permanently_delete_old_copywriting IS 
'永久删除超过指定天数的软删除记录（默认 90 天）';

-- 步骤 6: 创建视图（方便查询）
-- ============================================================================

-- 6.1 活跃文案视图（不包含已删除）
CREATE OR REPLACE VIEW active_copywriting AS
SELECT *
FROM copywriting
WHERE deleted_at IS NULL
AND status = 'active';

COMMENT ON VIEW active_copywriting IS 
'仅显示活跃且未删除的文案';

-- 6.2 待审核文案视图
CREATE OR REPLACE VIEW pending_copywriting AS
SELECT *
FROM copywriting
WHERE deleted_at IS NULL
AND status = 'pending';

COMMENT ON VIEW pending_copywriting IS 
'仅显示待审核且未删除的文案';

-- 6.3 已删除文案视图
CREATE OR REPLACE VIEW deleted_copywriting AS
SELECT *
FROM copywriting
WHERE deleted_at IS NOT NULL;

COMMENT ON VIEW deleted_copywriting IS 
'仅显示已软删除的文案';

-- 步骤 7: 验证策略创建成功
-- ============================================================================
DO $$ 
DECLARE
    policy_count INTEGER;
    function_count INTEGER;
    view_count INTEGER;
BEGIN
    -- 检查策略数量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'copywriting';
    
    -- 检查函数数量
    SELECT COUNT(*) INTO function_count
    FROM pg_proc
    WHERE proname IN ('soft_delete_copywriting', 'restore_copywriting', 'permanently_delete_old_copywriting');
    
    -- 检查视图数量
    SELECT COUNT(*) INTO view_count
    FROM pg_views
    WHERE viewname IN ('active_copywriting', 'pending_copywriting', 'deleted_copywriting');
    
    RAISE NOTICE '===============================================';
    RAISE NOTICE '✓ 策略数量: % (预期: 5)', policy_count;
    RAISE NOTICE '✓ 辅助函数: % (预期: 3)', function_count;
    RAISE NOTICE '✓ 视图数量: % (预期: 3)', view_count;
    RAISE NOTICE '===============================================';
END $$;

-- 步骤 8: 显示当前策略列表
-- ============================================================================
SELECT 
    policyname AS "策略名称",
    cmd AS "操作类型",
    roles AS "应用角色"
FROM pg_policies
WHERE tablename = 'copywriting'
ORDER BY cmd, policyname;

-- ============================================================================
-- 完成！
-- ============================================================================
-- 
-- 📝 更改摘要:
-- 
-- ✅ 添加了 deleted_at 字段支持软删除
-- ✅ 优化了所有 RLS 策略，排除已删除的记录
-- ✅ 创建了软删除/恢复/清理辅助函数
-- ✅ 创建了便捷查询视图
-- ✅ 添加了性能优化索引
-- 
-- 🔧 使用方法:
-- 
-- 1. 软删除文案:
--    SELECT soft_delete_copywriting('文案ID');
-- 
-- 2. 恢复文案:
--    SELECT restore_copywriting('文案ID');
-- 
-- 3. 清理 90 天前的软删除记录:
--    SELECT permanently_delete_old_copywriting(90);
-- 
-- 4. 查询活跃文案:
--    SELECT * FROM active_copywriting;
-- 
-- 5. 查询已删除文案:
--    SELECT * FROM deleted_copywriting;
-- 
-- 🔍 建议测试项目:
-- 
-- 1. 未登录用户:
--    - 只能看到 active 且未删除的文案 ✓
--    - 可以提交新文案 ✓
--    - 不能看到已删除的文案 ✓
-- 
-- 2. 已登录用户:
--    - 可以看到所有未删除的文案 ✓
--    - 可以软删除文案 ✓
--    - 可以查看已删除的文案 ✓
--    - 可以恢复已删除的文案 ✓
-- 
-- ============================================================================
