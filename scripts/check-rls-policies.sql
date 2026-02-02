-- 查询 copywriting 表的 RLS 策略
-- 在 Supabase Dashboard > SQL Editor 中执行此查询

SELECT 
  schemaname AS "模式名称", 
  tablename AS "表名", 
  policyname AS "策略名称", 
  permissive AS "策略类型", 
  roles AS "应用角色",
  cmd AS "命令类型", 
  qual AS "USING条件", 
  with_check AS "WITH_CHECK条件"
FROM pg_policies
WHERE tablename = 'copywriting'
ORDER BY policyname;

-- 同时检查 RLS 是否已启用
SELECT 
  schemaname AS "模式名称",
  tablename AS "表名",
  rowsecurity AS "RLS已启用"
FROM pg_tables
WHERE tablename = 'copywriting';
