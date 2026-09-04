<script>
  /**
   * #41 / #77 — изолированный блок CTA справа от progress bar.
   * Маппинг только через orderStatusCtas; клики → onAction(kind).
   */
  import { onMount } from "svelte"
  import { orderStatusCtas } from "../lib/orderStatusCtaMachine.js"
  import {
    ACTION_CTA_STYLE,
    ORDER_ACTION_TEST_IDS
  } from "../lib/orderActionButtons.js"
  import {
    loadSubscriptionOfferCta,
    subscriptionOfferCtaDefaults
  } from "../lib/subscriptionOfferCta.js"

  let {
    status = "",
    os = "desktop",
    canCancel = false,
    hasPushSubscription = false,
    isLoading = false,
    onAction = undefined
  } = $props()

  let offerCta = $state(subscriptionOfferCtaDefaults())

  onMount(() => {
    loadSubscriptionOfferCta().then((v) => {
      if (v) offerCta = v
    })
  })

  let view = $derived(
    orderStatusCtas({
      status,
      os,
      canCancel,
      hasPushSubscription,
      subscriptionOfferEnabled: offerCta.subscriptionOfferEnabled,
      secondCtaMode: offerCta.secondCtaMode,
      eligibleForSubscriptionOffer: offerCta.eligibleForSubscriptionOffer
    })
  )

  function handleClick(kind) {
    if (isLoading) return
    if (typeof onAction === "function") onAction(kind)
  }
</script>

{#if view.buttons.length > 0}
  <div
    class={ACTION_CTA_STYLE.actionsClass}
    data-testid={ORDER_ACTION_TEST_IDS.root}
    style:width="{ACTION_CTA_STYLE.actionsWidthRem}rem"
    style:gap="{ACTION_CTA_STYLE.actionsGapRem}rem"
  >
    {#each view.buttons as btn (btn.kind)}
      <button
        type="button"
        class={ACTION_CTA_STYLE.buttonClass}
        data-kind={btn.kind}
        data-testid={ORDER_ACTION_TEST_IDS.button}
        disabled={isLoading}
        style:background={ACTION_CTA_STYLE.background}
        style:color={ACTION_CTA_STYLE.color}
        style:font-weight={ACTION_CTA_STYLE.fontWeight}
        style:min-height="{ACTION_CTA_STYLE.heightPx}px"
        style:border-radius={ACTION_CTA_STYLE.borderRadius}
        style:font-size="{ACTION_CTA_STYLE.fontSizeRem}rem"
        onclick={() => handleClick(btn.kind)}
      >
        {#if isLoading}…{:else}
          {btn.label}{#if btn.hint}<span class="oab__hint">{btn.hint}</span>{/if}
        {/if}
      </button>
    {/each}
  </div>
{/if}

<style>
  .oab__actions {
    display: flex;
    flex-direction: column;
    flex-shrink: 0;
    max-width: 100%;
    box-sizing: border-box;
  }
  .oab__btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    box-sizing: border-box;
    width: 100%;
    min-height: 44px;
    padding: 0.35rem 0.45rem;
    border: 0;
    cursor: pointer;
    text-align: center;
    line-height: 1.15;
    white-space: normal;
    word-break: break-word;
    overflow-wrap: anywhere;
  }
  .oab__btn:disabled {
    opacity: 0.85;
    cursor: default;
  }
  .oab__hint {
    display: block;
    font-size: 0.55rem;
    font-weight: 500;
    opacity: 0.9;
    margin-top: 0.1rem;
  }
  @media (max-width: 767px) {
    .oab__btn {
      min-height: 44px;
    }
  }
</style>
