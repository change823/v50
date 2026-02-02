<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabase'
import Toast from './Toast.vue'

const copywriting = ref('')
const loading = ref(false)
const showToast = ref(false)
const toastMessage = ref('')

// 格式化文案，将转义字符转换为真正的换行符、制表符等
const formattedCopywriting = computed(() => {
  return copywriting.value
    .replace(/\\n/g, '\n')    // 转换 \n 为换行
    .replace(/\\r/g, '\r')    // 转换 \r 为回车
    .replace(/\\t/g, '\t')    // 转换 \t 为制表符
    .replace(/\\"/g, '"')     // 转换 \" 为引号
    .replace(/\\'/g, "'")     // 转换 \' 为单引号
})

// 获取随机文案
const fetchRandomCopywriting = async () => {
  loading.value = true
  try {
    // 获取所有 active 状态的文案
    const { data, error } = await supabase
      .from('copywriting')
      .select('content')
      .eq('status', 'active')

    if (error) throw error

    if (data && data.length > 0) {
      // 随机选择一条
      const randomIndex = Math.floor(Math.random() * data.length)
      copywriting.value = data[randomIndex].content
    } else {
      copywriting.value = '暂无文案，快去投稿吧！'
    }
  } catch (error) {
    console.error('获取文案失败:', error)
    copywriting.value = '加载失败，请稍后重试'
  } finally {
    loading.value = false
  }
}

// 复制到剪贴板
const copyToClipboard = async () => {
  try {
    // 复制格式化后的文案（包含真正的换行符）
    await navigator.clipboard.writeText(formattedCopywriting.value)
    showToastMessage('已复制到剪贴板！')
  } catch (error) {
    console.error('复制失败:', error)
    showToastMessage('复制失败，请手动复制')
  }
}

// 显示 Toast 提示
const showToastMessage = (message) => {
  toastMessage.value = message
  showToast.value = true
  setTimeout(() => {
    showToast.value = false
  }, 2000)
}

// 组件挂载时获取第一条文案
onMounted(() => {
  fetchRandomCopywriting()
})
</script>

<template>
  <div class="w-full max-w-2xl">
    <div class="bg-white rounded-2xl shadow-2xl p-8 md:p-12">
      <!-- 文案显示区 -->
      <div class="mb-8">
        <div
          v-if="loading"
          class="text-center text-gray-400 text-lg animate-pulse"
        >
          加载中...
        </div>
        <div
          v-else
          class="text-gray-800 text-lg md:text-xl leading-relaxed whitespace-pre-wrap"
        >
          {{ formattedCopywriting }}
        </div>
      </div>

      <!-- 操作按钮 -->
      <div class="flex gap-4 justify-center">
        <button
          @click="fetchRandomCopywriting"
          :disabled="loading"
          class="flex-1 bg-kfc-red text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-700 active:bg-red-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors select-none flex items-center justify-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          换一句
        </button>
        <button
          @click="copyToClipboard"
          :disabled="loading || !copywriting"
          class="flex-1 bg-gray-800 text-white px-6 py-3 rounded-lg font-semibold hover:bg-gray-700 active:bg-gray-900 disabled:opacity-50 disabled:cursor-not-allowed transition-colors select-none flex items-center justify-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
          复制
        </button>
      </div>
    </div>

    <!-- Toast 提示 -->
    <Toast v-if="showToast" :message="toastMessage" />
  </div>
</template>
