<script>
  /**
   * 2-экранный phone auth wizard (каскад OTP).
   * Шаг 1: телефон → flash_call. Шаг 2: 4 PIN-ячейки + авто-verify.
   */
  import { tick } from "svelte"
  import { api } from "../lib/api.js"
  import { formatPhoneMask, normalizePhoneToE164Ru } from "../lib/phoneOtp.js"
  import {
    WIZARD_SCREEN,
    PIN_LENGTH,
    canContinuePhone,
    buildFlashCallSendBody,
    nextScreenAfterSend,
    emptyPinCells,
    applyPinDigit,
    pinBackspaceFocus,
    shouldAutoSubmitPin,
    buildVerifyBody
  } from "../lib/phoneAuthWizard.js"

  let {
    onVerified = undefined,
    onError = undefined,
    onPhoneChange = undefined
  } = $props()

  let screen = $state(WIZARD_SCREEN.PHONE)
  let phoneDisplay = $state("+7")
  let sending = $state(false)
  let verifying = $state(false)
  let localError = $state("")
  let pinCells = $state(emptyPinCells())
  /** DOM-refs ячеек PIN (не $state — иначе bind:this по индексу глючит). */
  let pinEls = []

  const phoneE164 = $derived(normalizePhoneToE164Ru(phoneDisplay))
  const canContinue = $derived(canContinuePhone(phoneDisplay) && !sending)
  const pinIndexes = Array.from({ length: PIN_LENGTH }, (_, i) => i)

  function onPhoneInput(e) {
    phoneDisplay = formatPhoneMask(e.target.value)
    localError = ""
    onPhoneChange?.(phoneDisplay)
  }

  async function onContinue() {
    if (!canContinue || !phoneE164) return
    localError = ""
    sending = true
    try {
      await api("/phone_otp/send", {
        method: "POST",
        body: JSON.stringify(buildFlashCallSendBody(phoneE164))
      })
      pinCells = emptyPinCells()
      screen = nextScreenAfterSend(screen)
      await tick()
      pinEls[0]?.focus()
    } catch (e) {
      localError = e.message || "Не удалось отправить код"
      onError?.(localError)
    } finally {
      sending = false
    }
  }

  function onChangeNumber() {
    screen = WIZARD_SCREEN.PHONE
    pinCells = emptyPinCells()
    verifying = false
    localError = ""
  }

  async function focusPin(index) {
    await tick()
    pinEls[index]?.focus()
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
</script>

<div class="mb-4 border-t border-[#3a3a3a] pt-4" data-testid="phone-auth-wizard">
  {#if screen === WIZARD_SCREEN.PHONE}
    <div data-testid="phone-auth-screen-1">
      <p class="mb-2 text-sm font-medium text-white">Вход по телефону</p>
      <label class="mb-3 block">
        <span class="mb-1 block text-sm text-[#a0a0a0]">Телефон</span>
        <input
          value={phoneDisplay}
          oninput={onPhoneInput}
          type="tel"
          inputmode="tel"
          autocomplete="tel"
          autofocus
          class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2"
          placeholder="+7 (900) 123-45-67"
          data-testid="phone-auth-input"
        />
      </label>
      <button
        type="button"
        class="w-full rounded-lg bg-[#ff8c42] py-2.5 text-sm font-medium text-white disabled:opacity-50"
        disabled={!canContinue}
        onclick={onContinue}
        data-testid="phone-auth-continue"
      >
        {sending ? "Отправляем…" : "Продолжить"}
      </button>
    </div>
  {:else}
    <div data-testid="phone-auth-screen-2">
      <p class="mb-2 text-sm text-[#a0a0a0]">{phoneDisplay}</p>
      <button
        type="button"
        class="mb-3 text-sm text-[#ff8c42]"
        onclick={onChangeNumber}
        data-testid="phone-auth-change-number"
      >
        Изменить номер
      </button>
      <p class="mb-3 text-sm text-[#a0a0a0]" role="status">
        Введите последние 4 цифры номера, с которого вам звонят. На звонок отвечать не нужно.
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
    </div>
  {/if}

  {#if localError}
    <p class="mt-2 text-sm text-red-400" role="alert">{localError}</p>
  {/if}
</div>
