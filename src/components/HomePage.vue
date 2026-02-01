<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'
import Toast from './Toast.vue'

const copywriting = ref('')
const loading = ref(false)
const showToast = ref(false)
const toastMessage = ref('')

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
    await navigator.clipboard.writeText(copywriting.value)
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
          {{ copywriting }}
        </div>
      </div>

      <!-- 操作按钮 -->
      <div class="flex gap-4 justify-center">
        <button
          @click="fetchRandomCopywriting"
          :disabled="loading"
          class="flex-1 bg-kfc-red text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all transform hover:scale-105"
        >
          🔄 换一句
        </button>
        <button
          @click="copyToClipboard"
          :disabled="loading || !copywriting"
          class="flex-1 bg-gray-800 text-white px-6 py-3 rounded-lg font-semibold hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all transform hover:scale-105"
        >
          📋 复制
        </button>
      </div>
    </div>

    <!-- Toast 提示 -->
    <Toast v-if="showToast" :message="toastMessage" />
  </div>
</template>
