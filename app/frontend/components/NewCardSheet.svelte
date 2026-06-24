<script>
  import { api } from "../lib/api.js"
  import {
    formatPanInput,
    formatExpiryInput,
    validateCardFields,
    assertNoPlainCardInPayload
  } from "../lib/tbankCardFormat.js"
  import { encryptCardPayload } from "../lib/tbankCardEncrypt.js"
  import { clearCartCache } from "../lib/shopCartCache.js"
  import { saveGuestOrderSession } from "../lib/shopGuestSession.js"
  import CheckoutPayButton from "./CheckoutPayButton.svelte"
  import {
    PAY_FSM,
    MIN_LOADER_MS,
    withMinLoaderMs,
    apiWithPayTimeout,
    fsmFromPaymentError,
    isPayFsmClickable
  } from "../lib/shopPayFsm.js"

  let {
    open = false,
    name = "",
    email = "",
    cardHolderName = "",
    fsmState = PAY_FSM.DEFAULT,
    onFsmChange = () => {},
    onClose = () => {},
    onSuccess = () => {},
    onThreeDs = () => {}
  } = $props()

  let pan = $state("")
  let expiry = $state("")
  let cvv = $state("")
  let saveCard = $state(true)
  let touched = $state(false)
  let submitting = $state(false)
  let fieldErrors = $state({})
  let rsaPublicKey = $state(null)
  let configLoading = $state(false)
  let configError = $state(null)

  const validation = $derived(validateCardFields({ pan, expiry, cvv }))
  const canSubmit = $derived(
    open &&
      validation.valid &&
      !submitting &&
      !configLoading &&
      rsaPublicKey &&
      !configError &&
      isPayFsmClickable(fsmState)
  )

  async function loadCryptoConfig() {
    if (rsaPublicKey || configLoading) return
    configLoading = true
    configError = null
    try {
      const res = await api("/payments/card_config")
      if (!res?.card_data_ready || !res?.rsa_public_key) {
        configError = "Оплата новой картой временно недоступна"
        return
      }
      rsaPublicKey = res.rsa_public_key
    } catch (e) {
      configError = e.message || "Не удалось загрузить настройки оплаты"
    } finally {
      configLoading = false
    }
  }

  $effect(() => {
    if (open) {
      touched = false
      fieldErrors = {}
      loadCryptoConfig()
    }
  })

  function refreshFieldErrors() {
    fieldErrors = validateCardFields({ pan, expiry, cvv }).errors
  }

  function onPanInput(event) {
    pan = formatPanInput(event.currentTarget.value)
    if (touched) refreshFieldErrors()
  }

  function onExpiryInput(event) {
    expiry = formatExpiryInput(event.currentTarget.value)
    if (touched) refreshFieldErrors()
  }

  function onCvvInput(event) {
    cvv = event.currentTarget.value.replace(/\D/g, "").slice(0, 4)
    if (touched) refreshFieldErrors()
  }

  function closeSheet() {
    if (submitting || !isPayFsmClickable(fsmState)) return
    onClose()
  }

  async function submit() {
    touched = true
    refreshFieldErrors()
    if (!validation.valid || !rsaPublicKey || !isPayFsmClickable(fsmState)) return

    submitting = true
    onFsmChange(PAY_FSM.CONNECTING)

    try {
      const card_data = encryptCardPayload(
        {
          pan,
          expDate: validation.expDate,
          cvv,
          cardHolder: cardHolderName || name
        },
        rsaPublicKey
      )

      const body = {
        name,
        email: email.trim().toLowerCase(),
        payment_method: "card",
        card_data,
        save_card: saveCard
      }
      assertNoPlainCardInPayload(body, pan, cvv)

      const res = await withMinLoaderMs(MIN_LOADER_MS, async () => {
        onFsmChange(PAY_FSM.CONNECTING)
        const payload = await apiWithPayTimeout(api, "/payments/new_card", {
          method: "POST",
          body: JSON.stringify(body)
        })
        onFsmChange(PAY_FSM.PROCESSING)
        return payload
      })

      saveGuestOrderSession(res.order_id, res.reconnect_token)
      clearCartCache()

      if (res.tbank_status === "3DS_CHECKING" && res.three_ds?.acs_url) {
        onThreeDs(res)
        return
      }

      onSuccess(res)
    } catch (e) {
      onFsmChange(fsmFromPaymentError(e, { httpStatus: e.httpStatus }))
    } finally {
      submitting = false
    }
  }
</script>

