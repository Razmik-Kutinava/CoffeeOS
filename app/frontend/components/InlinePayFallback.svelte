<script>
  /**
   * Inline pay UI по скрину заказчика (#32/#33):
   * оранжевая плашка статусов → белые «СБП»/«карта +» → expanded cards → NewCardForm.
   */
  import { WIDGET_FSM_STATES } from "../lib/shopWidgetPayFsm.js"
  import { WIDGET_STATUS_LABELS } from "../lib/widgetInlinePay.js"
  import NewCardForm from "./NewCardForm.svelte"

  let {
    fsmState = WIDGET_FSM_STATES.IDLE,
    statusText = "",
    errorText = "",
    savedCards = [],
    showFallbackMethods = false,
    showExpandedCards = false,
    showNewCardForm = false,
    onSelectSbp = undefined,
    onSelectCardPlus = undefined,
    onSelectSavedCard = undefined,
    onClose = undefined
  } = $props()

  let processing = $derived(fsmState === WIDGET_FSM_STATES.PROCESSING)
  let fallback = $derived(fsmState === WIDGET_FSM_STATES.FALLBACK)
  let success = $derived(fsmState === WIDGET_FSM_STATES.SUCCESS)
  let error = $derived(fsmState === WIDGET_FSM_STATES.ERROR)
  let visible = $derived(processing || fallback || success || error)

  let displayText = $derived(
    processing ? (statusText || WIDGET_STATUS_LABELS.PROCESSING) :
    success ? WIDGET_STATUS_LABELS.SUCCESS :
    error ? (errorText || WIDGET_STATUS_LABELS.ERROR) :
    fallback ? (errorText || WIDGET_STATUS_LABELS.ERROR) :
    ""
  )
</script>

{#if visible}
  <div data-testid="inline-pay-fallback" class="mt-1 w-full min-w-[12rem] space-y-1.5">
    <!-- Плашка статуса (скрин: оранжевая кнопка на всю ширину) -->
    <div
      data-testid="inline-pay-status-bar"
      class="flex min-h-10 items-center justify-center rounded-xl px-3 py-2.5 text-[13px] font-semibold
        {success ? 'bg-green-600 text-white' :
         error || fallback ? 'bg-[#ff8c42] text-black' :
         'bg-[#ff8c42] text-black'}"
      aria-busy={processing}
    >
      {#if processing}
        <span class="mr-2 inline-block h-3.5 w-3.5 animate-spin rounded-full border-2 border-black border-t-transparent"></span>
      {/if}
      {displayText}
    </div>

    <!-- Скрин: белые кнопки «СБП» / «карта +» -->
    {#if showFallbackMethods}
      <div data-testid="inline-fallback-methods" class="flex gap-2">
        <button
          type="button"
          data-testid="inline-fallback-sbp"
          class="flex-1 rounded-lg bg-white px-3 py-2.5 text-center text-[13px] font-semibold text-black"
          onclick={() => onSelectSbp?.()}
        >СБП</button>
        <button
          type="button"
          data-testid="inline-fallback-card-plus"
          class="flex-1 rounded-lg bg-white px-3 py-2.5 text-center text-[13px] font-semibold text-black"
          onclick={() => onSelectCardPlus?.()}
        >карта +</button>
      </div>
    {/if}

    <!-- Expanded: «Картой *XXXX» с оранжевой обводкой -->
    {#if showExpandedCards}
      <div data-testid="inline-expanded-cards" class="space-y-1.5">
        {#each savedCards as card (card.id)}
          <button
            type="button"
            data-testid="inline-saved-card"
            class="w-full rounded-lg border border-[#ff8c42] bg-[#1a1a1a] px-3 py-2.5 text-left text-[13px] font-medium text-[#ff8c42]"
            onclick={() => onSelectSavedCard?.(card)}
          >Картой *{card.last4 || card.last_4 || "????"}</button>
        {/each}
      </div>
    {/if}

    {#if showNewCardForm}
      <div data-testid="inline-new-card-wrap" class="rounded-xl border border-[#3a3a3a] bg-[#1a1a1a] p-2">
        <NewCardForm />
      </div>
    {/if}
  </div>
{/if}
