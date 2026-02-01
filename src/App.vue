<script setup>
import { ref } from 'vue'
import HomePage from './components/HomePage.vue'
import SubmitModal from './components/SubmitModal.vue'

const showSubmitModal = ref(false)

const openSubmitModal = () => {
  showSubmitModal.value = true
}

const closeSubmitModal = () => {
  showSubmitModal.value = false
}
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <!-- Header -->
    <header class="bg-kfc-red text-white py-4 px-6 shadow-lg">
      <div class="max-w-4xl mx-auto flex justify-between items-center">
        <h1 class="text-2xl font-bold">🍗 疯四文案</h1>
        <button
          @click="openSubmitModal"
          class="bg-white text-kfc-red px-4 py-2 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
        >
          我要投稿
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 flex items-center justify-center p-6">
      <HomePage />
    </main>

    <!-- Footer -->
    <footer class="text-center py-4 text-gray-600 text-sm">
      <p>每个星期四都值得疯狂 🎉</p>
    </footer>

    <!-- Submit Modal -->
    <SubmitModal v-if="showSubmitModal" @close="closeSubmitModal" />
  </div>
</template>
