<script>
  import { getEmailValidationError } from "../lib/emailCollection.js"

  let {
    orderId = "",
    email = "",
    marketingConsent = false,
    onSubmit = undefined,
    onSkip = undefined,
    loading = false
  } = $props()

  let emailError = $state("")
  let submitting = $state(false)

  function validateEmail(value) {
    return getEmailValidationError(value)
  }

  function onEmailChange(e) {
    email = e.currentTarget.value
    if (email) {
      emailError = validateEmail(email)
    } else {
      emailError = ""
    }
  }

  function onEmailBlur() {
    if (email) {
      emailError = validateEmail(email)
    }
  }

  async function handleSubmit() {
    if (!email.trim()) {
      return onSkip?.()
    }
    emailError = validateEmail(email)
    if (emailError) {
      return
    }
    submitting = true
    try {
      await onSubmit?.({
        email: email.trim().toLowerCase(),
        marketing_consent: !!marketingConsent
      })
    } finally {
      submitting = false
    }
  }

  const canSubmit = !submitting && (!email || !emailError)
</script>

<div class="email-success-block" data-testid="order-success-email-block">
  <div class="block-content">
    <h3 class="block-title">Куда прислать чек и предложения</h3>

    <label class="email-field">
      <span class="label">Email</span>
      <input
        type="email"
        placeholder="example@mail.com"
        value={email}
        oninput={onEmailChange}
        onblur={onEmailBlur}
        disabled={submitting}
        data-testid="order-email-input"
      />
      {#if emailError}
        <p class="error-text" role="alert" data-testid="order-email-error">
          {emailError}
        </p>
      {/if}
    </label>

    <label class="consent-checkbox">
      <input
        type="checkbox"
        bind:checked={marketingConsent}
        disabled={submitting}
        data-testid="order-marketing-consent"
      />
      <span>Отправляйте мне предложения</span>
    </label>

    <div class="button-group">
      <button
        type="button"
        class="btn btn-primary"
        disabled={!canSubmit}
        onclick={handleSubmit}
        data-testid="order-email-submit"
      >
        {submitting ? "Отправляем…" : "Отправить"}
      </button>
      <button
        type="button"
        class="btn btn-secondary"
        disabled={submitting}
        onclick={() => onSkip?.()}
        data-testid="order-email-skip"
      >
        Пропустить
      </button>
    </div>
  </div>
</div>

<style>
  .email-success-block {
    margin: 2rem 0;
    padding: 1.5rem;
    background: #2a2a2a;
    border: 1px solid #3a3a3a;
    border-radius: 12px;
  }

  .block-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .block-title {
    margin: 0;
    font-size: 1rem;
    font-weight: 600;
    color: #fff;
  }

  .email-field {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .label {
    font-size: 0.75rem;
    color: #a0a0a0;
    text-transform: uppercase;
  }

  input[type="email"] {
    padding: 0.75rem;
    border: 1px solid #3a3a3a;
    border-radius: 8px;
    background: #1a1a1a;
    color: #fff;
    font-size: 0.95rem;
  }

  input[type="email"]:focus {
    outline: none;
    border-color: #ff8c42;
    background: #1a1a1a;
  }

  input[type="email"]:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .error-text {
    margin: 0.25rem 0 0 0;
    font-size: 0.75rem;
    color: #ef4444;
  }

  .consent-checkbox {
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
    font-size: 0.875rem;
    color: #a0a0a0;
    cursor: pointer;
  }

  input[type="checkbox"] {
    margin-top: 0.125rem;
    cursor: pointer;
  }

  input[type="checkbox"]:disabled {
    cursor: not-allowed;
    opacity: 0.6;
  }

  .button-group {
    display: flex;
    gap: 0.75rem;
    margin-top: 0.5rem;
  }

  .btn {
    flex: 1;
    padding: 0.75rem 1rem;
    border: none;
    border-radius: 8px;
    font-size: 0.9rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-primary {
    background: #ff8c42;
    color: #000;
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-primary:not(:disabled):hover {
    background: #ffaa5e;
  }

  .btn-secondary {
    background: #3a3a3a;
    color: #fff;
  }

  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary:not(:disabled):hover {
    background: #4a4a4a;
  }
</style>
