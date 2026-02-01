<script setup>
defineProps({
  message: {
    type: String,
    required: true
  }
})
</script>

<template>
  <div class="fixed top-20 left-1/2 transform -translate-x-1/2 z-50 animate-bounce">
    <div class="bg-gray-800 text-white px-6 py-3 rounded-lg shadow-lg">
      {{ message }}
    </div>
  </div>
</template>

<style scoped>
@keyframes bounce {
  0%, 100% {
    transform: translateY(0) translateX(-50%);
  }
  50% {
    transform: translateY(-10px) translateX(-50%);
  }
}

.animate-bounce {
  animation: bounce 0.5s ease-in-out;
}
</style>
