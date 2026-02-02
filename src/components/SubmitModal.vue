<script setup>
import { ref } from 'vue'
import { supabase } from '../supabase'
import Toast from './Toast.vue'

const emit = defineEmits(['close'])

const content = ref('')
const submitting = ref(false)
const showToast = ref(false)
const toastMessage = ref('')

// 提交文案
const submitCopywriting = async () => {
  if (!content.value.trim()) {
    showToastMessage('请输入文案内容')
    return
  }

  submitting.value = true
  try {
    const { error } = await supabase
      .from('copywriting')
      .insert([
        { content: content.value.trim(), status: 'pending' }
      ])

    if (error) throw error

    showToastMessage('提交成功！审核通过后展示')
    setTimeout(() => {
      emit('close')
    }, 1500)
  } catch (error) {
    console.error('提交失败:', error)
    showToastMessage('提交失败，请稍后重试')
  } finally {
    submitting.value = false
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
</script>

<template>
  <!-- 模态框背景 -->
  <div
    class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
    @click.self="emit('close')"
  >
    <!-- 模态框内容 -->
    <div class="bg-white rounded-2xl shadow-2xl max-w-lg w-full p-6 md:p-8">
      <div class="flex justify-between items-center mb-6">
        <h2 class="text-2xl font-bold text-gray-800">投稿文案</h2>
        <button
          @click="emit('close')"
          class="text-gray-400 hover:text-gray-600 active:text-gray-800 text-2xl select-none"
        >
          ×
        </button>
      </div>

      <!-- 输入区域 -->
      <textarea
        v-model="content"
        placeholder="写下你的疯四文案..."
        rows="8"
        class="w-full border-2 border-gray-300 rounded-lg p-4 focus:border-kfc-red focus:outline-none resize-none"
        :disabled="submitting"
      ></textarea>

      <!-- 提示信息 -->
      <p class="text-sm text-gray-500 mt-2 mb-6">
        提交后将进入审核队列，审核通过后会在首页展示
      </p>

      <!-- 提交按钮 -->
      <button
        @click="submitCopywriting"
        :disabled="submitting || !content.trim()"
        class="w-full bg-kfc-red text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-700 active:bg-red-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors select-none"
      >
        {{ submitting ? '提交中...' : '提交' }}
      </button>
    </div>

    <!-- Toast 提示 -->
    <Toast v-if="showToast" :message="toastMessage" />
  </div>
</template>
