<script>
  /**
   * Экран 2: PIN + каскад Flash×2 → SMS.
   */
  import { onDestroy } from "svelte"
  import { api } from "../lib/api.js"
  import { buildVerifyBody, buildOtpSendBody } from "../lib/phoneAuthWizard.js"
  import {
    RETRY_FLASH_LABEL,
    SMS_BTN_LABEL,
    initialFlashCascade,
    tickFlashCascade,
    showRetryFlashButton,
    showSmsButton,
    afterManualFlashResend,
    afterSmsSend,
    cascadeHint,
    cascadeTimerLabel
  } from "../lib/phoneAuthCascade.js"
  import PhoneAuthPinInputs from "./PhoneAuthPinInputs.svelte"

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
  let pinNonce = $state(0)
  let cascade = $state(initialFlashCascade())
  let timerId = null

  const hintText = $derived(cascadeHint({ lastChannel: cascade.lastChannel, phoneDisplay }))
  const waitLabel = $derived(
    cascadeTimerLabel({
      phase: cascade.phase,
      secondsLeft: cascade.secondsLeft,
      lastChannel: cascade.lastChannel
    })
  )
  const showRetry = $derived(showRetryFlashButton(cascade.phase))
  const showSms = $derived(showSmsButton(cascade.phase))
  const busy = $derived(resending || verifying)

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
      cascade = {
        phase: next.phase,
        secondsLeft: next.secondsLeft,
        lastChannel: next.lastChannel
      }
      if (next.autoSend) sendChannel(next.autoSend)
    }, 1000)
  }

  startTimer()
  onDestroy(stopTimer)

  async function sendChannel(channel) {
    if (!phoneE164 || resending || verifying) return
    resending = true
    localError = ""
    try {
      await api("/phone_otp/send", {
        method: "POST",
        body: JSON.stringify(buildOtpSendBody(phoneE164, channel))
      })
      if (channel === "flash_call") cascade = afterManualFlashResend()
      else if (channel === "sms") cascade = afterSmsSend()
      if (!timerId) startTimer()
    } catch (e) {
      localError = e.message || "Не удалось отправить код"
      onError?.(localError)
    } finally {
      resending = false
    }
  }

  async function submitPin(code) {
    if (!phoneE164 || verifying) return
    verifying = true
    localError = ""
    try {
      const res = await api("/phone_otp/verify", {
        method: "POST",
        body: JSON.stringify(buildVerifyBody(phoneE164, code))
      })
      stopTimer()
      onVerified?.({ phone: res?.phone || phoneE164, refreshToken: res?.refresh_token })
    } catch (e) {
      localError = e.message || "Неверный код"
      onError?.(localError)
      pinNonce += 1
    } finally {
      verifying = false
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
  <p class="mb-2 text-sm text-[#a0a0a0]" role="status" data-testid="phone-auth-flash-hint">{hintText}</p>
  {#if waitLabel}
    <p class="mb-3 text-center text-sm text-white" role="status" data-testid="phone-auth-flash-timer">
      {waitLabel}
    </p>
  {/if}
  {#key pinNonce}
    <PhoneAuthPinInputs disabled={verifying} onComplete={submitPin} />
  {/key}
  {#if verifying}
    <p class="text-center text-sm text-[#a0a0a0]" role="status">Проверяем…</p>
  {/if}
  {#if showRetry}
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-[#ff8c42] py-2 text-sm text-[#ff8c42] disabled:opacity-50"
      disabled={busy}
      onclick={() => sendChannel("flash_call")}
      data-testid="phone-auth-retry-flash"
    >
      {resending ? "Отправляем…" : RETRY_FLASH_LABEL}
    </button>
  {/if}
  {#if showSms}
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-[#ff8c42] py-2 text-sm text-[#ff8c42] disabled:opacity-50"
      disabled={busy || cascade.secondsLeft > 0}
      onclick={() => sendChannel("sms")}
      data-testid="phone-auth-sms"
    >
      {resending ? "Отправляем…" : SMS_BTN_LABEL}
    </button>
  {/if}
  {#if localError}
    <p class="mt-2 text-sm text-red-400" role="alert">{localError}</p>
  {/if}
</div>
