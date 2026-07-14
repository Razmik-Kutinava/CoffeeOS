<script>
  /**
   * Список способов оплаты — макет 1000008925.png
   * Шаг 3: сохранённые карты + СБП + «Новая карта» + Pay при выборе.
   */
  import {
    formatCardFullLabel,
    formatCardListLabel,
    cardBrandShort
  } from "../lib/paymentMethodLabels.js"
  import NewCardForm from "./NewCardForm.svelte"

  let {
    open = false,
    cards = [],
    loading = false,
    selectedCardId = null,
    selectionMode = "saved_card", // saved_card | new_card
    canPay = false,
    newCardState = $bindable(undefined),
    onClose = undefined,
    onSelectCard = undefined,
    onSelectNewCard = undefined,
    onPay = undefined
  } = $props()

  let sbpNotice = $state(false)

  const payDisabled = $derived(!canPay || loading)

  function isCardSelected(card) {
    return selectionMode === "saved_card" && selectedCardId === card.id
  }

  function handleSbpClick() {
    sbpNotice = true
  }
</script>

{#if open}
  <div
    class="pm-backdrop"
    role="presentation"
    onclick={() => onClose?.()}
    data-testid="payment-methods-backdrop"
  ></div>
  <section class="pm-sheet" aria-label="Способ оплаты" data-testid="payment-methods-sheet">
    <header class="pm-sheet__header">
      <h2 class="pm-sheet__title">Способ оплаты</h2>
      <button
        type="button"
        class="pm-sheet__close"
        aria-label="Закрыть"
        data-testid="payment-methods-close"
        onclick={() => onClose?.()}
      >
        ×
      </button>
    </header>

    {#if loading}
      <p class="pm-sheet__loading">Загружаем карты…</p>
    {:else}
      <ul class="pm-sheet__list" role="radiogroup" aria-label="Сохранённые карты">
        {#each cards as card (card.id)}
          <li>
            <button
              type="button"
              class="pm-row"
              class:pm-row--selected={isCardSelected(card)}
              role="radio"
              aria-checked={isCardSelected(card)}
              data-testid="payment-method-card-{card.id}"
              onclick={() => onSelectCard?.(card)}
            >
              <span class="pm-row__brand" aria-hidden="true">{cardBrandShort(card.payment_system || card.card_type)}</span>
              <span class="pm-row__label">{formatCardFullLabel(card)}</span>
              <span class="pm-row__hint" aria-hidden="true">{formatCardListLabel(card)}</span>
              <span class="pm-row__radio" aria-hidden="true"></span>
            </button>
          </li>
        {/each}

        <li>
          <button
            type="button"
            class="pm-row pm-row--sbp"
            disabled
            aria-disabled="true"
            data-testid="payment-method-sbp"
            onclick={handleSbpClick}
          >
            <span class="pm-row__brand pm-row__brand--sbp" aria-hidden="true">СБП</span>
            <span class="pm-row__label">СБП</span>
          </button>
        </li>

        <li>
          <button
            type="button"
            class="pm-row"
            class:pm-row--selected={selectionMode === "new_card"}
            role="radio"
            aria-checked={selectionMode === "new_card"}
            data-testid="payment-method-new-card"
            onclick={() => onSelectNewCard?.()}
          >
            <span class="pm-row__label pm-row__label--solo">Новая карта</span>
            <span class="pm-row__chevron" aria-hidden="true">⌄</span>
          </button>
        </li>
      </ul>

      {#if selectionMode === "new_card" && newCardState}
        <div class="pm-new-card" data-testid="checkout-new-card-wrap">
          <NewCardForm bind:state={newCardState} />
        </div>
      {/if}

      {#if sbpNotice}
        <p class="pm-sheet__hint" role="status">Будет позже</p>
      {/if}
    {/if}

    <div class="pm-sheet__pay">
      <button
        type="button"
        class="pm-pay"
        data-testid="payment-methods-pay"
        disabled={payDisabled}
        onclick={() => onPay?.()}
      >
        Оплатить
      </button>
    </div>
  </section>
{/if}


<style>
  .pm-backdrop {
    position: fixed;
    inset: 0;
    z-index: 35;
    background: rgb(0 0 0 / 0.55);
  }

  .pm-sheet {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 40;
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

  .pm-sheet__loading,
  .pm-sheet__hint {
    margin: 0 0 1rem;
    font-size: 0.875rem;
    color: #a0a0a0;
    text-align: center;
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

  .pm-row--selected {
    border-color: #ff8c42;
    box-shadow: inset 0 0 0 1px #ff8c42;
  }

  .pm-row--sbp {
    opacity: 0.55;
    cursor: not-allowed;
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
  }

  .pm-row__hint {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip: rect(0 0 0 0);
  }

  .pm-row__label--solo {
    flex: 1;
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

  .pm-new-card {
    margin-top: 0.75rem;
    padding: 0.75rem;
    border-radius: 0.75rem;
    background: #242424;
  }

  .pm-pay {
    width: 100%;
    border: 0;
    border-radius: 999px;
    background: #ff8c42;
    color: #000;
    font-size: 1.125rem;
    font-weight: 600;
    padding: 1rem;
    cursor: pointer;
  }

  .pm-pay:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
