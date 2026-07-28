<script>
  /**
   * 2-экранный phone auth wizard (каскад OTP).
   * Шаг 1: Экран 1 — телефон + «Продолжить» → flash_call → Экран 2.
   */
  import { api } from "../lib/api.js"
  import { formatPhoneMask, normalizePhoneToE164Ru } from "../lib/phoneOtp.js"
  import {
    WIZARD_SCREEN,
    canContinuePhone,
    buildFlashCallSendBody,
    nextScreenAfterSend
  } from "../lib/phoneAuthWizard.js"

  let {
    onVerified = undefined,
    onError = undefined,
    onPhoneChange = undefined
  } = $props()

  let screen = $state(WIZARD_SCREEN.PHONE)
  let phoneDisplay = $state("+7")
  let sending = $state(false)
  let localError = $state("")

  const phoneE164 = $derived(normalizePhoneToE164Ru(phoneDisplay))
  const canContinue = $derived(canContinuePhone(phoneDisplay) && !sending)

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
      screen = nextScreenAfterSend(screen)
    } catch (e) {
      localError = e.message || "Не удалось отправить код"
      onError?.(localError)
    } finally {
      sending = false
    }
  }

  function onChangeNumber() {
    screen = WIZARD_SCREEN.PHONE
    localError = ""
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
      <p class="text-sm text-[#a0a0a0]" role="status">
        Введите последние 4 цифры номера, с которого вам звонят. На звонок отвечать не нужно.
      </p>
      <!-- PIN-ячейки — Шаг 2 -->
    </div>
  {/if}

  {#if localError}
    <p class="mt-2 text-sm text-red-400" role="alert">{localError}</p>
  {/if}
</div>
