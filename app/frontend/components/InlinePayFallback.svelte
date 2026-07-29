<script>
  /**
   * Inline fallback при ошибке one-click (#33 Шаг 5–6).
   * Показывает: плашку «статусы от банка» / ошибку → кнопки «СБП» / «карта +» → expanded cards.
   */
  import { WIDGET_FSM_STATES } from "../lib/shopWidgetPayFsm.js"
  import { WIDGET_STATUS_LABELS } from "../lib/widgetInlinePay.js"

  let {
    fsmState = WIDGET_FSM_STATES.IDLE,
    statusText = "",
    errorText = "",
    savedCards = [],
    showFallbackMethods = false,
    showExpandedCards = false,
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
  <div data-testid="inline-pay-fallback" class="mt-1 space-y-1.5">
    <!-- Плашка статуса -->
    <div
      data-testid="inline-pay-status-bar"
      class="flex items-center justify-center rounded-lg px-3 py-2 text-[12px] font-semibold
        {success ? 'bg-green-600 text-white' :
         error || fallback ? 'bg-[#ff8c42] text-black' :
         'bg-[#ff8c42] text-black'}"
    >
      {#if processing}
        <span class="mr-2 inline-block h-3 w-3 animate-spin rounded-full border-2 border-black border-t-transparent"></span>
      {/if}
      {displayText}
    </div>

    <!-- Fallback: кнопки «СБП» / «карта +» -->
    {#if showFallbackMethods}
      <div data-testid="inline-fallback-methods" class="flex gap-2">
        <button
          type="button"
          data-testid="inline-fallback-sbp"
          class="flex-1 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-3 py-2 text-center text-[12px] font-medium text-white"
          onclick={() => onSelectSbp?.()}
        >СБП</button>
        <button
          type="button"
          data-testid="inline-fallback-card-plus"
          class="flex-1 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-3 py-2 text-center text-[12px] font-medium text-white"
          onclick={() => onSelectCardPlus?.()}
        >карта +</button>
      </div>
    {/if}

    <!-- Expanded: сохранённые карты -->
    {#if showExpandedCards}
      <div data-testid="inline-expanded-cards" class="space-y-1">
        {#each savedCards as card (card.id)}
          <button
            type="button"
            data-testid="inline-saved-card"
            class="w-full rounded-lg border border-[#ff8c42] bg-[#1f1f1f] px-3 py-2 text-left text-[12px] font-medium text-[#ff8c42]"
            onclick={() => onSelectSavedCard?.(card)}
          >Картой *{card.last4}</button>
        {/each}
      </div>
    {/if}
  </div>
{/if}
