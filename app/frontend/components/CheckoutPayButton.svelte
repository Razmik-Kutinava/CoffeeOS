<script>
  import {
    PAY_FSM,
    payFsmLabel,
    isPayFsmBusy
  } from "../lib/shopPayFsm.js"

  let {
    fsmState = PAY_FSM.DEFAULT,
    disabled = false,
    idleLabel = null,
    loadingLabel = null,
    onPay = () => {},
    onRetry = () => {}
  } = $props()

  let shake = $state(false)
  let prevFsm = PAY_FSM.DEFAULT

  $effect(() => {
    if (fsmState === PAY_FSM.CLIENT_ERROR && prevFsm !== PAY_FSM.CLIENT_ERROR) {
      shake = true
      const t = setTimeout(() => {
        shake = false
      }, 520)
      return () => clearTimeout(t)
    }
    prevFsm = fsmState
  })

  const busy = $derived(isPayFsmBusy(fsmState))
  const showLoader = $derived(
    fsmState === PAY_FSM.CONNECTING || fsmState === PAY_FSM.PROCESSING
  )
  const label = $derived(
    showLoader && loadingLabel
      ? loadingLabel
      : fsmState === PAY_FSM.DEFAULT && idleLabel
        ? idleLabel
        : payFsmLabel(fsmState)
  )

  function handleClick() {
    if (disabled) return
    if (fsmState === PAY_FSM.BANK_ERROR || fsmState === PAY_FSM.NET_ERROR) {
      onRetry()
      return
    }
    if (fsmState === PAY_FSM.CLIENT_ERROR) {
      onPay()
      return
    }
    if (fsmState === PAY_FSM.DEFAULT) {
      onPay()
    }
  }
</script>

<button
  type="button"
  class="pay-fsm-btn pay-fsm-btn--{fsmState}"
  class:pay-fsm-btn--shake={shake}
  disabled={disabled || (busy && fsmState !== PAY_FSM.CLIENT_ERROR)}
  onclick={handleClick}
  aria-live="polite"
  aria-busy={busy}
  data-fsm-state={fsmState}
  data-testid="checkout-pay-fsm"
>
  {#if showLoader}
    <span class="pay-fsm-btn__loader" aria-hidden="true"></span>
  {/if}
  <span class="pay-fsm-btn__label">{label}</span>
</button>

<style>
  .pay-fsm-btn {
    width: 100%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    border: 0;
    border-radius: 999px;
    padding: 1rem 1.25rem;
    font-size: 1.0625rem;
    font-weight: 600;
    line-height: 1.2;
    cursor: pointer;
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .pay-fsm-btn:disabled {
    cursor: not-allowed;
  }

  .pay-fsm-btn--0 {
    background: #3b82f6;
    color: #fff;
  }

  .pay-fsm-btn--1,
  .pay-fsm-btn--2 {
    background: #2563eb;
    color: #fff;
    opacity: 0.92;
  }

  .pay-fsm-btn--3 {
    background: #1d4ed8;
    color: #fff;
    opacity: 0.88;
  }

  .pay-fsm-btn--4 {
    background: #22c55e;
    color: #0f172a;
  }

  .pay-fsm-btn--5 {
    background: #ef4444;
    color: #fff;
  }

  .pay-fsm-btn--6,
  .pay-fsm-btn--7 {
    background: #6b7280;
    color: #fff;
  }

  .pay-fsm-btn--shake {
    animation: pay-shake 0.45s ease;
  }

  @keyframes pay-shake {
    0%,
    100% {
      transform: translateX(0);
    }
    20%,
    60% {
      transform: translateX(-6px);
    }
    40%,
    80% {
      transform: translateX(6px);
    }
  }

  .pay-fsm-btn__loader {
    width: 1rem;
    height: 1rem;
    border: 2px solid rgb(255 255 255 / 0.35);
    border-top-color: #fff;
    border-radius: 999px;
    animation: pay-spin 0.7s linear infinite;
    flex-shrink: 0;
  }

  @keyframes pay-spin {
    to {
      transform: rotate(360deg);
    }
  }
</style>
