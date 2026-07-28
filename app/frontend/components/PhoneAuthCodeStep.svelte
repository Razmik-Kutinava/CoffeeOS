<script>
  /**
   * Экран 2 auth wizard: PIN + каскад Flash Call #1/#2.
   */
  import { onDestroy, onMount, tick } from "svelte"
  import { api } from "../lib/api.js"
  import {
    PIN_LENGTH,
    emptyPinCells,
    applyPinDigit,
    pinBackspaceFocus,
    shouldAutoSubmitPin,
    buildVerifyBody,
    buildFlashCallSendBody
  } from "../lib/phoneAuthWizard.js"
  import {
    FLASH_HINT,
    RETRY_FLASH_LABEL,
    initialFlashCascade,
    tickFlashCascade,
    waitingCallLabel,
    showRetryFlashButton,
    afterManualFlashResend
  } from "../lib/phoneAuthCascade.js"

  let {
    phoneDisplay = "+7",
    phoneE164 = null,
    onChangeNumber = undefined,
    onVerified = undefined,
    onError = undefined
  } = $props()

  let verifying = $state(false)
  let resending = $state(false)
  let localError = $state("")
  let pinCells = $state(emptyPinCells())
  let pinEls = []
  let cascade = $state(initialFlashCascade())
  let timerId = null

  const pinIndexes = Array.from({ length: PIN_LENGTH }, (_, i) => i)
  const waitLabel = $derived(waitingCallLabel(cascade.secondsLeft))
  const showRetry = $derived(showRetryFlashButton(cascade.flashRound))

  function stopTimer() {
    if (timerId) {
      clearInterval(timerId)
      timerId = null
    }
  }

  function startTimer() {
    stopTimer()
    timerId = setInterval(() => {
      const next = tickFlashCascade(cascade)
      cascade = { flashRound: next.flashRound, secondsLeft: next.secondsLeft }
      if (next.autoResend) requestFlashResend({ auto: true })
    }, 1000)
  }

  startTimer()
  onDestroy(stopTimer)

  onMount(() => {
    focusPin(0)
  })

  async function focusPin(index) {
    await tick()
    pinEls[index]?.focus()
  }

  async function requestFlashResend({ auto = false } = {}) {
    if (!phoneE164 || resending || verifying) return
    resending = true
    localError = ""
    try {
      await api("/phone_otp/send", {
        method: "POST",
        body: JSON.stringify(buildFlashCallSendBody(phoneE164))
      })
      cascade = afterManualFlashResend(auto ? 2 : cascade.flashRound)
      if (!timerId) startTimer()
    } catch (e) {
      localError = e.message || "Не удалось запросить звонок"
      onError?.(localError)
    } finally {
      resending = false
    }
  }

  async function submitPin(code) {
    if (!phoneE164 || verifying || !shouldAutoSubmitPin(code)) return
    verifying = true
    localError = ""
    try {
      const res = await api("/phone_otp/verify", {
        method: "POST",
        body: JSON.stringify(buildVerifyBody(phoneE164, code))
      })
      stopTimer()
      onVerified?.({
        phone: res?.phone || phoneE164,
        refreshToken: res?.refresh_token
      })
    } catch (e) {
      localError = e.message || "Неверный код"
      onError?.(localError)
      pinCells = emptyPinCells()
      await focusPin(0)
    } finally {
      verifying = false
    }
  }

  function onPinInput(index, e) {
    if (verifying) return
    const r = applyPinDigit(pinCells, index, e.target.value)
    pinCells = r.cells
    localError = ""
    focusPin(r.focusIndex)
    if (shouldAutoSubmitPin(r.code)) submitPin(r.code)
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

  function handleChangeNumber() {
    stopTimer()
    onChangeNumber?.()
  }
</script>

<div data-testid="phone-auth-screen-2">
  <p class="mb-2 text-sm text-[#a0a0a0]">{phoneDisplay}</p>
  <button
    type="button"
    class="mb-3 text-sm text-[#ff8c42]"
    onclick={handleChangeNumber}
    data-testid="phone-auth-change-number"
  >
    Изменить номер
  </button>
  <p class="mb-2 text-sm text-[#a0a0a0]" role="status" data-testid="phone-auth-flash-hint">
    {FLASH_HINT}
  </p>
  <p class="mb-3 text-center text-sm text-white" role="status" data-testid="phone-auth-flash-timer">
    {waitLabel}
  </p>
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
        disabled={verifying}
        class="h-12 w-11 rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] text-center text-xl text-white tracking-widest disabled:opacity-50"
        data-testid={"phone-auth-pin-" + i}
        aria-label={"Цифра " + (i + 1)}
      />
    {/each}
  </div>
  {#if verifying}
    <p class="text-center text-sm text-[#a0a0a0]" role="status">Проверяем…</p>
  {/if}
  {#if showRetry}
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-[#ff8c42] py-2 text-sm text-[#ff8c42] disabled:opacity-50"
      disabled={resending || verifying}
      onclick={() => requestFlashResend({ auto: false })}
      data-testid="phone-auth-retry-flash"
    >
      {resending ? "Отправляем…" : RETRY_FLASH_LABEL}
    </button>
  {/if}
  {#if localError}
    <p class="mt-2 text-sm text-red-400" role="alert">{localError}</p>
  {/if}
</div>
