<script>
  /**
   * Список способов оплаты — канон #26 скрин 03 (Картой *XXXX / СБП / Картой +).
   * СБП selectable → Checkout onSelectSbp / onSelectSbpAccount → shopSbpPay.
   */
  import {
    formatCardMaskStar,
    labelCardBy,
    labelAddCard,
    labelSbp,
    labelSbpAccount,
    labelBindSbpAccount,
    ctaSbpFastPay,
    ctaSbpAccountPay,
    paymentMethodLoadErrorMessage,
    paymentMethodRetryLabel
  } from "../lib/paymentMethodI18n.js"
  import { SBP_LOADING_LABEL } from "../lib/shopSbpPay.js"
  import { PAY_FSM, shouldLockPaymentMethods } from "../lib/shopPayFsm.js"
  import NewCardForm from "./NewCardForm.svelte"
  import CheckoutPayButton from "./CheckoutPayButton.svelte"

  let {
    open = false,
    stacked = false,
    cards = [],
    sbpAccounts = [],
    loading = false,
    loadError = null,
    inlineError = null,
    selectedCardId = null,
    selectionMode = "saved_card", // saved_card | new_card | sbp | sbp_account
    saveSbpAccount = $bindable(true),
    canPay = false,
    fsmState = PAY_FSM.DEFAULT,
    newCardState = $bindable(undefined),
    onClose = undefined,
    onSelectCard = undefined,
    onSelectNewCard = undefined,
    onSelectSbp = undefined,
    onSelectSbpAccount = undefined,
    onSaveSbpAccountUserChange = undefined,
    onPay = undefined,
    onRetry = undefined,
    onRetryLoad = undefined,
    onChangeCard = undefined
  } = $props()

  const locked = $derived(shouldLockPaymentMethods(fsmState))
  const payDisabled = $derived(!canPay || loading || locked)
  const hasSbpAccount = $derived(Array.isArray(sbpAccounts) && sbpAccounts.length > 0)
  const idlePayLabel = $derived(
    selectionMode === "sbp"
      ? ctaSbpFastPay()
      : selectionMode === "sbp_account"
        ? ctaSbpAccountPay()
        : null
  )
  const loadingPayLabel = $derived(
    selectionMode === "sbp" || selectionMode === "sbp_account" ? SBP_LOADING_LABEL : null
  )

  function isCardSelected(card) {
    return selectionMode === "saved_card" && selectedCardId === card.id
  }
</script>

