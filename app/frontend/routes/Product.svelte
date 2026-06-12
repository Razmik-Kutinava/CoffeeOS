<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { addToCart as shopAddToCart } from "../lib/shopCartAdd.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import { favorites } from "../lib/stores/favorites.js"
  import {
    isRadioModifierGroup,
    defaultSelectionForGroup,
    buildModifierPayload
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
  let showOnboardingHint = $state(false)
  let modifierHint = $state(null)
  let highlightGroupId = $state(null)

  function isRequiredGroup(g) {
    return g.modifier_type === "required"
  }

  function isGroupFilled(g) {
    if (!isRequiredGroup(g)) return true
    if (isRadioModifierGroup(g)) return !!selected[g.id]
    return (selected[g.id] || []).length > 0
  }

  function missingRequiredGroups() {
    if (!product?.modifier_groups) return []
    return product.modifier_groups.filter((g) => isRequiredGroup(g) && !isGroupFilled(g))
  }

  async function loadProduct(keepSelections = false) {
    const prev = keepSelections ? { ...selected } : {}
    const p = await api(`/products/${params.id}`)
    product = p
    for (const g of product.modifier_groups) {
      if (prev[g.id] !== undefined) selected[g.id] = prev[g.id]
      else selected[g.id] = defaultSelectionForGroup(g)
    }
    selected = { ...selected }
  }

  onMount(async () => {
    showOnboardingHint = !sessionStorage.getItem("shop_onboarding_dismissed")
    let pollTimer
    const tick = async () => {
      try {
        await loadProduct(true)
      } catch {
        /* keep last product */
      }
    }
    try {
      await loadProduct(false)
      await favorites.load()
      isFav = favorites.isFavorite(product.id)
      pollTimer = setInterval(tick, PRODUCT_POLL_MS)
      const onVisible = () => {
        if (document.visibilityState === "visible") tick()
      }
      document.addEventListener("visibilitychange", onVisible)
      return () => {
        clearInterval(pollTimer)
        document.removeEventListener("visibilitychange", onVisible)
      }
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
      if (isRadioModifierGroup(g)) {
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

  function dismissOnboarding() {
    sessionStorage.setItem("shop_onboarding_dismissed", "1")
    showOnboardingHint = false
  }

  async function addToCart() {
    if (adding) return
    const missing = missingRequiredGroups()
    if (missing.length > 0) {
      const g = missing[0]
      highlightGroupId = g.id
      modifierHint = `Выберите: ${g.name}`
      g.id && document.getElementById(`mod-group-${g.id}`)?.scrollIntoView({ behavior: "smooth", block: "center" })
      return
    }
    modifierHint = null
    highlightGroupId = null
    dismissOnboarding()
    adding = true
    try {
    const { selected_modifiers, removed_modifiers } = buildModifierPayload(
      product.modifier_groups,
      selected
    )
    await shopAddToCart(
      {
        product_id: product.id,
        quantity: qty,
        selected_modifiers
      },
      { product }
    )
    push("/cart")
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

  {#if showOnboardingHint && product.modifier_groups?.some(isRequiredGroup)}
    <div class="onboarding-banner mb-4 rounded-xl border border-[#ff8c42]/40 bg-[#3a2a1a] px-3 py-2 text-sm text-[#e8c4a8]">
      Сначала выберите параметры с пометкой <strong>обязательно</strong> (вкус, температура и т.д.), затем «В корзину».
      <button type="button" class="onboarding-dismiss" onclick={dismissOnboarding}>Понятно</button>
    </div>
  {/if}

  {#if modifierHint}
    <p class="modifier-hint mb-3" role="alert">{modifierHint}</p>
  {/if}

  {#each product.modifier_groups as g (g.id)}
    <div
      id={"mod-group-" + g.id}
      class="mb-4 mod-group"
      class:mod-group--highlight={highlightGroupId === g.id}
    >
      <p class="mb-2 text-sm font-medium">
        {g.name}
        {#if g.modifier_type === "required"}
          <span class="ml-1 text-xs font-normal text-[#888]">· обязательно</span>
        {/if}
      </p>
      {#if isRadioModifierGroup(g)}
        <div class="flex flex-wrap gap-2">
          {#each g.modifiers as m (m.id)}
            <label class="cursor-pointer">
              <input
                type="radio"
                name={"mg-" + g.id}
                checked={selected[g.id] === m.id}
                onchange={() => { selected[g.id] = m.id; selected = { ...selected }; highlightGroupId = null; modifierHint = null }}
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

  .onboarding-banner {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .onboarding-dismiss {
    align-self: flex-start;
    background: none;
    border: none;
    color: #ff8c42;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    padding: 0;
  }

  .modifier-hint {
    color: #ff8c42;
    font-size: 14px;
    font-weight: 600;
  }

  .mod-group--highlight {
    border-radius: 12px;
    outline: 2px solid #ff8c42;
    outline-offset: 4px;
    padding: 4px;
  }
</style>
