<script>
  /**
   * Форма новой карты (+ опционально SMS-пинпад для inline #32).
   */
  import {
    createNewCardFormState,
    applyPanInput,
    applyExpInput,
    applyCvvInput,
    setSaveCard,
    isPayEnabled
  } from "../lib/shopNewCardForm.js"
  import { createSmsPinPadState, isSmsCodeComplete } from "../lib/shopSmsPinPad.js"
  import SmsPinPad from "./SmsPinPad.svelte"

  let {
    state = $bindable(createNewCardFormState()),
    smsState = $bindable(createSmsPinPadState()),
    showSmsPinPad = false,
    onchange = undefined,
    onPay = undefined
  } = $props()

  const cardReady = $derived(isPayEnabled(state))
  const payEnabled = $derived(
    showSmsPinPad ? cardReady && isSmsCodeComplete(smsState) : cardReady
  )

  function emit(next) {
    state = next
    onchange?.(next)
  }

  function onPanInput(e) {
    emit(applyPanInput(state, e.currentTarget.value))
  }

  function onExpInput(e) {
    emit(applyExpInput(state, e.currentTarget.value))
  }

  function onCvvInput(e) {
    emit(applyCvvInput(state, e.currentTarget.value))
  }

  function onSaveToggle(e) {
    emit(setSaveCard(state, e.currentTarget.checked))
  }

  function handlePay() {
    if (!payEnabled) return
    onPay?.({ card: state, smsCode: showSmsPinPad ? smsState.code : null })
  }
</script>

<div class="new-card-form" data-testid="shop-new-card-form" data-pay-enabled={payEnabled}>
  <label class="field">
    <span class="label">Номер карты</span>
    <input
      data-testid="shop-new-card-pan"
      type="text"
      inputmode="numeric"
      autocomplete="cc-number"
      maxlength="23"
      placeholder="0000 0000 0000 0000"
      value={state.pan_masked}
      oninput={onPanInput}
    />
  </label>

  <div class="row">
    <label class="field">
      <span class="label">ММ/ГГ</span>
      <input
        data-testid="shop-new-card-exp"
        type="text"
        inputmode="numeric"
        autocomplete="cc-exp"
        maxlength="5"
        placeholder="ММ/ГГ"
        value={state.exp_date}
        oninput={onExpInput}
      />
    </label>

    <label class="field">
      <span class="label">CMC/CVV</span>
      <input
        data-testid="shop-new-card-cvv"
        type="password"
        inputmode="numeric"
        autocomplete="cc-csc"
        maxlength="4"
        placeholder="CVV"
        value={state.cvv}
        oninput={onCvvInput}
      />
    </label>
  </div>

  <label class="toggle" data-testid="shop-new-card-save-toggle">
    <input type="checkbox" checked={state.save_card} onchange={onSaveToggle} />
    <span>
      Использовать карту для будущих заказов
      {#if showSmsPinPad}
        <small>Это безопасно, данные зашифрованы</small>
      {/if}
    </span>
  </label>

  {#if showSmsPinPad}
    <SmsPinPad bind:state={smsState} />
    <button
      type="button"
      class="pay-btn"
      data-testid="shop-new-card-pay"
      disabled={!payEnabled}
      onclick={handlePay}
    >Оплатить</button>
  {:else}
    <p class="pay-hint" hidden={!payEnabled} data-testid="shop-new-card-pay-ready">
      Готово к оплате
    </p>
  {/if}
</div>

<style>
  .new-card-form {
    display: flex;
    flex-direction: column;
    gap: 0.65rem;
  }
  .row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.5rem;
  }
  .field {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }
  .label {
    font-size: 0.75rem;
    color: #6b7280;
  }
  input[type="text"],
  input[type="password"] {
    border: 1px solid #d1d5db;
    border-radius: 0.5rem;
    padding: 0.65rem 0.75rem;
    font-size: 1rem;
  }
  .toggle {
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
    font-size: 0.875rem;
  }
  .toggle small {
    display: block;
    margin-top: 0.15rem;
    color: #888;
    font-size: 0.7rem;
  }
  .pay-hint {
    font-size: 0.75rem;
    color: #059669;
    margin: 0;
  }
  .pay-btn {
    align-self: flex-end;
    min-width: 7rem;
    border: 0;
    border-radius: 0.75rem;
    padding: 0.7rem 1rem;
    background: #ff8c42;
    color: #111;
    font-weight: 700;
    cursor: pointer;
  }
  .pay-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
</style>
