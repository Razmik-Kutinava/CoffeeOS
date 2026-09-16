<script>
  /**
   * Экран 2: Callcheck (poll) → SMS fallback (PIN).
   * #90: visibility/pageshow → resume poll существующего Callcheck (без повторного init).
   */
  import { onDestroy, onMount } from "svelte"
  import { api } from "../lib/api.js"
  import { buildVerifySmsBody, buildSendSmsBody } from "../lib/phoneAuthWizard.js"
  import {
    SMS_BTN_LABEL,
    CALLCHECK_POLL_MS,
    CALLCHECK_CHECKING_TITLE,
    CALLCHECK_CHECKING_BODY,
    initialCallcheckState,
    tickCallcheck,
    afterSmsSend,
    showSmsPin,
    cascadeHint,
    cascadeTimerLabel,
    telHrefFromCallPhone,
    callPhoneButtonLabel,
    interpretCallcheckPoll,
    callcheckForegroundAction,
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
  let completing = $state(false)
  let resending = $state(false)
  let localError = $state("")
  let pinNonce = $state(0)
  let state = $state(initialCallcheckState(callcheck || {}))
  let returnedChecking = $state(false)
  let wasBackgrounded = false
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
  const dialLabel = $derived(callPhoneButtonLabel(state.callPhonePretty, state.callPhone))
  const busy = $derived(resending || verifying || completing)
  const showChecking = $derived(
    returnedChecking && state.phase === AUTH_PHASE.CALLCHECK && !completing
  )

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

  /** #90: return from phone app — poll only, never re-init Callcheck. */
  function resumeAfterForeground() {
    if (callcheckForegroundAction(state.phase) !== "poll") return
    returnedChecking = true
    if (!pollId) startPoll()
    else pollStatus()
  }

  function onVisibilityChange() {
    if (typeof document !== "undefined" && document.visibilityState === "hidden") {
      wasBackgrounded = true
      return
    }
    if (!wasBackgrounded) return
    resumeAfterForeground()
  }

  function onPageShow(event) {
    if (!wasBackgrounded && !event?.persisted) return
    wasBackgrounded = true
    resumeAfterForeground()
  }

  async function pollStatus() {
    if (state.phase !== AUTH_PHASE.CALLCHECK || verifying || completing) return
    try {
      const res = await api("/phone_otp/check_status", { method: "GET" })
      localError = ""
      onError?.("")
      const outcome = interpretCallcheckPoll(res)
      if (outcome.action === "complete") {
        completing = true
        returnedChecking = false
        stopTimers()
        onVerified?.({
          phone: outcome.phone || phoneE164,
          refreshToken: outcome.refreshToken
        })
        return
      }
      if (outcome.action === "sms_fallback") {
        stopPoll()
        returnedChecking = false
        state = { ...state, phase: AUTH_PHASE.SMS, secondsLeft: 0 }
        await sendSms()
      }
    } catch (e) {
      localError = e?.message || "Не удалось проверить звонок. Попробуйте SMS."
      onError?.(localError)
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
  onMount(() => {
    document.addEventListener("visibilitychange", onVisibilityChange)
    window.addEventListener("pageshow", onPageShow)
    return () => {
      document.removeEventListener("visibilitychange", onVisibilityChange)
      window.removeEventListener("pageshow", onPageShow)
    }
  })
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
  {#if showChecking}
    <div class="mb-3 text-center" role="status" data-testid="phone-auth-callcheck-checking">
      <p class="text-sm font-medium text-white">{CALLCHECK_CHECKING_TITLE}</p>
      <p class="mt-1 text-sm text-[#a0a0a0]">{CALLCHECK_CHECKING_BODY}</p>
    </div>
  {:else if waitLabel}
    <p class="mb-3 text-center text-sm text-white" role="status" data-testid="phone-auth-callcheck-timer">
      {waitLabel}
    </p>
  {/if}

  {#if state.phase === AUTH_PHASE.CALLCHECK}
    <div class="mb-3 text-center" data-testid="phone-auth-callcheck-number">
      {#if telHref}
        <a
          href={telHref}
          class="inline-flex w-full items-center justify-center rounded-lg bg-[#ff8c42] px-4 py-3 text-base font-semibold text-black no-underline"
          data-testid="phone-auth-tel-btn"
        >
          {dialLabel}
        </a>
      {:else if state.callPhoneHtml}
        <!-- SMS.ru html already escaped server-side; tel link preferred -->
        <p class="text-lg text-white">{dialLabel}</p>
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
