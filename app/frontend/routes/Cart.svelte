<script>
  import { onMount } from "svelte"
  import { link, push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import PageSkeleton from "../components/PageSkeleton.svelte"

  let items = $state([])
  let total = $state(0)
  let loading = $state(true)
  let busyIndex = $state(null)
  let err = $state(null)

  const CART_CACHE_KEY = "coffeeos_shop_cart_v1"

  function readCartCache() {
    try {
      const raw = localStorage.getItem(CART_CACHE_KEY)
      return raw ? JSON.parse(raw) : null
    } catch {
      return null
    }
  }

  async function load() {
    try {
      const data = await api("/cart")
      localStorage.setItem(CART_CACHE_KEY, JSON.stringify(data))
      items = data.items
      total = data.total
    } catch (e) {
      const cached = readCartCache()
      if (cached?.items) {
        items = cached.items
        total = cached.total ?? 0
        err = navigator.onLine ? e.message : "Показана сохранённая корзина (офлайн)"
        return
      }
      throw e
    }
  }

  onMount(async () => {
    try {
      await load()
    } catch (e) {
      err = e.message
    } finally {
      loading = false
    }
  })

  async function bump(index, delta) {
    if (busyIndex !== null) return
    busyIndex = index
    err = null
    try {
      await api(`/cart/items/${index}`, {
        method: "PATCH",
        body: JSON.stringify({ delta })
      })
      await load()
    } finally {
      busyIndex = null
    }
  }

  async function removeLine(index) {
    if (busyIndex !== null) return
    busyIndex = index
    err = null
    try {
      await api(`/cart/items/${index}`, { method: "DELETE" })
      await load()
    } finally {
      busyIndex = null
    }
  }
</script>

<h1 class="mb-4 text-xl font-bold">Корзина</h1>

{#if loading}
  <PageSkeleton />
{:else if err && !items.length}
  <p class="text-red-400">{err}</p>
{:else if !items.length}
  <div class="py-12 text-center text-[#a0a0a0]">
    <p class="mb-4 text-4xl">🛒</p>
    <p>Корзина пуста</p>
    <a use:link href="/" class="mt-4 inline-block text-[#ff8c42]">Перейти в каталог</a>
  </div>
{:else}
  {#each items as line (line.index)}
    <div class="mb-4 flex gap-3 rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-3">
      {#if line.image_url}
        <img src={line.image_url} alt="" class="h-20 w-20 shrink-0 rounded-lg object-cover" decoding="async" />
      {/if}
      <div class="min-w-0 flex-1">
        <a use:link href="/product/{line.product_id}" class="font-medium hover:underline">{line.product_name}</a>
        <p class="text-sm text-[#a0a0a0]">
          {Math.round(line.unit_total)}₽ × {line.quantity}
        </p>
        {#if line.selected_modifiers?.length}
          <ul class="mt-1 space-y-0.5 text-xs text-[#888]">
            {#each line.selected_modifiers as mod (mod.id)}
              <li>{mod.name}{#if Number(mod.price) > 0} (+{Math.round(mod.price)}₽){/if}</li>
            {/each}
          </ul>
        {/if}
        <div class="mt-2 flex items-center gap-2">
          <button
            type="button"
            class="rounded bg-[#3a3a3a] px-2 py-0.5 text-sm disabled:opacity-40"
            disabled={busyIndex !== null}
            onclick={() => bump(line.index, -1)}
          >
            −
          </button>
          <span class="text-sm">{line.quantity}</span>
          <button
            type="button"
            class="rounded bg-[#3a3a3a] px-2 py-0.5 text-sm disabled:opacity-40"
            disabled={busyIndex !== null}
            onclick={() => bump(line.index, 1)}
          >
            +
          </button>
          <button
            type="button"
            class="ml-auto text-sm text-red-400 disabled:opacity-40"
            disabled={busyIndex !== null}
            onclick={() => removeLine(line.index)}
          >
            Удалить
          </button>
        </div>
      </div>
    </div>
  {/each}

  <div class="mb-4 flex justify-between text-lg">
    <span>Итого</span>
    <span class="font-bold text-[#ff8c42]">{Math.round(total)}₽</span>
  </div>

  <button
    type="button"
    class="w-full rounded-xl bg-[#ff8c42] py-4 text-lg font-semibold text-black"
    onclick={() => push("/checkout")}
  >
    Оформить заказ
  </button>
{/if}
