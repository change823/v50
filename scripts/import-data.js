import { createClient } from '@supabase/supabase-js'
import { readFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import dotenv from 'dotenv'

// 加载环境变量
dotenv.config()

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// 初始化 Supabase 客户端
const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ 错误: 请在 .env 文件中配置 VITE_SUPABASE_URL 和 VITE_SUPABASE_ANON_KEY')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseAnonKey)

// 读取 JSON 数据文件
const dataFilePath = join(__dirname, '..', 'data.json')
let data

try {
  const fileContent = readFileSync(dataFilePath, 'utf-8')
  data = JSON.parse(fileContent)
  console.log(`✅ 成功读取 data.json，共 ${data.length} 条数据`)
} catch (error) {
  console.error('❌ 读取 data.json 失败:', error.message)
  process.exit(1)
}

// 批量导入数据
async function importData() {
  console.log('\n🚀 开始导入数据...\n')

  let successCount = 0
  let errorCount = 0

  // 每次批量插入 100 条
  const batchSize = 100

  for (let i = 0; i < data.length; i += batchSize) {
    const batch = data.slice(i, i + batchSize)

    // 将数据转换为数据库格式
    const records = batch.map(item => ({
      content: item.content || item,
      status: item.status || 'pending' // 默认为 pending，需要管理员审核
    }))

    try {
      const { data: insertedData, error } = await supabase
        .from('copywriting')
        .insert(records)
        .select()

      if (error) throw error

      successCount += records.length
      console.log(`✓ 第 ${i + 1}-${i + records.length} 条导入成功`)
    } catch (error) {
      errorCount += records.length
      console.error(`✗ 第 ${i + 1}-${i + batch.length} 条导入失败:`, error.message)
    }
  }

  console.log('\n' + '='.repeat(50))
  console.log(`📊 导入完成！`)
  console.log(`   成功: ${successCount} 条`)
  console.log(`   失败: ${errorCount} 条`)
  console.log(`   总计: ${data.length} 条`)
  console.log('='.repeat(50) + '\n')
}

// 执行导入
importData()
  .then(() => {
    console.log('✅ 数据导入任务完成')
    process.exit(0)
  })
  .catch((error) => {
    console.error('❌ 导入过程发生错误:', error)
    process.exit(1)
  })
