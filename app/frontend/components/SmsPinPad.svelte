<script>
  /**
   * Пинпад «смс код» + таймер 00:59 (скрин inline-оплаты).
   */
  import { onMount } from "svelte"
  import {
    createSmsPinPadState,
    formatSmsTimer,
    appendSmsDigit,
    backspaceSmsDigit,
    tickSmsTimer,
    isSmsCodeComplete,
    SMS_PIN_LENGTH
  } from "../lib/shopSmsPinPad.js"

  let {
    state = $bindable(createSmsPinPadState()),
    onchange = undefined,
    onComplete = undefined
  } = $props()

  const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]
  const timerLabel = $derived(formatSmsTimer(state.secondsLeft))
  const cells = $derived(
    Array.from({ length: SMS_PIN_LENGTH }, (_, i) => state.code[i] || "")
  )

  onMount(() => {
    const id = setInterval(() => {
      const next = tickSmsTimer(state)
      if (next === state) return
      state = next
      onchange?.(next)
    }, 1000)
    return () => clearInterval(id)
  })

  function press(key) {
    if (!key) return
    let next = state
    if (key === "⌫") next = backspaceSmsDigit(state)
    else next = appendSmsDigit(state, key)
    if (next === state) return
    state = next
    onchange?.(next)
    if (isSmsCodeComplete(next)) onComplete?.(next.code)
  }
</script>

<div class="sms-pin" data-testid="shop-sms-pinpad">
  <div class="sms-pin__head">
    <span class="sms-pin__label">смс код</span>
    <span class="sms-pin__timer" data-testid="shop-sms-timer">{timerLabel}</span>
  </div>

  <div class="sms-pin__cells" aria-live="polite">
    {#each cells as ch, i (i)}
      <span class="sms-pin__cell" data-testid="shop-sms-cell">{ch}</span>
    {/each}
  </div>

  <div class="sms-pin__pad" data-testid="shop-sms-keys">
    {#each keys as key (key || "blank")}
      {#if key === ""}
        <span class="sms-pin__blank"></span>
      {:else}
        <button
          type="button"
          class="sms-pin__key"
          data-testid="shop-sms-key"
          data-key={key}
          onclick={() => press(key)}
        >{key}</button>
      {/if}
    {/each}
  </div>
</div>

<style>
  .sms-pin {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  .sms-pin__head {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 0.5rem;
  }
  .sms-pin__label {
    font-size: 0.75rem;
    color: #a3a3a3;
  }
  .sms-pin__timer {
    font-size: 0.75rem;
    font-variant-numeric: tabular-nums;
    color: #ff8c42;
  }
  .sms-pin__cells {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 0.35rem;
  }
  .sms-pin__cell {
    min-height: 2.25rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
    border: 1px solid #3a3a3a;
    background: #111;
    color: #fff;
    font-size: 1rem;
    font-weight: 600;
  }
  .sms-pin__pad {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.35rem;
  }
  .sms-pin__key {
    min-height: 2.5rem;
    border: 0;
    border-radius: 0.5rem;
    background: #fff;
    color: #111;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
  }
  .sms-pin__blank {
    min-height: 2.5rem;
  }
</style>
