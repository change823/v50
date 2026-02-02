import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '../components/HomePage.vue'
import AdminPanel from '../components/AdminPanel.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: HomePage,
    meta: {
      title: '疯四文案'
    }
  },
  {
    path: '/admin',
    name: 'Admin',
    component: AdminPanel,
    meta: {
      title: '管理后台 - 疯四文案'
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 更新页面标题
router.beforeEach((to, from, next) => {
  document.title = to.meta.title || '疯四文案'
  next()
})

export default router
