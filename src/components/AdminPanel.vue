<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabase'
import Toast from './Toast.vue'

// 认证状态
const isAuthenticated = ref(false)
const email = ref('')
const password = ref('')
const loginError = ref('')

// 数据状态
const allCopywriting = ref([])
const loading = ref(false)

// 筛选和分页
const currentStatus = ref('all') // all, pending, active, rejected
const currentPage = ref(1)
const pageSize = 10

// Toast
const showToast = ref(false)
const toastMessage = ref('')

// 计算属性：根据状态筛选数据
const filteredList = computed(() => {
  if (currentStatus.value === 'all') {
    return allCopywriting.value
  }
  return allCopywriting.value.filter(item => item.status === currentStatus.value)
})

// 计算属性：统计各状态数量
const statusCounts = computed(() => ({
  all: allCopywriting.value.length,
  pending: allCopywriting.value.filter(item => item.status === 'pending').length,
  active: allCopywriting.value.filter(item => item.status === 'active').length,
  rejected: allCopywriting.value.filter(item => item.status === 'rejected').length
}))

// 计算属性：分页后的数据
const paginatedList = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  const end = start + pageSize
  return filteredList.value.slice(start, end)
})

// 计算属性：总页数
const totalPages = computed(() => {
  return Math.ceil(filteredList.value.length / pageSize)
})

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
  allCopywriting.value = []
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
    allCopywriting.value = data || []
  } catch (error) {
    console.error('获取数据失败:', error)
    showToastMessage('获取数据失败')
  } finally {
    loading.value = false
  }
}

// 切换状态筛选
const changeStatus = (status) => {
  currentStatus.value = status
  currentPage.value = 1 // 重置到第一页
}

