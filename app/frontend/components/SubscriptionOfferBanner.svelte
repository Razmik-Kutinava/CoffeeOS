<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    bannerVisible,
    buildOfferLink,
    dismissOffer,
    loadOfferProfile,
    markShownOnce,
    trackOfferOpened
  } from "../lib/subscriptionOffer.js"

  let { order } = $props()

  let profile = $state(null)
  let dismissed = $state(false)
  let touchStartX = 0

  const SWIPE_DISMISS_PX = 60

  const visible = $derived(!dismissed && bannerVisible({ order, profile }))

  onMount(async () => {
    profile = await loadOfferProfile()
  })

  $effect(() => {
    if (visible && order?.id) markShownOnce(order.id)
  })

  function onDismiss(event) {
    event?.stopPropagation?.()
    dismissed = true
    dismissOffer()
  }

  function onOpen() {
    if (dismissed) return
    trackOfferOpened("banner")
    push(buildOfferLink("banner"))
  }

  function onKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      onOpen()
    }
  }

  function onTouchStart(event) {
    touchStartX = event.changedTouches?.[0]?.clientX ?? 0
  }

  function onTouchEnd(event) {
    const dx = (event.changedTouches?.[0]?.clientX ?? 0) - touchStartX
    if (Math.abs(dx) > SWIPE_DISMISS_PX) onDismiss()
  }
</script>

{#if visible}
  <div
    class="offer-banner"
    data-testid="subscription-offer-banner"
    role="button"
    tabindex="0"
    onclick={onOpen}
    onkeydown={onKeydown}
    ontouchstart={onTouchStart}
    ontouchend={onTouchEnd}
  >
    <div class="offer-text">
      <p class="offer-title">Кофе по подписке</p>
      <p class="offer-sub">Экономьте на каждом заказе</p>
    </div>
    <button
      type="button"
      class="offer-close"
      data-testid="subscription-offer-banner-close"
      aria-label="Скрыть предложение"
      onclick={onDismiss}
    >
      ×
    </button>
  </div>
{/if}

<style>
  .offer-banner {
    display: flex;
    align-items: center;
    gap: 12px;
    margin: 12px 16px 0;
    padding: 14px 12px 14px 16px;
    border-radius: 14px;
    background: #2a2a2a;
    border: 1px solid #ff8c42;
    color: #fff;
    cursor: pointer;
    touch-action: pan-y;
  }
  .offer-text { flex: 1; min-width: 0; }
  .offer-title { margin: 0; font-size: 15px; font-weight: 700; }
  .offer-sub { margin: 2px 0 0; font-size: 13px; color: #a0a0a0; }
  .offer-close {
    flex-shrink: 0;
    background: none;
    border: none;
    color: #a0a0a0;
    font-size: 22px;
    line-height: 1;
    padding: 4px 8px;
    cursor: pointer;
  }
</style>
