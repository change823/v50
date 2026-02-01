<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'
import Toast from './Toast.vue'

// 认证状态
const isAuthenticated = ref(false)
const email = ref('')
const password = ref('')
const loginError = ref('')

// 文案列表
const pendingList = ref([])
const activeList = ref([])
const rejectedList = ref([])
const loading = ref(false)

// Toast
const showToast = ref(false)
const toastMessage = ref('')

// 登录
const login = async () => {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })
    if (error) throw error
    isAuthenticated.value = true
    await fetchAllCopywriting()
  } catch (error) {
    console.error('登录失败:', error)
    loginError.value = error.message
  }
}

// 登出
const logout = async () => {
  await supabase.auth.signOut()
  isAuthenticated.value = false
  pendingList.value = []
  activeList.value = []
  rejectedList.value = []
}

// 获取所有文案
const fetchAllCopywriting = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('copywriting')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error

    pendingList.value = data.filter(item => item.status === 'pending')
    activeList.value = data.filter(item => item.status === 'active')
    rejectedList.value = data.filter(item => item.status === 'rejected')
  } catch (error) {
    console.error('获取数据失败:', error)
    showToastMessage('获取数据失败')
  } finally {
    loading.value = false
  }
}

// 更新文案状态
const updateStatus = async (id, newStatus) => {
  try {
    const { error } = await supabase
      .from('copywriting')
      .update({ status: newStatus })
      .eq('id', id)

    if (error) throw error

    showToastMessage('状态已更新')
    await fetchAllCopywriting()
  } catch (error) {
    console.error('更新失败:', error)
    showToastMessage('更新失败')
  }
}

// 删除文案
const deleteCopywriting = async (id) => {
  if (!confirm('确定要删除这条文案吗？')) return

  try {
    const { error } = await supabase
      .from('copywriting')
      .delete()
      .eq('id', id)

    if (error) throw error

    showToastMessage('已删除')
    await fetchAllCopywriting()
  } catch (error) {
    console.error('删除失败:', error)
    showToastMessage('删除失败')
  }
}

// 显示 Toast
const showToastMessage = (message) => {
  toastMessage.value = message
  showToast.value = true
  setTimeout(() => {
    showToast.value = false
  }, 2000)
}

// 检查登录状态
onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  if (data.session) {
    isAuthenticated.value = true
    await fetchAllCopywriting()
  }
})
</script>

<template>
  <div class="min-h-screen bg-gray-100 p-6">
    <!-- 登录表单 -->
    <div v-if="!isAuthenticated" class="max-w-md mx-auto mt-20">
      <div class="bg-white rounded-lg shadow-lg p-8">
        <h2 class="text-2xl font-bold mb-6 text-center">管理后台登录</h2>
        <form @submit.prevent="login">
          <div class="mb-4">
            <label class="block text-gray-700 mb-2">邮箱</label>
            <input
              v-model="email"
              type="email"
              required
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:border-kfc-red"
            />
          </div>
          <div class="mb-4">
            <label class="block text-gray-700 mb-2">密码</label>
            <input
              v-model="password"
              type="password"
              required
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:border-kfc-red"
            />
          </div>
          <div v-if="loginError" class="mb-4 text-red-500 text-sm">
            {{ loginError }}
          </div>
          <button
            type="submit"
            class="w-full bg-kfc-red text-white py-2 rounded-lg hover:bg-red-700"
          >
            登录
          </button>
        </form>
      </div>
    </div>

    <!-- 管理界面 -->
    <div v-else class="max-w-6xl mx-auto">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">文案管理后台</h1>
        <button
          @click="logout"
          class="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700"
        >
          登出
        </button>
      </div>

      <!-- 待审核 -->
      <div class="mb-8">
        <h2 class="text-xl font-bold mb-4 text-orange-600">
          待审核 ({{ pendingList.length }})
        </h2>
        <div class="space-y-4">
          <div
            v-for="item in pendingList"
            :key="item.id"
            class="bg-white p-4 rounded-lg shadow"
          >
            <p class="text-gray-800 mb-3">{{ item.content }}</p>
            <div class="flex gap-2 text-sm text-gray-500 mb-3">
              <span>ID: {{ item.id }}</span>
              <span>{{ new Date(item.created_at).toLocaleString('zh-CN') }}</span>
            </div>
            <div class="flex gap-2">
              <button
                @click="updateStatus(item.id, 'active')"
                class="bg-green-500 text-white px-4 py-1 rounded hover:bg-green-600"
              >
                ✓ 通过
              </button>
              <button
                @click="updateStatus(item.id, 'rejected')"
                class="bg-red-500 text-white px-4 py-1 rounded hover:bg-red-600"
              >
                ✗ 拒绝
              </button>
              <button
                @click="deleteCopywriting(item.id)"
                class="bg-gray-500 text-white px-4 py-1 rounded hover:bg-gray-600"
              >
                删除
              </button>
            </div>
          </div>
          <div v-if="pendingList.length === 0" class="text-gray-500 text-center py-8">
            暂无待审核文案
          </div>
        </div>
      </div>

      <!-- 已通过 -->
      <div class="mb-8">
        <h2 class="text-xl font-bold mb-4 text-green-600">
          已通过 ({{ activeList.length }})
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="item in activeList"
            :key="item.id"
            class="bg-white p-4 rounded-lg shadow"
          >
            <p class="text-gray-800 mb-2">{{ item.content }}</p>
            <div class="flex justify-between items-center text-sm">
              <span class="text-gray-500">ID: {{ item.id }}</span>
              <button
                @click="deleteCopywriting(item.id)"
                class="text-red-500 hover:text-red-700"
              >
                删除
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 已拒绝 -->
      <div>
        <h2 class="text-xl font-bold mb-4 text-red-600">
          已拒绝 ({{ rejectedList.length }})
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="item in rejectedList"
            :key="item.id"
            class="bg-white p-4 rounded-lg shadow opacity-60"
          >
            <p class="text-gray-800 mb-2">{{ item.content }}</p>
            <div class="flex justify-between items-center text-sm">
              <span class="text-gray-500">ID: {{ item.id }}</span>
              <div class="flex gap-2">
                <button
                  @click="updateStatus(item.id, 'active')"
                  class="text-green-500 hover:text-green-700"
                >
                  恢复
                </button>
                <button
                  @click="deleteCopywriting(item.id)"
                  class="text-red-500 hover:text-red-700"
                >
                  删除
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast -->
    <Toast v-if="showToast" :message="toastMessage" />
  </div>
</template>
