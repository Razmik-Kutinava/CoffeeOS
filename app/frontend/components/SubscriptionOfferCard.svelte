<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    buildOfferLink,
    lkCardView,
    loadHasActiveSubscription,
    loadOfferProfile,
    markOfferViewed,
    readOfferParams,
    trackOfferOpened
  } from "../lib/subscriptionOffer.js"

  let profile = $state(null)
  let hasActiveSubscription = $state(null)
  let expanded = $state(false)
  let unreadCleared = $state(false)

  const view = $derived(lkCardView({ profile, hasActiveSubscription }))
  const unread = $derived(view.unread && !unreadCleared)

  onMount(async () => {
    const params = readOfferParams(typeof window !== "undefined" ? window.location.hash : "")
    if (params?.channel === "push") {
      trackOfferOpened("push", { extra: { push_notification_id: params.push_notification_id } })
    }

    const [p, sub] = await Promise.all([loadOfferProfile(), loadHasActiveSubscription()])
    profile = p
    hasActiveSubscription = sub
  })

  function toggle() {
    expanded = !expanded
    if (expanded && unread) {
      unreadCleared = true
      markOfferViewed()
    }
  }

  function openOffer() {
    trackOfferOpened("lk")
    push(buildOfferLink("lk"))
  }
</script>

{#if view.visible}
  <section class="offer-card" data-testid="subscription-offer-card">
    <button type="button" class="offer-head" aria-expanded={expanded} onclick={toggle}>
      <span class="offer-title">Кофе по подписке</span>
      {#if unread}
        <span class="offer-unread" data-testid="subscription-offer-unread" aria-label="Новое предложение"></span>
      {/if}
      <span class="offer-chevron" aria-hidden="true">{expanded ? "▴" : "▾"}</span>
    </button>
    {#if expanded}
      <div class="offer-body">
        <p>Оформите подписку и экономьте на каждом заказе.</p>
        <button type="button" class="offer-cta" data-testid="subscription-offer-card-open" onclick={openOffer}>
          Подробнее
        </button>
      </div>
    {/if}
  </section>
{/if}

<style>
  .offer-card { margin: 8px 16px; background: #2a2a2a; border-radius: 12px; overflow: hidden; }
  .offer-head {
    width: 100%;
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 14px 12px;
    background: none;
    border: none;
    color: #fff;
    text-align: left;
    cursor: pointer;
  }
  .offer-title { flex: 1; font-size: 15px; font-weight: 700; }
  .offer-unread { width: 8px; height: 8px; border-radius: 50%; background: #ff8c42; flex-shrink: 0; }
  .offer-chevron { color: #a0a0a0; font-size: 14px; }
  .offer-body { padding: 0 12px 14px; color: #ddd; font-size: 14px; }
  .offer-body p { margin: 0 0 10px; }
  .offer-cta {
    background: #ff8c42;
    color: #fff;
    border: none;
    border-radius: 12px;
    padding: 10px 20px;
    font-weight: 600;
    cursor: pointer;
  }
</style>
