<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { addToCart as shopAddToCart } from "../lib/shopCartAdd.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import { favorites } from "../lib/stores/favorites.js"
  import {
    defaultSelectionForGroup,
    buildModifierPayload,
    selectedModifierIdsForGroup
  } from "../lib/modifiers.js"

  useTelegramBack(() => window.history.back())

  const shopTelegramUrl = (import.meta.env.VITE_SHOP_TELEGRAM_URL || "").trim()
  const PRODUCT_POLL_MS = 8_000

  let { params } = $props()

  let product = $state(null)
  let loading = $state(true)
  let error = $state(null)
  let selected = $state({})
  let qty = $state(1)
  let showMoreMenu = $state(false)
  let isFav = $state(false)
  let adding = $state(false)
  let loadedProductId = $state(null)

  function normalizeSelection(value, group) {
    if (value !== undefined) {
      if (Array.isArray(value)) return [...value]
      return value ? [value] : []
    }
    return defaultSelectionForGroup(group)
  }

  async function loadProduct(keepSelections = false) {
    const productId = params.id
    const sameProduct = keepSelections && loadedProductId === productId && product?.id === productId
    const prev = sameProduct ? { ...selected } : {}
    const p = await api(`/products/${productId}`)
    if (params.id !== productId) return

    product = p
    const next = {}
    for (const g of product.modifier_groups) {
      next[g.id] = sameProduct ? normalizeSelection(prev[g.id], g) : defaultSelectionForGroup(g)
    }
    selected = next
    loadedProductId = p.id
  }

  // svelte-spa-router не размонтирует /product/:id при смене id — только обновляет params.
  let routeKey = $derived(String(params.id ?? ""))

  $effect(() => {
    const key = routeKey
    if (!key) return

    let active = true
    loading = true
    error = null
    selected = {}
    loadedProductId = null
    product = null
    qty = 1
    adding = false
    showMoreMenu = false

    ;(async () => {
      try {
        await loadProduct(false)
        if (!active) return
        isFav = favorites.isFavorite(product.id)
      } catch (e) {
        if (active) {
          error = e.message
          product = null
        }
      } finally {
        if (active) loading = false
      }
    })()

    return () => {
      active = false
    }
  })

  onMount(() => {
    favorites.load()

    const tick = async () => {
      if (!params.id || params.id !== loadedProductId) return
      try {
        await loadProduct(true)
      } catch {
        /* keep last product */
      }
    }
    const pollTimer = setInterval(tick, PRODUCT_POLL_MS)
    const onVisible = () => {
      if (document.visibilityState === "visible") tick()
    }
    document.addEventListener("visibilitychange", onVisible)
    return () => {
      clearInterval(pollTimer)
      document.removeEventListener("visibilitychange", onVisible)
    }
  })

  function toggleModifier(groupId, modId) {
    const arr = [...(selected[groupId] || [])]
    const i = arr.indexOf(modId)
    if (i >= 0) arr.splice(i, 1)
    else arr.push(modId)
    selected[groupId] = arr
    selected = { ...selected }
  }

  function isModifierSelected(group, modId) {
    return selectedModifierIdsForGroup(group, selected).includes(modId)
  }

  let totalPrice = $derived.by(() => {
    if (!product) return 0
    let t = Number(product.price)
    for (const g of product.modifier_groups) {
      for (const mid of selectedModifierIdsForGroup(g, selected)) {
        const m = g.modifiers.find((x) => x.id === mid)
        if (m) t += Number(m.price_change)
      }
    }
    return t * qty
  })

  async function addToCart() {
    if (adding) return
    const routeProductId = String(params.id ?? "")
    if (!routeProductId || !product || String(product.id) !== routeProductId) {
      error = "Подождите, загружается карточка товара…"
      return
    }
    adding = true
    error = null
    try {
      const { selected_modifiers } = buildModifierPayload(product.modifier_groups, selected)
      await shopAddToCart(
        {
          product_id: routeProductId,
          quantity: qty,
          selected_modifiers
        },
        { product }
      )
      push("/cart")
      window.dispatchEvent(
        new CustomEvent("shop:cart-added", { detail: { name: product.name } })
      )
    } catch (e) {
      error = e.message || "Не удалось добавить в корзину"
    } finally {
      adding = false
    }
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
    <div id={"mod-group-" + g.id} class="mb-4 mod-group">
      <p class="mb-2 text-sm font-medium">{g.name}</p>
      <div class="flex flex-wrap gap-2">
        {#each g.modifiers as m (m.id)}
          <button
            type="button"
            class="mod-chip"
            class:mod-chip--selected={isModifierSelected(g, m.id)}
            onclick={() => toggleModifier(g.id, m.id)}
          >
            {#if isModifierSelected(g, m.id)}
              <span class="mod-chip-plus" aria-hidden="true">+</span>
            {/if}
            <span>{m.name}</span>
            {#if Number(m.price_change) > 0}
              <span class="mod-chip-price">+{m.price_change}₽</span>
            {/if}
          </button>
        {/each}
      </div>
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
      disabled={product.stock <= 0 || adding}
      onclick={addToCart}
    >
      {adding ? "Добавляем…" : "В корзину 🛒"}
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

  .mod-chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    border-radius: 8px;
    border: 1px solid #3a3a3a;
    background: transparent;
    padding: 8px 12px;
    font-size: 14px;
    color: #fff;
    cursor: pointer;
    text-align: left;
  }

  .mod-chip--selected {
    border-color: #ff8c42;
    background: #3a2a1a;
  }

  .mod-chip-plus {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 18px;
    height: 18px;
    border-radius: 4px;
    background: #ff8c42;
    color: #000;
    font-size: 14px;
    font-weight: 700;
    line-height: 1;
    flex-shrink: 0;
  }

  .mod-chip-price {
    color: #ff8c42;
  }
</style>
