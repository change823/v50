-- ============================================
-- 疯四文案 - Supabase 数据库初始化脚本
-- ============================================

-- 1. 创建 copywriting 表
CREATE TABLE IF NOT EXISTS copywriting (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_copywriting_status ON copywriting(status);
CREATE INDEX IF NOT EXISTS idx_copywriting_created_at ON copywriting(created_at DESC);

-- 3. 启用 Row Level Security (RLS)
ALTER TABLE copywriting ENABLE ROW LEVEL SECURITY;

-- 4. 删除现有策略（如果存在）
DROP POLICY IF EXISTS "Anyone can read active copywriting" ON copywriting;
DROP POLICY IF EXISTS "Anyone can insert pending copywriting" ON copywriting;
DROP POLICY IF EXISTS "Only authenticated users can update copywriting" ON copywriting;
DROP POLICY IF EXISTS "Authenticated users can read all copywriting" ON copywriting;

-- 5. 创建 RLS 策略

-- 允许所有人读取 status = 'active' 的文案（首页展示）
CREATE POLICY "Anyone can read active copywriting"
ON copywriting
FOR SELECT
USING (status = 'active');

-- 允许所有人插入新文案（投稿功能）
CREATE POLICY "Anyone can insert pending copywriting"
ON copywriting
FOR INSERT
WITH CHECK (status = 'pending');

-- 只有认证用户可以更新文案状态（管理员审核）
CREATE POLICY "Only authenticated users can update copywriting"
ON copywriting
FOR UPDATE
USING (auth.role() = 'authenticated');

-- 认证用户可以查看所有文案（管理后台）
CREATE POLICY "Authenticated users can read all copywriting"
ON copywriting
FOR SELECT
USING (auth.role() = 'authenticated');

-- 6. 插入一些示例数据（可选）
INSERT INTO copywriting (content, status) VALUES
('今天是疯狂星期四！有没有人请我吃肯德基？如果你请我吃，我就会非常开心，毕竟肯德基那么好吃，我怎么能拒绝呢？所以请我吃吧，拜托了！', 'active'),
('肯德基疯狂星期四！V我50，让我看看谁才是真正的朋友！', 'active'),
('今天星期四，我想吃肯德基了。你愿意请我吃吗？我知道你很善良，一定不会拒绝我的，对吗？', 'active')
ON CONFLICT DO NOTHING;

-- 完成提示
DO $$
BEGIN
  RAISE NOTICE '✅ 数据库初始化完成！';
  RAISE NOTICE '📊 表名: copywriting';
  RAISE NOTICE '🔒 RLS 已启用';
  RAISE NOTICE '🎉 已插入 % 条示例数据', (SELECT COUNT(*) FROM copywriting WHERE status = 'active');
END $$;
