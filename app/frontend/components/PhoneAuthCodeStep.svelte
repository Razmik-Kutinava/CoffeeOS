<script>
  /**
   * Экран 2: Callcheck (poll) → SMS fallback (PIN).
   */
  import { onDestroy } from "svelte"
  import { api } from "../lib/api.js"
  import { buildVerifySmsBody, buildSendSmsBody } from "../lib/phoneAuthWizard.js"
  import {
    SMS_BTN_LABEL,
    CALLCHECK_POLL_MS,
    initialCallcheckState,
    tickCallcheck,
    afterSmsSend,
    showSmsPin,
    cascadeHint,
    cascadeTimerLabel,
    telHrefFromCallPhone,
    AUTH_PHASE
  } from "../lib/phoneAuthCascade.js"
  import PhoneAuthPinInputs from "./PhoneAuthPinInputs.svelte"

  let {
    phoneDisplay = "+7",
    phoneE164 = null,
    callcheck = null,
    onChangeNumber = undefined,
    onVerified = undefined,
    onError = undefined
  } = $props()

  let verifying = $state(false)
  let resending = $state(false)
  let localError = $state("")
  let pinNonce = $state(0)
  let state = $state(initialCallcheckState(callcheck || {}))
  let tickId = null
  let pollId = null

  const hintText = $derived(
    cascadeHint({
      phase: state.phase,
      lastChannel: state.lastChannel,
      phoneDisplay,
      smsSent: state.smsSent
    })
  )
  const waitLabel = $derived(
    cascadeTimerLabel({ phase: state.phase, secondsLeft: state.secondsLeft })
  )
  const showPin = $derived(showSmsPin(state.phase, state.smsSent))
  const telHref = $derived(telHrefFromCallPhone(state.callPhone))
  const busy = $derived(resending || verifying)

  function stopTimers() {
    if (tickId) {
      clearInterval(tickId)
      tickId = null
    }
    if (pollId) {
      clearInterval(pollId)
      pollId = null
    }
  }

  function startTick() {
    stopTimers()
    tickId = setInterval(() => {
      const next = tickCallcheck(state)
      state = {
        ...state,
        phase: next.phase,
        secondsLeft: next.secondsLeft,
        lastChannel: next.lastChannel,
        smsSent: next.smsSent,
        autoSend: null
      }
      if (next.autoSend === "sms") {
        stopPoll()
        sendSms()
      }
    }, 1000)
    if (state.phase === AUTH_PHASE.CALLCHECK) startPoll()
  }

  function stopPoll() {
    if (pollId) {
      clearInterval(pollId)
      pollId = null
    }
  }

  function startPoll() {
    stopPoll()
    pollId = setInterval(() => {
      pollStatus()
    }, CALLCHECK_POLL_MS)
    pollStatus()
  }

  async function pollStatus() {
    if (state.phase !== AUTH_PHASE.CALLCHECK || verifying) return
    try {
      const res = await api("/phone_otp/check_status", { method: "GET" })
      if (res?.confirmed || res?.verified) {
        stopTimers()
        onVerified?.({ phone: res?.phone || phoneE164, refreshToken: res?.refresh_token })
      } else if (res?.expired) {
        stopPoll()
        state = { ...state, phase: AUTH_PHASE.SMS, secondsLeft: 0 }
        await sendSms()
      }
    } catch (_) {
      /* poll soft-fail; timeout/SMS fallback handles UX */
    }
  }

  async function sendSms() {
    if (!phoneE164 || resending || verifying) return
    resending = true
    localError = ""
    try {
      await api("/phone_otp/send_sms", {
        method: "POST",
        body: JSON.stringify(buildSendSmsBody(phoneE164))
      })
      state = afterSmsSend(state)
      if (!tickId) startTick()
    } catch (e) {
      localError = e.message || "Не удалось отправить SMS"
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
      const res = await api("/phone_otp/verify_sms", {
        method: "POST",
        body: JSON.stringify(buildVerifySmsBody(phoneE164, code))
      })
      stopTimers()
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
    stopTimers()
    onChangeNumber?.()
  }

  function onManualSms() {
    stopPoll()
    sendSms()
  }

  startTick()
  onDestroy(stopTimers)
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
  <p class="mb-2 text-sm text-[#a0a0a0]" role="status" data-testid="phone-auth-callcheck-hint">{hintText}</p>
  {#if waitLabel}
    <p class="mb-3 text-center text-sm text-white" role="status" data-testid="phone-auth-callcheck-timer">
      {waitLabel}
    </p>
  {/if}

  {#if state.phase === AUTH_PHASE.CALLCHECK}
    <div class="mb-3 text-center" data-testid="phone-auth-callcheck-number">
      {#if telHref}
        <a
          href={telHref}
          class="text-lg font-medium text-[#ff8c42] underline"
          data-testid="phone-auth-tel-link"
        >
          {state.callPhonePretty || state.callPhone}
        </a>
      {:else if state.callPhoneHtml}
        <!-- SMS.ru html already escaped server-side; tel link preferred -->
        <p class="text-lg text-white">{state.callPhonePretty}</p>
      {/if}
    </div>
  {/if}

  {#if showPin}
    {#key pinNonce}
      <PhoneAuthPinInputs disabled={verifying} onComplete={submitPin} />
    {/key}
    {#if verifying}
      <p class="text-center text-sm text-[#a0a0a0]" role="status">Проверяем…</p>
    {/if}
  {/if}

  {#if state.phase === AUTH_PHASE.CALLCHECK || (state.phase === AUTH_PHASE.SMS && !state.smsSent)}
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-[#ff8c42] py-2 text-sm text-[#ff8c42] disabled:opacity-50"
      disabled={busy}
      onclick={onManualSms}
      data-testid="phone-auth-sms"
    >
      {resending ? "Отправляем…" : SMS_BTN_LABEL}
    </button>
  {:else if state.phase === AUTH_PHASE.SMS && state.smsSent}
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-[#ff8c42] py-2 text-sm text-[#ff8c42] disabled:opacity-50"
      disabled={busy || state.secondsLeft > 0}
      onclick={onManualSms}
      data-testid="phone-auth-sms"
    >
      {resending ? "Отправляем…" : SMS_BTN_LABEL}
    </button>
  {/if}

  {#if localError}
    <p class="mt-2 text-sm text-red-400" role="alert">{localError}</p>
  {/if}
</div>
