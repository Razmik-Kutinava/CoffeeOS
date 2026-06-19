<script>
  import { PAY_BTN } from "../lib/shopOneClickPay.js"

  let {
    state = PAY_BTN.idle,
    disabled = false,
    errorInfo = null,
    onPay = () => {},
    onRetry = () => {},
    onBindOther = () => {}
  } = $props()

  const labels = {
    [PAY_BTN.idle]: "Оплатить →",
    [PAY_BTN.loading]: "Идёт оплата…",
    [PAY_BTN.success]: "Оплачено ✓",
    [PAY_BTN.error]: "Оплатить →"
  }
</script>

<button
  type="button"
  class="w-full rounded-xl py-4 text-lg font-semibold transition-colors
    {state === PAY_BTN.success
    ? 'bg-green-500 text-black'
    : 'bg-[#ff8c42] text-black'}
    disabled:opacity-50"
  disabled={disabled || state === PAY_BTN.loading || state === PAY_BTN.success}
  onclick={onPay}
  aria-live="polite"
  aria-busy={state === PAY_BTN.loading}
>
  {labels[state] || labels[PAY_BTN.idle]}
</button>

{#if state === PAY_BTN.error && errorInfo}
  <p class="mt-3 text-sm text-red-400" role="alert">{errorInfo.message}</p>
  <div class="mt-2 flex flex-wrap gap-2">
    {#if errorInfo.showRetry}
      <button type="button" class="text-sm text-[#ff8c42]" onclick={onRetry}>Повторить</button>
    {/if}
    {#if errorInfo.showBindOther}
      <button type="button" class="text-sm text-[#ff8c42]" onclick={onBindOther}>
        Привязать другую карту
      </button>
    {/if}
  </div>
{/if}
