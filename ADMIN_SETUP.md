# 添加管理后台功能

`AdminPanel.vue` 组件已经创建，但默认未启用。如果你需要一个可视化的管理后台来审核文案，可以按照以下步骤添加。

## 方式 1: 独立路由（推荐）

### 1. 安装 Vue Router

```bash
npm install vue-router@4
```

### 2. 创建路由配置

创建 `src/router.js`:

```javascript
import { createRouter, createWebHistory } from 'vue-router'
import HomePage from './components/HomePage.vue'
import AdminPanel from './components/AdminPanel.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: HomePage
  },
  {
    path: '/admin',
    name: 'Admin',
    component: AdminPanel
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
```

### 3. 修改 `src/main.js`

```javascript
import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'

createApp(App).use(router).mount('#app')
```

### 4. 修改 `src/App.vue`

```vue
<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import SubmitModal from './components/SubmitModal.vue'

const router = useRouter()
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
        <h1 class="text-2xl font-bold cursor-pointer" @click="router.push('/')">
          🍗 疯四文案
        </h1>
        <button
          @click="openSubmitModal"
          class="bg-white text-kfc-red px-4 py-2 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
        >
          我要投稿
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1">
      <router-view />
    </main>

    <!-- Footer -->
    <footer class="text-center py-4 text-gray-600 text-sm">
      <p>每个星期四都值得疯狂 🎉</p>
    </footer>

    <!-- Submit Modal -->
    <SubmitModal v-if="showSubmitModal" @close="closeSubmitModal" />
  </div>
</template>
```

### 5. 访问管理后台

部署后访问 `https://your-domain.com/admin` 即可进入管理后台。

## 方式 2: 隐藏入口（简单）

如果不想安装路由，可以添加一个隐藏的管理入口。

### 修改 `src/App.vue`

```vue
<script setup>
import { ref } from 'vue'
import HomePage from './components/HomePage.vue'
import SubmitModal from './components/SubmitModal.vue'
import AdminPanel from './components/AdminPanel.vue'

const showSubmitModal = ref(false)
const showAdmin = ref(false)

const openSubmitModal = () => {
  showSubmitModal.value = true
}

const closeSubmitModal = () => {
  showSubmitModal.value = false
}

// 按 Shift + Alt + A 打开管理后台
const handleKeydown = (e) => {
  if (e.shiftKey && e.altKey && e.key === 'A') {
    showAdmin.value = !showAdmin.value
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <!-- 显示管理后台或主页 -->
    <AdminPanel v-if="showAdmin" @close="showAdmin = false" />

    <template v-else>
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
    </template>

    <!-- Submit Modal -->
    <SubmitModal v-if="showSubmitModal" @close="closeSubmitModal" />
  </div>
</template>
```

访问方式：在首页按 `Shift + Alt + A` 打开管理后台。

## 配置 Supabase Auth

无论使用哪种方式，都需要在 Supabase 中创建管理员账号。

### 1. 创建用户

在 Supabase Dashboard 中：

1. 进入 **Authentication** → **Users**
2. 点击 **Add user** → **Create new user**
3. 输入邮箱和密码（建议使用强密码）
4. 点击 **Create user**

### 2. 测试登录

- 访问管理后台页面
- 使用创建的邮箱和密码登录
- 应该能看到所有文案列表

## 安全建议

1. **使用强密码**：管理员密码应足够复杂
2. **限制访问**：可以通过 Cloudflare Access 添加额外保护
3. **监控日志**：定期检查 Supabase 的使用日志
4. **禁用注册**：在 Supabase Auth 设置中禁用公开注册
5. **IP 白名单**：在 Supabase 设置中限制可访问的 IP 地址

## Cloudflare Access 保护（可选）

如果使用独立路由 (`/admin`)，可以通过 Cloudflare Access 添加额外保护：

1. 登录 Cloudflare Dashboard
2. 进入 **Zero Trust** → **Access** → **Applications**
3. 创建新应用，保护 `/admin` 路径
4. 设置允许访问的邮箱地址
5. 访问 `/admin` 时会要求先通过 Cloudflare 验证

这样即使有人知道管理后台地址，也无法直接访问。

## 不使用管理后台

如果不需要可视化管理后台，可以继续使用 Supabase Dashboard 手动审核：

1. 登录 Supabase Dashboard
2. 进入 **Table Editor** → **copywriting**
3. 筛选 `status = 'pending'` 的记录
4. 手动修改 `status` 字段

这种方式简单但不够优雅，适合文案数量较少的情况。
