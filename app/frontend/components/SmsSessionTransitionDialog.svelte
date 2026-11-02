<script>
  import {
    SMS_TRANSITION_TITLE,
    SMS_TRANSITION_CART_WARNING,
    SMS_TRANSITION_CONFIRM_LABEL,
    SMS_TRANSITION_DECLINE_LABEL
  } from "../lib/smsSessionTransition.js"

  /** @type {boolean} */
  export let open = false
  /** @type {boolean} */
  export let busy = false
  /** @type {() => void} */
  export let onConfirm = () => {}
  /** @type {() => void} */
  export let onDecline = () => {}
</script>

{#if open}
  <div class="sms-tr" role="alertdialog" aria-labelledby="sms-tr-title" aria-describedby="sms-tr-warn">
    <div class="sms-tr__panel">
      <h2 id="sms-tr-title" class="sms-tr__title">{SMS_TRANSITION_TITLE}</h2>
      <p id="sms-tr-warn" class="sms-tr__warn">{SMS_TRANSITION_CART_WARNING}</p>
      <div class="sms-tr__actions">
        <button
          type="button"
          class="sms-tr__btn sms-tr__btn--ghost"
          disabled={busy}
          on:click={onDecline}
        >
          {SMS_TRANSITION_DECLINE_LABEL}
        </button>
        <button
          type="button"
          class="sms-tr__btn sms-tr__btn--primary"
          disabled={busy}
          on:click={onConfirm}
        >
          {SMS_TRANSITION_CONFIRM_LABEL}
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .sms-tr {
    position: fixed;
    inset: 0;
    z-index: 60;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    background: rgba(0, 0, 0, 0.55);
    padding: 1rem;
    padding-bottom: calc(1rem + var(--shop-safe-bottom, 0px));
  }
  .sms-tr__panel {
    width: 100%;
    max-width: 28rem;
    background: #242424;
    border-radius: 1rem;
    padding: 1.25rem 1rem;
    color: #fff;
  }
  .sms-tr__title {
    margin: 0 0 0.5rem;
    font-size: 1.125rem;
    font-weight: 600;
  }
  .sms-tr__warn {
    margin: 0 0 1rem;
    font-size: 0.9375rem;
    color: #d4d4d4;
  }
  .sms-tr__actions {
    display: flex;
    gap: 0.75rem;
  }
  .sms-tr__btn {
    flex: 1;
    border-radius: 0.75rem;
    padding: 0.75rem 1rem;
    font-size: 1rem;
    font-weight: 600;
    border: none;
  }
  .sms-tr__btn:disabled {
    opacity: 0.6;
  }
  .sms-tr__btn--ghost {
    background: #3a3a3a;
    color: #fff;
  }
  .sms-tr__btn--primary {
    background: #c4a574;
    color: #1a1a1a;
  }
</style>