{#if open}
  {#if !stacked}
  <div
    class="pm-backdrop"
    role="presentation"
    onclick={() => {
      if (!locked) onClose?.()
    }}
    data-testid="payment-methods-backdrop"
  ></div>
  {/if}
  <section
    class="pm-sheet"
    class:pm-sheet--stacked={stacked}
    aria-label="Способ оплаты"
    data-testid="payment-methods-sheet"
    data-payment-sheet-stacked={stacked ? "true" : "false"}
  >
    <header class="pm-sheet__header">
      <h2 class="pm-sheet__title">Способ оплаты</h2>
      <button
        type="button"
        class="pm-sheet__close"
        aria-label="Закрыть"
        data-testid="payment-methods-close"
        disabled={locked}
        onclick={() => onClose?.()}
      >
        ×
      </button>
    </header>

    {#if loading}
      <p class="pm-sheet__loading">Загружаем карты…</p>
    {:else if loadError}
      <div class="pm-sheet__error-block" data-testid="payment-method-load-retry">
        <p class="pm-sheet__hint" role="status">{loadError || paymentMethodLoadErrorMessage()}</p>
        <button
          type="button"
          class="pm-sheet__retry"
          onclick={() => onRetryLoad?.()}
        >
          {paymentMethodRetryLabel()}
        </button>
      </div>
    {:else}
      <ul class="pm-sheet__list" role="radiogroup" aria-label="Сохранённые карты">
        {#if hasSbpAccount}
          <li>
            <button
              type="button"
              class="pm-row pm-row--sbp"
              class:pm-row--selected={selectionMode === "sbp_account"}
              role="radio"
              aria-checked={selectionMode === "sbp_account"}
              data-testid="payment-method-sbp-account"
              disabled={locked}
              onclick={() => onSelectSbpAccount?.()}
            >
              <span class="pm-row__label pm-row__label--solo">{labelSbpAccount()}</span>
            </button>
          </li>
        {/if}

        {#each cards as card (card.id)}
          <li>
            <button
              type="button"
              class="pm-row"
              class:pm-row--selected={isCardSelected(card)}
              role="radio"
              aria-checked={isCardSelected(card)}
              data-testid="payment-method-card-{card.id}"
              disabled={locked}
              onclick={() => onSelectCard?.(card)}
            >
              <span class="pm-row__label">
                <span class="pm-row__card-prefix">{labelCardBy()}</span>
                <span class="pm-row__card-mask">{formatCardMaskStar(card)}</span>
              </span>
            </button>
          </li>
        {/each}

        <li>
          <button
            type="button"
            class="pm-row pm-row--sbp"
            class:pm-row--selected={selectionMode === "sbp"}
            role="radio"
            aria-checked={selectionMode === "sbp"}
            data-testid="payment-method-sbp"
            disabled={locked}
            onclick={() => onSelectSbp?.()}
          >
            <span class="pm-row__label pm-row__label--solo">{labelSbp()}</span>
          </button>
        </li>

        <li>
          <button
            type="button"
            class="pm-row pm-row--accent"
            class:pm-row--selected={selectionMode === "new_card"}
            role="radio"
            aria-checked={selectionMode === "new_card"}
            data-testid="payment-method-new-card"
            disabled={locked}
            onclick={() => onSelectNewCard?.()}
            aria-label={labelAddCard()}
          >
            <span class="pm-row__card-prefix">{labelCardBy()}</span>
            <span class="pm-row__plus" aria-hidden="true">+</span>
          </button>
        </li>
      </ul>

      {#if selectionMode === "sbp" && !hasSbpAccount}
        <label class="pm-bind-sbp" data-testid="save-sbp-account-checkbox">
          <input
            type="checkbox"
            class="pm-bind-sbp__input"
            checked={saveSbpAccount}
            disabled={locked}
            onchange={(e) => {
              const next = !!e.currentTarget.checked
              saveSbpAccount = next
              onSaveSbpAccountUserChange?.(next)
            }}
          />
          <span class="pm-bind-sbp__text">{labelBindSbpAccount()}</span>
        </label>
      {/if}

      {#if selectionMode === "new_card" && newCardState}
        <div class="pm-new-card" data-testid="checkout-new-card-wrap">
          <NewCardForm bind:state={newCardState} />
        </div>
      {/if}
    {/if}

    {#if inlineError}
      <p class="pm-sheet__inline-error" role="alert" data-testid="payment-method-inline-error">
        {inlineError}
      </p>
    {/if}

    <div class="pm-sheet__pay">
      <CheckoutPayButton
        {fsmState}
        accent="orange"
        disabled={payDisabled && fsmState === PAY_FSM.DEFAULT}
        idleLabel={idlePayLabel}
        loadingLabel={loadingPayLabel}
        onPay={() => onPay?.()}
        onRetry={() => onRetry?.()}
        onChangeCard={() => onChangeCard?.()}
      />
    </div>
  </section>
{/if}


<style>
  .pm-backdrop {
    position: fixed;
    inset: 0;
    z-index: 55;
    background: rgb(0 0 0 / 0.55);
  }

  .pm-sheet {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 56;
    max-height: 90vh;
    overflow: auto;
    border-radius: 1.25rem 1.25rem 0 0;
    background: #1a1a1a;
    border-top: 1px solid #3a3a3a;
    padding: 0.75rem 1rem 1.25rem;
    box-shadow: 0 -8px 32px rgb(0 0 0 / 0.45);
  }

  .pm-sheet__header {
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    margin-bottom: 1rem;
  }

  .pm-sheet__title {
    margin: 0;
    font-size: 1.125rem;
    font-weight: 600;
    color: #fff;
  }

  .pm-sheet__close {
    position: absolute;
    right: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 2rem;
    height: 2rem;
    border: 0;
    border-radius: 999px;
    background: #2a2a2a;
    color: #fff;
    font-size: 1.25rem;
    line-height: 1;
    cursor: pointer;
  }

  .pm-sheet__close:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }

  .pm-sheet__loading,
  .pm-sheet__hint {
    margin: 0 0 1rem;
    font-size: 0.875rem;
    color: #a0a0a0;
    text-align: center;
  }

  .pm-sheet__error-block {
    margin-bottom: 1rem;
    text-align: center;
  }

  .pm-sheet__retry {
    margin-top: 0.5rem;
    border: 1px solid #ff8c42;
    border-radius: 999px;
    background: transparent;
    color: #ff8c42;
    padding: 0.5rem 1rem;
    cursor: pointer;
  }

  .pm-sheet__inline-error {
    margin: 0 0 0.75rem;
    padding: 0.625rem 0.75rem;
    border-radius: 0.5rem;
    background: rgb(127 29 29 / 0.35);
    border: 1px solid rgb(248 113 113 / 0.45);
    color: #fca5a5;
    font-size: 0.875rem;
  }

  .pm-sheet__list {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 0.625rem;
  }

  .pm-row {
    width: 100%;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.875rem 1rem;
    border: 1px solid #3a3a3a;
    border-radius: 0.75rem;
    background: #2a2a2a;
    color: #fff;
    text-align: left;
    cursor: pointer;
    position: relative;
  }

  .pm-row:disabled {
    opacity: 0.55;
    cursor: not-allowed;
  }

  .pm-row--selected {
    border-color: #ff8c42;
    box-shadow: inset 0 0 0 1px #ff8c42;
  }

  .pm-row--accent {
    border-color: #ff8c42;
  }

  .pm-row--sbp .pm-row__brand--sbp {
    color: #6fcf97;
  }

  .pm-bind-sbp {
    display: flex;
    align-items: flex-start;
    gap: 0.625rem;
    margin-top: 0.75rem;
    padding: 0.75rem 0.25rem;
    cursor: pointer;
    color: #e0e0e0;
    font-size: 0.875rem;
    line-height: 1.35;
  }

  .pm-bind-sbp__input {
    margin-top: 0.15rem;
    width: 1.05rem;
    height: 1.05rem;
    accent-color: #ff8c42;
    flex-shrink: 0;
  }

  .pm-bind-sbp__text {
    flex: 1;
  }

  .pm-row__brand {
    flex-shrink: 0;
    min-width: 2.5rem;
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: #e0e0e0;
  }

  .pm-row__brand--sbp {
    color: #6fcf97;
  }

  .pm-row__label {
    flex: 1;
    font-size: 1rem;
    font-weight: 500;
    display: flex;
    align-items: baseline;
    gap: 0.35rem;
  }

  .pm-row__label--solo {
    flex: 1;
  }

  .pm-row__card-prefix {
    color: #ff8c42;
    font-weight: 600;
  }

  .pm-row__card-mask {
    color: #fff;
    font-weight: 500;
  }

  .pm-row__plus {
    margin-left: auto;
    color: #fff;
    font-size: 1.25rem;
    font-weight: 600;
    line-height: 1;
  }

  .pm-row__radio {
    width: 1.125rem;
    height: 1.125rem;
    border-radius: 999px;
    border: 2px solid #757575;
    flex-shrink: 0;
  }

  .pm-row--selected .pm-row__radio {
    border-color: #ff8c42;
    background: radial-gradient(circle at center, #ff8c42 0 45%, transparent 46%);
  }

  .pm-row__chevron {
    color: #ff8c42;
    font-size: 1.25rem;
    line-height: 1;
    transform: rotate(-90deg);
  }

  .pm-sheet__pay {
    margin-top: 1.25rem;
  }

  .pm-sheet--stacked {
    z-index: 51;
    max-height: none;
    height: calc(var(--checkout-pay-stack-h, 92vh) - var(--checkout-cart-peek-h, 15vh));
    border-radius: 0;
    border-top: 1px solid #3a3a3a;
    box-shadow: none;
  }

  .pm-new-card {
    margin-top: 0.75rem;
    padding: 0.75rem;
    border-radius: 0.75rem;
    background: #242424;
  }
</style>
