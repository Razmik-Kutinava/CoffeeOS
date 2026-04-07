<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import { favorites } from "../lib/stores/favorites.js"

  useTelegramBack(() => window.history.back())

  const shopTelegramUrl = (import.meta.env.VITE_SHOP_TELEGRAM_URL || "").trim()

  let { params } = $props()

  let product = $state(null)
  let loading = $state(true)
  let error = $state(null)
  let selected = $state({})
  let qty = $state(1)
  let showMoreMenu = $state(false)
  let isFav = $state(false)

  onMount(async () => {
    try {
      product = await api(`/products/${params.id}`)
      for (const g of product.modifier_groups) {
        if (g.modifier_type === "radio") {
          selected[g.id] = g.modifiers[0]?.id
        } else {
          selected[g.id] = []
        }
      }
      selected = { ...selected }
      await favorites.load()
      isFav = favorites.isFavorite(product.id)
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  })

  function toggleCheckbox(groupId, modId) {
    const arr = [...(selected[groupId] || [])]
    const i = arr.indexOf(modId)
    if (i >= 0) arr.splice(i, 1)
    else arr.push(modId)
    selected[groupId] = arr
    selected = { ...selected }
  }

  let totalPrice = $derived.by(() => {
    if (!product) return 0
    let t = Number(product.price)
    for (const g of product.modifier_groups) {
      if (g.modifier_type === "radio") {
        const mid = selected[g.id]
        const m = g.modifiers.find((x) => x.id === mid)
        if (m) t += Number(m.price_change)
      } else {
        for (const mid of selected[g.id] || []) {
          const m = g.modifiers.find((x) => x.id === mid)
          if (m) t += Number(m.price_change)
        }
      }
    }
    return t * qty
  })

  async function addToCart() {
    const selected_modifiers = []
    for (const g of product.modifier_groups) {
      if (g.modifier_type === "radio") {
        const mid = selected[g.id]
        const m = g.modifiers.find((x) => x.id === mid)
        if (m) selected_modifiers.push({ id: m.id, name: m.name, price: Number(m.price_change) })
      } else {
        for (const mid of selected[g.id] || []) {
          const m = g.modifiers.find((x) => x.id === mid)
          if (m) selected_modifiers.push({ id: m.id, name: m.name, price: Number(m.price_change) })
        }
      }
    }
    await api("/cart/add", {
      method: "POST",
      body: JSON.stringify({ product_id: product.id, quantity: qty, selected_modifiers })
    })
    push("/cart")
  }

  function writeToTelegram() {
    if (!shopTelegramUrl) return
    if (window.Telegram?.WebApp) {
      window.Telegram.WebApp.openTelegramLink(shopTelegramUrl)
    } else {
      window.open(shopTelegramUrl, "_blank")
    }
    showMoreMenu = false
  }

  function shareProduct() {
    if (navigator.share) {
      navigator.share({ title: product.name, url: window.location.href })
    } else {
      navigator.clipboard?.writeText(window.location.href)
    }
    showMoreMenu = false
  }

  async function toggleFavorite() {
    await favorites.toggle(product.id)
    isFav = favorites.isFavorite(product.id)
    showMoreMenu = false
  }
</script>

<!-- Затемнение при открытом меню -->
{#if showMoreMenu}
  <div class="overlay" onclick={() => showMoreMenu = false}></div>
{/if}

<div class="page-header">
  <button class="back-btn" onclick={() => window.history.back()}>‹</button>
  <span class="header-title">{product?.name || ''}</span>
</div>

{#if loading}
  <p class="text-[#a0a0a0]">Загрузка…</p>
{:else if error}
  <p class="text-red-400">{error}</p>
{:else if product}
  {#if product.image_url}
    <img src={product.image_url} alt="" class="mb-4 w-full rounded-xl object-cover" decoding="async" />
  {/if}
  <h1 class="mb-2 text-xl font-bold leading-tight">{product.name}</h1>
  <p class="mb-4 text-sm text-[#a0a0a0]">{product.description}</p>

  {#each product.modifier_groups as g (g.id)}
    <div class="mb-4">
      <p class="mb-2 text-sm font-medium">{g.name}</p>
      {#if g.modifier_type === "radio"}
        <div class="flex flex-wrap gap-2">
          {#each g.modifiers as m (m.id)}
            <label class="cursor-pointer">
              <input
                type="radio"
                name={"mg-" + g.id}
                checked={selected[g.id] === m.id}
                onchange={() => { selected[g.id] = m.id; selected = { ...selected } }}
                class="peer sr-only"
              />
              <span class="inline-block rounded-lg border border-[#3a3a3a] px-3 py-2 text-sm peer-checked:border-[#ff8c42] peer-checked:bg-[#3a2a1a]">
                {m.name}
                {#if Number(m.price_change) > 0}
                  <span class="text-[#ff8c42]">+{m.price_change}₽</span>
                {/if}
              </span>
            </label>
          {/each}
        </div>
      {:else}
        <div class="flex flex-wrap gap-2">
          {#each g.modifiers as m (m.id)}
            <label class="cursor-pointer">
              <input
                type="checkbox"
                checked={(selected[g.id] || []).includes(m.id)}
                onchange={() => toggleCheckbox(g.id, m.id)}
                class="peer sr-only"
              />
              <span class="inline-block rounded-lg border border-[#3a3a3a] px-3 py-2 text-sm peer-checked:border-[#ff8c42] peer-checked:bg-[#3a2a1a]">
                {m.name}
                {#if Number(m.price_change) > 0}
                  <span class="text-[#ff8c42]">+{m.price_change}₽</span>
                {/if}
              </span>
            </label>
          {/each}
        </div>
      {/if}
    </div>
  {/each}

  <!-- Пустое место чтоб контент не залазил под закреп -->
  <div class="bottom-spacer"></div>

  <!-- ЗАКРЕПЛЁННЫЙ НИЖНИЙ БАР -->
  <div class="bottom-bar">
    <div class="bar-left">
      <div class="price-display">{Math.round(totalPrice)}₽</div>
      <div class="qty-controls">
        <button class="qty-btn" onclick={() => (qty = Math.max(1, qty - 1))}>−</button>
        <span class="qty-value">{qty}</span>
        <button class="qty-btn" onclick={() => (qty = qty + 1)}>+</button>
      </div>
    </div>
    <button
      class="add-to-cart-btn"
      disabled={product.stock <= 0}
      onclick={addToCart}
    >
      В корзину 🛒
    </button>
    <button class="more-btn" onclick={() => showMoreMenu = !showMoreMenu}>⋮</button>
  </div>

  <!-- Выпадающее меню от "⋮" -->
  {#if showMoreMenu}
    <div class="more-menu">
      {#if shopTelegramUrl}
        <button onclick={writeToTelegram}>
          <span>✈️</span> Написать в Telegram
        </button>
      {/if}
      <button onclick={shareProduct}>
        <span>🔗</span> Поделиться
      </button>
      <button onclick={toggleFavorite}>
        <span>{isFav ? '♥' : '♡'}</span> {isFav ? 'Убрать из избранного' : 'В избранное'}
      </button>
    </div>
  {/if}
{/if}

<style>
  .overlay {
    position: fixed;
    inset: 0;
    z-index: 90;
    background: rgba(0,0,0,0.3);
  }

  .page-header {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 0 16px;
  }

  .back-btn {
    background: none;
    border: none;
    color: #ff8c42;
    font-size: 28px;
    cursor: pointer;
    padding: 0;
    line-height: 1;
    flex-shrink: 0;
  }

  .header-title {
    flex: 1;
    font-size: 16px;
    font-weight: 600;
    color: #fff;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .bottom-spacer {
    height: 90px;
  }

  /* === ЗАКРЕПЛЁННЫЙ НИЖНИЙ БАР === */
  .bottom-bar {
    position: fixed;
    bottom: 60px;
    left: 0;
    right: 0;
    z-index: 50;
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 12px 16px;
    background: #2a2a2a;
    border-top: 1px solid #3a3a3a;
    max-width: 480px;
    margin: 0 auto;
  }

  .bar-left {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }

  .price-display {
    font-size: 18px;
    font-weight: 700;
    color: #ff8c42;
    white-space: nowrap;
  }

  .qty-controls {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .qty-btn {
    width: 28px;
    height: 28px;
    border-radius: 6px;
    background: #3a3a3a;
    border: none;
    color: #fff;
    font-size: 16px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .qty-value {
    font-size: 14px;
    color: #fff;
    min-width: 20px;
    text-align: center;
  }

  .add-to-cart-btn {
    flex: 1;
    background: #ff8c42;
    color: #000;
    border: none;
    border-radius: 12px;
    padding: 14px 16px;
    font-size: 15px;
    font-weight: 700;
    cursor: pointer;
    white-space: nowrap;
  }

  .add-to-cart-btn:disabled {
    opacity: 0.4;
    cursor: default;
  }

  .more-btn {
    background: #3a3a3a;
    border: none;
    color: #a0a0a0;
    font-size: 22px;
    cursor: pointer;
    padding: 10px 12px;
    border-radius: 10px;
    line-height: 1;
    flex-shrink: 0;
  }

  .more-menu {
    position: fixed;
    bottom: 130px;
    right: 16px;
    background: #2a2a2a;
    border: 1px solid #3a3a3a;
    border-radius: 12px;
    overflow: hidden;
    z-index: 100;
    min-width: 220px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.5);
  }

  .more-menu button {
    display: flex;
    align-items: center;
    gap: 10px;
    width: 100%;
    padding: 14px 16px;
    background: none;
    border: none;
    border-bottom: 1px solid #3a3a3a;
    color: #fff;
    font-size: 15px;
    cursor: pointer;
    text-align: left;
  }

  .more-menu button:last-child { border-bottom: none; }
  .more-menu button:active { background: #3a3a3a; }
</style>
