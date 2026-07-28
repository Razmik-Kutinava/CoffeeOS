<script>
  /** 4 ячейки PIN для phone auth. */
  import { onMount, tick } from "svelte"
  import {
    PIN_LENGTH,
    emptyPinCells,
    applyPinDigit,
    pinBackspaceFocus,
    shouldAutoSubmitPin
  } from "../lib/phoneAuthWizard.js"

  let { disabled = false, onComplete = undefined } = $props()

  let pinCells = $state(emptyPinCells())
  let pinEls = []
  const pinIndexes = Array.from({ length: PIN_LENGTH }, (_, i) => i)

  onMount(() => focusPin(0))

  async function focusPin(index) {
    await tick()
    pinEls[index]?.focus()
  }

  function onPinInput(index, e) {
    if (disabled) return
    const r = applyPinDigit(pinCells, index, e.target.value)
    pinCells = r.cells
    focusPin(r.focusIndex)
    if (shouldAutoSubmitPin(r.code)) onComplete?.(r.code)
  }

  function onPinKeydown(index, e) {
    if (e.key !== "Backspace") return
    if ((pinCells[index] || "").length > 0) return
    e.preventDefault()
    const prev = pinBackspaceFocus(pinCells, index)
    if (prev !== index) {
      const next = [...pinCells]
      next[prev] = ""
      pinCells = next
      focusPin(prev)
    }
  }
</script>

<div class="mb-2 flex justify-center gap-2" data-testid="phone-auth-pin" role="group" aria-label="Код из 4 цифр">
  {#each pinIndexes as i (i)}
    <input
      bind:this={pinEls[i]}
      value={pinCells[i]}
      oninput={(e) => onPinInput(i, e)}
      onkeydown={(e) => onPinKeydown(i, e)}
      type="text"
      inputmode="numeric"
      autocomplete={i === 0 ? "one-time-code" : "off"}
      maxlength="1"
      {disabled}
      class="h-12 w-11 rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] text-center text-xl text-white tracking-widest disabled:opacity-50"
      data-testid={"phone-auth-pin-" + i}
      aria-label={"Цифра " + (i + 1)}
    />
  {/each}
</div>