// 翻页
const goToPage = (page) => {
  if (page < 1 || page > totalPages.value) return
  currentPage.value = page
  // 滚动到顶部
  window.scrollTo({ top: 0, behavior: 'smooth' })
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

// 格式化文案内容，转换转义字符
const formatContent = (content) => {
  return content
    .replace(/\\n/g, '\n')
    .replace(/\\r/g, '\r')
    .replace(/\\t/g, '\t')
    .replace(/\\"/g, '"')
    .replace(/\\'/g, "'")
}

// 获取状态显示文本
const getStatusText = (status) => {
  const map = {
    pending: '待审核',
    active: '已通过',
    rejected: '已拒绝'
  }
  return map[status] || status
}

// 获取状态样式
const getStatusClass = (status) => {
  const map = {
    pending: 'bg-orange-100 text-orange-700',
    active: 'bg-green-100 text-green-700',
    rejected: 'bg-red-100 text-red-700'
  }
  return map[status] || ''
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
            class="w-full bg-kfc-red text-white py-2 rounded-lg hover:bg-red-700 select-none"
          >
            登录
          </button>
        </form>
      </div>
    </div>

    <!-- 管理界面 -->
    <div v-else class="max-w-6xl mx-auto">
      <!-- 头部 -->
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">文案管理后台</h1>
        <button
          @click="logout"
          class="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700 select-none"
        >
          登出
        </button>
      </div>

      <!-- 状态筛选标签 -->
      <div class="bg-white rounded-lg shadow p-4 mb-6">
        <div class="flex gap-2 flex-wrap">
          <button
            @click="changeStatus('all')"
            :class="[
              'px-4 py-2 rounded-lg font-semibold transition-colors select-none',
              currentStatus === 'all'
                ? 'bg-kfc-red text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            全部 ({{ statusCounts.all }})
          </button>
          <button
            @click="changeStatus('pending')"
            :class="[
              'px-4 py-2 rounded-lg font-semibold transition-colors select-none',
              currentStatus === 'pending'
                ? 'bg-orange-500 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            待审核 ({{ statusCounts.pending }})
          </button>
          <button
            @click="changeStatus('active')"
            :class="[
              'px-4 py-2 rounded-lg font-semibold transition-colors select-none',
              currentStatus === 'active'
                ? 'bg-green-500 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            已通过 ({{ statusCounts.active }})
          </button>
          <button
            @click="changeStatus('rejected')"
            :class="[
              'px-4 py-2 rounded-lg font-semibold transition-colors select-none',
              currentStatus === 'rejected'
                ? 'bg-red-500 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            已拒绝 ({{ statusCounts.rejected }})
          </button>
        </div>
      </div>

      <!-- 数据列表 -->
      <div class="bg-white rounded-lg shadow">
        <!-- 加载状态 -->
        <div v-if="loading" class="p-12 text-center text-gray-400">
          加载中...
        </div>

        <!-- 无数据 -->
        <div v-else-if="filteredList.length === 0" class="p-12 text-center text-gray-400">
          暂无数据
        </div>

        <!-- 数据列表 -->
        <div v-else class="divide-y">
          <div
            v-for="item in paginatedList"
            :key="item.id"
            class="p-6 hover:bg-gray-50 transition-colors"
          >
            <div class="flex items-start justify-between gap-4">
              <!-- 左侧：内容 -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-2">
                  <span class="text-sm text-gray-500">ID: {{ item.id }}</span>
                  <span
                    :class="[
                      'text-xs px-2 py-1 rounded-full font-semibold',
                      getStatusClass(item.status)
                    ]"
                  >
                    {{ getStatusText(item.status) }}
                  </span>
                  <span class="text-sm text-gray-400">
                    {{ new Date(item.created_at).toLocaleString('zh-CN') }}
                  </span>
                </div>
                <p class="text-gray-800 whitespace-pre-wrap leading-relaxed">
                  {{ formatContent(item.content) }}
                </p>
              </div>

              <!-- 右侧：操作按钮 -->
              <div class="flex flex-col gap-2 flex-shrink-0">
                <!-- 待审核状态的操作 -->
                <template v-if="item.status === 'pending'">
                  <button
                    @click="updateStatus(item.id, 'active')"
                    class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 text-sm whitespace-nowrap select-none"
                  >
                    ✓ 通过
                  </button>
                  <button
                    @click="updateStatus(item.id, 'rejected')"
                    class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 text-sm whitespace-nowrap select-none"
                  >
                    ✗ 拒绝
                  </button>
                </template>

                <!-- 已通过状态的操作 -->
                <template v-else-if="item.status === 'active'">
                  <button
                    @click="updateStatus(item.id, 'rejected')"
                    class="bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600 text-sm whitespace-nowrap select-none"
                  >
                    拒绝
                  </button>
                </template>

                <!-- 已拒绝状态的操作 -->
                <template v-else-if="item.status === 'rejected'">
                  <button
                    @click="updateStatus(item.id, 'active')"
                    class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 text-sm whitespace-nowrap select-none"
                  >
                    恢复
                  </button>
                </template>

                <!-- 删除按钮（所有状态都有） -->
                <button
                  @click="deleteCopywriting(item.id)"
                  class="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600 text-sm whitespace-nowrap select-none"
                >
                  删除
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 分页 -->
        <div v-if="totalPages > 1" class="p-6 border-t bg-gray-50">
          <div class="flex items-center justify-between">
            <!-- 左侧：显示信息 -->
            <div class="text-sm text-gray-600">
              共 {{ filteredList.length }} 条数据，第 {{ currentPage }} / {{ totalPages }} 页
            </div>

            <!-- 右侧：分页按钮 -->
            <div class="flex gap-2">
              <button
                @click="goToPage(1)"
                :disabled="currentPage === 1"
                class="px-3 py-1 rounded bg-white border hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed select-none"
              >
                首页
              </button>
              <button
                @click="goToPage(currentPage - 1)"
                :disabled="currentPage === 1"
                class="px-3 py-1 rounded bg-white border hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed select-none"
              >
                上一页
              </button>

              <!-- 页码 -->
              <div class="flex gap-1">
                <button
                  v-for="page in totalPages"
                  :key="page"
                  v-show="Math.abs(page - currentPage) < 3 || page === 1 || page === totalPages"
                  @click="goToPage(page)"
                  :class="[
                    'px-3 py-1 rounded border select-none',
                    page === currentPage
                      ? 'bg-kfc-red text-white border-kfc-red'
                      : 'bg-white hover:bg-gray-100'
                  ]"
                >
                  {{ page }}
                </button>
              </div>

              <button
                @click="goToPage(currentPage + 1)"
                :disabled="currentPage === totalPages"
                class="px-3 py-1 rounded bg-white border hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed select-none"
              >
                下一页
              </button>
              <button
                @click="goToPage(totalPages)"
                :disabled="currentPage === totalPages"
                class="px-3 py-1 rounded bg-white border hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed select-none"
              >
                末页
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast -->
    <Toast v-if="showToast" :message="toastMessage" />
  </div>
</template>
