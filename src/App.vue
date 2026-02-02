<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import SubmitModal from './components/SubmitModal.vue'

const route = useRoute()
const showSubmitModal = ref(false)

// 判断是否在首页
const isHomePage = computed(() => route.path === '/')

const openSubmitModal = () => {
  showSubmitModal.value = true
}

const closeSubmitModal = () => {
  showSubmitModal.value = false
}
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <!-- Header (只在首页显示) -->
    <header v-if="isHomePage" class="bg-kfc-red text-white py-4 px-6 shadow-lg">
      <div class="max-w-4xl mx-auto flex justify-between items-center">
        <div class="flex items-center gap-3">
          <img src="https://p.ipic.vip/6v8rsk.png" alt="KFC" class="w-12 h-12 rounded-lg shadow-md" />
          <div class="flex flex-col">
            <h1 class="text-xl font-bold leading-tight">疯狂星期四</h1>
            <p class="text-sm font-medium opacity-90">Crazy Thursday</p>
          </div>
        </div>
        <button
          @click="openSubmitModal"
          class="bg-white text-kfc-red px-4 py-2 rounded-lg font-semibold hover:bg-gray-100 active:bg-gray-200 transition-colors select-none"
        >
          我要投稿
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main :class="isHomePage ? 'flex-1 flex items-center justify-center p-6' : ''">
      <router-view />
    </main>

    <!-- Footer (只在首页显示) -->
    <footer v-if="isHomePage" class="text-center py-4 text-gray-600 text-sm">
      <p>再不疯狂我们就老了</p>
    </footer>

    <!-- Submit Modal -->
    <SubmitModal v-if="showSubmitModal" @close="closeSubmitModal" />
  </div>
</template>
