<script>
  import { push } from "svelte-spa-router"
  import { ShoppingCart, User, Home, Heart } from "lucide-svelte"

  let hash = $state(typeof window !== 'undefined' ? window.location.hash : '')

  $effect(() => {
    const handler = () => { hash = window.location.hash }
    window.addEventListener('hashchange', handler)
    return () => window.removeEventListener('hashchange', handler)
  })

  function isActive(path) {
    const h = hash.replace('#', '') || '/'
    if (path === '/') return h === '/' || h === ''
    return h === path || h.startsWith(path + '/')
  }
</script>

<nav class="fixed bottom-0 left-0 right-0 z-40 border-t border-[#3a3a3a] bg-[#2a2a2a]/95 backdrop-blur">
  <div class="mx-auto flex max-w-lg justify-around py-2">
    <button
      onclick={() => push('/')}
      class="flex flex-col items-center gap-1 px-3 py-1 transition-colors"
      class:text-white={isActive('/')}
      class:text-[#a0a0a0]={!isActive('/')}
    >
      <Home class="h-6 w-6" />
      <span class="text-xs">Каталог</span>
    </button>

    <button
      onclick={() => push('/cart')}
      class="flex flex-col items-center gap-1 px-3 py-1 transition-colors"
      class:text-white={isActive('/cart')}
      class:text-[#a0a0a0]={!isActive('/cart')}
    >
      <ShoppingCart class="h-6 w-6" />
      <span class="text-xs">Корзина</span>
    </button>

    <button
      onclick={() => push('/favorites')}
      class="flex flex-col items-center gap-1 px-3 py-1 transition-colors"
      class:text-[#ff8c42]={isActive('/favorites')}
      class:text-[#a0a0a0]={!isActive('/favorites')}
    >
      <Heart class="h-6 w-6" />
      <span class="text-xs">Избранное</span>
    </button>

    <button
      onclick={() => push('/profile')}
      class="flex flex-col items-center gap-1 px-3 py-1 transition-colors"
      class:text-white={isActive('/profile')}
      class:text-[#a0a0a0]={!isActive('/profile')}
    >
      <User class="h-6 w-6" />
      <span class="text-xs">Профиль</span>
    </button>
  </div>
</nav>
