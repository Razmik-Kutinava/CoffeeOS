<script>
  import { onMount } from "svelte"
  import {
    frequentItems,
    frequentQuantities,
    frequentCardKey,
    setFrequentQty,
    repeatPayOneClickItem,
    repeatFeedback
  } from "../lib/frequentRepeatStore.js"
  import { repeatBumpEmbeddedToCart } from "../lib/repeatEmbeddedCart.js"

  /** full — empty/expanded (скрин 06); embedded — peek с заказом (скрины 01–02: thumb+qty) */
  let { layout = "full" } = $props()

  let items = $state([])
  let storeQty = $state({})
  let brokenUrls = $state(/** @type {Set<string>} */ (new Set()))
  let feedback = $state(null)
  let repeatBusy = $state(false)
  let toastTimer = null

  let topItems = $derived(items.slice(0, 3))
  let embedded = $derived(layout === "embedded")

  onMount(() => {
    const unsubItems = frequentItems.subscribe((v) => { items = Array.isArray(v) ? v : [] })
    const unsubQty = frequentQuantities.subscribe((v) => { storeQty = v || {} })
    const unsubFeedback = repeatFeedback.subscribe((v) => {
      feedback = v
      if (toastTimer) clearTimeout(toastTimer)
      if (v) toastTimer = setTimeout(() => repeatFeedback.set(null), 2500)
    })
    return () => {
      unsubItems(); unsubQty(); unsubFeedback()
      if (toastTimer) clearTimeout(toastTimer)
    }
  })

  function qtyOf(key) {
    return storeQty[key] || 1
  }

  async function bump(item, delta) {
    const key = frequentCardKey(item)
    if (embedded) {
      if (repeatBusy) return
      repeatBusy = true
      try {
        await repeatBumpEmbeddedToCart(item, delta)
      } finally {
        repeatBusy = false
      }
      return
    }
    setFrequentQty(key, qtyOf(key) + delta)
  }

  async function onPayCardClick(item) {
    if (repeatBusy) return
    repeatBusy = true
    try {
      await repeatPayOneClickItem(item)
    } finally {
      repeatBusy = false
    }
  }

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }
</script>

{#if topItems.length}
  <div
    data-testid="shop-repeat-section"
    data-repeat-layout={layout}
    class="shrink-0 px-1 {embedded ? 'pt-1' : 'pt-1.5'}"
  >
    <p class="mb-1 px-1 text-[11px] italic text-[#888]">повторить</p>
    {#if feedback}
      <div
        data-testid="shop-repeat-toast"
        role="status"
        class="mb-1 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-2 py-1 text-[11px] {feedback.type === 'error' ? 'text-red-400' : 'text-[#ff8c42]'}"
      >{feedback.message}</div>
    {/if}
    <div class="flex gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      {#each topItems as item (frequentCardKey(item))}
        {@const key = frequentCardKey(item)}
        {@const url = item.image_url || ""}
        <div
          data-testid="shop-repeat-card"
          class="flex shrink-0 flex-col gap-1 {embedded ? 'w-[4.5rem]' : 'w-[min(28vw,110px)] rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-1.5'}"
        >
          {#if url && !brokenUrls.has(url)}
            <img
              data-testid="shop-repeat-thumb"
              src={url}
              alt=""
              class="{embedded ? 'h-12 w-12' : 'h-12 w-full'} rounded-lg object-cover object-top"
              decoding="async"
              onerror={() => {
                const next = new Set(brokenUrls)
                next.add(url)
                brokenUrls = next
              }}
            />
          {:else}
            <div
              data-testid="shop-repeat-thumb-empty"
              class="flex {embedded ? 'h-12 w-12' : 'h-12 w-full'} items-center justify-center rounded-lg bg-[#333] text-[9px] text-[#888]"
            >Нет фото</div>
          {/if}
          {#if !embedded}
            <p class="line-clamp-1 text-[11px] font-medium leading-tight">{item.name}</p>
            <p class="text-[10px] text-[#ff8c42]">{roundPrice(item.price)}₽</p>
          {/if}
          <div class="mt-0.5 flex items-center justify-between gap-0.5 {embedded ? 'w-12' : ''}">
            <button
              type="button"
              data-testid="shop-repeat-minus"
              class="min-h-6 min-w-6 rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[12px] leading-none disabled:opacity-40"
              disabled={qtyOf(key) <= 1 || repeatBusy}
              onclick={() => bump(item, -1)}
            >−</button>
            <span data-testid="shop-repeat-qty" class="min-w-[1rem] text-center text-[11px] font-medium">{qtyOf(key)}</span>
            <button
              type="button"
              data-testid="shop-repeat-plus"
              class="min-h-6 min-w-6 rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[12px] leading-none disabled:opacity-40"
              disabled={repeatBusy}
              onclick={() => bump(item, 1)}
            >+</button>
          </div>
          {#if !embedded}
            <button
              type="button"
              data-testid="shop-repeat-card-pay"
              class="mt-0.5 min-h-7 w-full rounded-lg bg-[#ff8c42] px-2 py-1 text-[10px] font-semibold text-black disabled:opacity-40"
              disabled={repeatBusy}
              onclick={() => onPayCardClick(item)}
            >оплатить в 1 клик</button>
          {/if}
        </div>
      {/each}
    </div>
  </div>
{/if}
