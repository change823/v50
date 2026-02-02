-- ============================================================================
-- 更新删除策略：允许删除任何状态的记录
-- 执行方式：在 Supabase Dashboard > SQL Editor 中执行
-- ============================================================================

-- 删除旧的删除策略
DROP POLICY IF EXISTS "authenticated_delete_pending" ON copywriting;

-- 创建新的删除策略（允许删除任何状态）
CREATE POLICY "authenticated_delete_all"
ON copywriting FOR DELETE
TO authenticated
USING (true);

COMMENT ON POLICY "authenticated_delete_all" ON copywriting IS 
'允许已登录用户删除任何状态的文案（不再限制只能删除 pending）';

-- 验证策略
SELECT 
  policyname AS "策略名称",
  cmd AS "操作类型",
  roles AS "应用角色",
  qual AS "USING条件"
FROM pg_policies
WHERE tablename = 'copywriting' AND cmd = 'DELETE';

-- ============================================================================
-- 完成！
-- ============================================================================
-- 
-- 更改说明：
-- - 删除了旧策略：只能删除 pending 状态
-- - 新策略：已认证用户可以删除任何状态的记录
-- 
-- 注意：
-- - 这个改动提高了灵活性，但也增加了误删风险
-- - 建议在管理面板中添加二次确认
-- - 重要数据建议使用软删除（设置 deleted_at）而不是物理删除
-- 
-- ============================================================================
