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
        <h1 class="text-2xl font-bold">🍗 疯四文案</h1>
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
