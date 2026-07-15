<script>
  /**
   * Форма новой карты — макет 1000008924.png
   * Логика валидации / save_card — в shopNewCardForm.js
   */
  import {
    createNewCardFormState,
    applyPanInput,
    applyExpInput,
    applyCvvInput,
    setSaveCard,
    isPayEnabled
  } from "../lib/shopNewCardForm.js"

  let {
    state = $bindable(createNewCardFormState()),
    onchange = undefined
  } = $props()

  const payEnabled = $derived(isPayEnabled(state))

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
    <input
      type="checkbox"
      checked={state.save_card}
      onchange={onSaveToggle}
    />
    <span>Использовать карту для будущих заказов</span>
  </label>

  <!-- Кнопка «Оплатить» активируется снаружи по isPayEnabled / data-pay-enabled -->
  <p class="pay-hint" hidden={!payEnabled} data-testid="shop-new-card-pay-ready">
    Готово к оплате
  </p>
</div>

<style>
  .new-card-form {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }
  .row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.75rem;
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
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
  }
  .pay-hint {
    font-size: 0.75rem;
    color: #059669;
    margin: 0;
  }
</style>