{#if open}
  <div
    class="new-card-backdrop"
    role="presentation"
    onclick={closeSheet}
    data-testid="new-card-sheet-backdrop"
  ></div>
  <section
    class="new-card-sheet"
    aria-label="Новая карта"
    data-testid="new-card-sheet"
  >
    <div class="new-card-sheet__handle" aria-hidden="true"></div>

    <div class="new-card-sheet__fields">
      <label class="new-card-field" class:new-card-field--error={fieldErrors.pan}>
        <span class="sr-only">Номер карты</span>
        <input
          type="text"
          inputmode="numeric"
          autocomplete="cc-number"
          placeholder="Номер карты"
          value={pan}
          oninput={onPanInput}
          class="new-card-input"
          data-testid="new-card-pan"
        />
        {#if fieldErrors.pan}
          <span class="new-card-field__error">{fieldErrors.pan}</span>
        {/if}
      </label>

      <div class="new-card-sheet__row">
        <label class="new-card-field new-card-field--half" class:new-card-field--error={fieldErrors.expiry}>
          <span class="sr-only">Срок действия</span>
          <input
            type="text"
            inputmode="numeric"
            autocomplete="cc-exp"
            placeholder="ММ / ГГ"
            value={expiry}
            oninput={onExpiryInput}
            class="new-card-input"
            data-testid="new-card-expiry"
          />
          {#if fieldErrors.expiry}
            <span class="new-card-field__error">{fieldErrors.expiry}</span>
          {/if}
        </label>

        <label class="new-card-field new-card-field--grow" class:new-card-field--error={fieldErrors.cvv}>
          <span class="sr-only">CVC/CVV</span>
          <input
            type="password"
            inputmode="numeric"
            autocomplete="cc-csc"
            placeholder="CVC/CVV"
            value={cvv}
            oninput={onCvvInput}
            class="new-card-input"
            data-testid="new-card-cvv"
          />
          {#if fieldErrors.cvv}
            <span class="new-card-field__error">{fieldErrors.cvv}</span>
          {/if}
        </label>
      </div>
    </div>

    <div class="new-card-sheet__save">
      <div class="new-card-sheet__save-text">
        <span class="new-card-sheet__lock" aria-hidden="true">🔒</span>
        <div>
          <p class="new-card-sheet__save-title">Использовать карту для будущих заказов</p>
          <p class="new-card-sheet__save-hint">Это безопасно, данные зашифрованы</p>
        </div>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={saveCard}
        aria-label="Использовать карту для будущих заказов"
        class="new-card-toggle"
        class:new-card-toggle--on={saveCard}
        data-testid="new-card-save-toggle"
        onclick={() => {
          saveCard = !saveCard
        }}
      >
        <span class="new-card-toggle__thumb"></span>
      </button>
    </div>

    {#if configError}
      <p class="new-card-sheet__banner new-card-sheet__banner--error" role="status">{configError}</p>
    {/if}

    <div class="new-card-sheet__badges" aria-hidden="true">
      <span>Visa</span>
      <span>Mastercard</span>
      <span>Мир</span>
      <span>3-D Secure</span>
    </div>

    <div class="new-card-sheet__pay-wrap">
      <CheckoutPayButton
        fsmState={configLoading ? PAY_FSM.CONNECTING : fsmState}
        disabled={!canSubmit && fsmState === PAY_FSM.DEFAULT}
        onPay={submit}
        onRetry={submit}
      />
    </div>

    <button type="button" class="new-card-sheet__cancel" onclick={closeSheet}>Отмена</button>
  </section>
{/if}

<style>
  .new-card-backdrop {
    position: fixed;
    inset: 0;
    z-index: 40;
    background: rgb(0 0 0 / 0.55);
  }

  .new-card-sheet {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 50;
    border-radius: 1.25rem 1.25rem 0 0;
    background: #1a1a1a;
    border-top: 1px solid #3a3a3a;
    padding: 0.75rem 1rem 1.25rem;
    box-shadow: 0 -8px 32px rgb(0 0 0 / 0.45);
  }

  .new-card-sheet__handle {
    width: 2.5rem;
    height: 0.25rem;
    margin: 0 auto 1rem;
    border-radius: 999px;
    background: #4a4a4a;
  }

  .new-card-sheet__fields {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .new-card-sheet__row {
    display: flex;
    gap: 0.75rem;
  }

  .new-card-field {
    display: block;
  }

  .new-card-field--half {
    flex: 0 0 42%;
  }

  .new-card-field--grow {
    flex: 1;
  }

  .new-card-input {
    width: 100%;
    border-radius: 0.75rem;
    border: 1px solid #fff;
    background: transparent;
    color: #fff;
    padding: 0.875rem 1rem;
    font-size: 1rem;
    outline: none;
  }

  .new-card-field--error .new-card-input {
    border-color: #f87171;
  }

  .new-card-field__error {
    display: block;
    margin-top: 0.25rem;
    font-size: 0.75rem;
    color: #f87171;
  }

  .new-card-sheet__save {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    margin-top: 1.25rem;
    padding-top: 1rem;
    border-top: 1px solid #3a3a3a;
  }

  .new-card-sheet__save-text {
    display: flex;
    align-items: flex-start;
    gap: 0.625rem;
    min-width: 0;
  }

  .new-card-sheet__lock {
    font-size: 1rem;
    line-height: 1.25rem;
  }

  .new-card-sheet__save-title {
    margin: 0;
    font-size: 0.9375rem;
    font-weight: 500;
    color: #fff;
  }

  .new-card-sheet__save-hint {
    margin: 0.125rem 0 0;
    font-size: 0.75rem;
    color: #a0a0a0;
  }

  .new-card-toggle {
    position: relative;
    flex-shrink: 0;
    width: 3rem;
    height: 1.75rem;
    border-radius: 999px;
    border: 0;
    background: #3a3a3a;
    cursor: pointer;
    transition: background 0.2s ease;
  }

  .new-card-toggle--on {
    background: #ff8c42;
  }

  .new-card-toggle__thumb {
    position: absolute;
    top: 0.2rem;
    left: 0.2rem;
    width: 1.35rem;
    height: 1.35rem;
    border-radius: 999px;
    background: #fff;
    transition: transform 0.2s ease;
  }

  .new-card-toggle--on .new-card-toggle__thumb {
    transform: translateX(1.2rem);
  }

  .new-card-sheet__pay-wrap {
    margin-top: 1rem;
  }

  .new-card-sheet__cancel {
    width: 100%;
    margin-top: 0.5rem;
    border: 0;
    background: transparent;
    color: #a0a0a0;
    font-size: 0.875rem;
    padding: 0.5rem;
    cursor: pointer;
  }

  .new-card-sheet__banner {
    margin: 0.75rem 0 0;
    font-size: 0.875rem;
  }

  .new-card-sheet__banner--error {
    color: #f87171;
  }

  .new-card-sheet__badges {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 0.75rem;
    margin-top: 1rem;
    font-size: 0.6875rem;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: #757575;
  }

  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }
</style>
