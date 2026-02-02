import { createClient } from '@supabase/supabase-js'
import * as dotenv from 'dotenv'

// 加载环境变量
dotenv.config()

const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ 错误: 请设置 VITE_SUPABASE_URL 和 VITE_SUPABASE_ANON_KEY 环境变量')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function checkRLSPolicies() {
  console.log('📋 正在查询 copywriting 表的 RLS 策略...\n')
  
  try {
    // 执行查询
    const { data, error } = await supabase.rpc('exec_sql', {
      sql: `
        SELECT 
          schemaname, 
          tablename, 
          policyname, 
          permissive, 
          roles,
          cmd, 
          qual, 
          with_check
        FROM pg_policies
        WHERE tablename = 'copywriting'
      `
    })

    if (error) {
      // 如果 RPC 不存在，尝试使用直接查询（需要适当的权限）
      console.log('⚠️  RPC 方法不可用，尝试使用 PostgreSQL REST API...\n')
      
      // 使用 PostgREST 的方式（这可能需要额外配置）
      const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseAnonKey,
          'Authorization': `Bearer ${supabaseAnonKey}`
        },
        body: JSON.stringify({
          sql: `SELECT * FROM pg_policies WHERE tablename = 'copywriting'`
        })
      })

      if (!response.ok) {
        throw new Error('需要直接在 Supabase Dashboard 中执行此查询')
      }
    }

    if (!data || data.length === 0) {
      console.log('ℹ️  未找到 copywriting 表的 RLS 策略')
      console.log('\n💡 提示：')
      console.log('   - 表可能还没有启用 RLS')
      console.log('   - 或者还没有创建任何策略')
      return
    }

    console.log(`✅ 找到 ${data.length} 个策略：\n`)
    console.log('=' .repeat(80))
    
    data.forEach((policy, index) => {
      console.log(`\n策略 ${index + 1}: ${policy.policyname}`)
      console.log('-'.repeat(80))
      console.log(`  模式名称:     ${policy.schemaname}`)
      console.log(`  表名:         ${policy.tablename}`)
      console.log(`  策略类型:     ${policy.permissive}`)
      console.log(`  应用角色:     ${JSON.stringify(policy.roles)}`)
      console.log(`  命令类型:     ${policy.cmd}`)
      console.log(`  USING 条件:   ${policy.qual || '(无)'}`)
      console.log(`  WITH CHECK:   ${policy.with_check || '(无)'}`)
    })
    
    console.log('\n' + '='.repeat(80))

  } catch (err) {
    console.error('\n❌ 查询失败:', err.message)
    console.log('\n💡 解决方案：')
    console.log('   请在 Supabase Dashboard 的 SQL Editor 中执行以下查询：')
    console.log('\n' + '-'.repeat(80))
    console.log(`
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles,
  cmd, 
  qual, 
  with_check
FROM pg_policies
WHERE tablename = 'copywriting';
    `.trim())
    console.log('-'.repeat(80) + '\n')
  }
}

// 执行查询
checkRLSPolicies()
  .then(() => {
    console.log('\n✨ 查询完成')
    process.exit(0)
  })
  .catch((err) => {
    console.error('发生错误:', err)
    process.exit(1)
  })
