<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    loadGuestProfile,
    saveGuestProfile,
    clearEmailVerifiedInProfile,
    maskEmail,
    isValidEmail
  } from "../lib/shopGuestProfile.js"
  import {
    lastGuestOrderId,
    reconnectGuestOrder,
    returningFromPaymentPage,
    saveGuestOrderSession,
    clearGuestOrderSession
  } from "../lib/shopGuestSession.js"
  import { savePaymentSession, loadPaymentSession, clearPaymentSession } from "../lib/tbankPayment.js"
  import { clearCartCache } from "../lib/shopCartCache.js"
  import { enqueueOrder } from "../lib/shopOfflineQueue.js"
  import { isOfflineError } from "../lib/shopNetwork.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import {
    PAY_BTN,
    SUCCESS_REDIRECT_MS,
    formatSavedCardLabel,
    classifyCheckoutPayError,
    isOfflineLikeError,
    waitForOrderSettled
  } from "../lib/shopOneClickPay.js"
  import CheckoutPayButton from "../components/CheckoutPayButton.svelte"
  import CheckoutInlinePayment from "../components/CheckoutInlinePayment.svelte"
  import { buildInlinePaymentSession, SAVED_CARD_RETRY_MS, SAVED_CARD_RETRY_ATTEMPTS } from "../lib/shopCheckoutInlinePay.js"
  import {
    getOperatingHours,
    loadOperatingHours,
    shopIsOpenForPay,
    subscribeOperatingHours
  } from "../lib/shopOperatingHours.js"

  let name = $state("")
  let email = $state("")
  let otpCode = $state("")
  let payment_method = $state("card")
  let sbpNotice = $state(false)
  let emailVerified = $state(false)
  let sendingCode = $state(false)
  let verifyingCode = $state(false)
  let otpNotice = $state("")
  let err = $state(null)
  let savedProfile = $state(false)
  let profileSyncing = $state(true)
  let editContact = $state(true)
  let savedCard = $state(null)
  let savedCardsLoading = $state(false)
  let useOneClick = $state(true)
  let payState = $state(PAY_BTN.idle)
  let payError = $state(null)
  let clientOrderUuid = $state(null)
  let operatingHours = $state(getOperatingHours())
  let inlineSession = $state(null)
  let inlineAwaitingOnly = $state(false)

  const payBusy = $derived(
    payState === PAY_BTN.loading ||
      payState === PAY_BTN.ordering ||
      payState === PAY_BTN.paying ||
      payState === PAY_BTN.awaiting ||
      payState === PAY_BTN.success
  )
  const canPay = $derived(
    isValidEmail(email) && emailVerified && !payBusy && shopIsOpenForPay()
  )
  const showSavedCard = $derived(
    payment_method === "card" && useOneClick && savedCard && emailVerified
  )
  const savedCardLabel = $derived(formatSavedCardLabel(savedCard))
  const canSendCode = $derived(isValidEmail(email) && !sendingCode)

  function applyServerVerificationStatus(status) {
    const normalized = email.trim().toLowerCase()
    const serverOk =
      status?.verified === true && status?.email === normalized && isValidEmail(email)
    if (serverOk) {
      emailVerified = true
      editContact = false
      saveGuestProfile({ name, email, emailVerified: true })
      otpNotice = ""
      return true
    }
    emailVerified = false
    editContact = true
    clearEmailVerifiedInProfile()
    otpNotice = ""
    return false
  }

  async function syncServerStatus() {
    if (!isValidEmail(email)) {
      emailVerified = false
      return false
    }
    try {
      const q = encodeURIComponent(email.trim().toLowerCase())
      const status = await api(`/email_otp/status?email=${q}`)
      return applyServerVerificationStatus(status)
    } catch {
      return emailVerified
    }
  }

  async function loadSavedCards() {
    if (!emailVerified || !isValidEmail(email)) {
      savedCard = null
      return
    }
    savedCardsLoading = true
    try {
      const q = encodeURIComponent(email.trim().toLowerCase())
      const res = await api(`/saved_cards?email=${q}`)
      savedCard = res?.primary || null
    } catch {
      savedCard = null
    } finally {
      savedCardsLoading = false
    }
  }

  onMount(() => {
    const profile = loadGuestProfile()
    if (profile) {
      name = profile.name
      email = profile.email
      savedProfile = true
      if (profile.emailVerified) {
        emailVerified = true
        editContact = false
      } else {
        editContact = true
      }
    }

    const recover = async () => {
      if (await resumeInlinePayment()) return
      const orderId = lastGuestOrderId()
      if (!orderId) return
      await reconnectGuestOrder(api)
      if (returningFromPaymentPage()) {
        push(`/payment-result?status=fail&order_id=${orderId}`)
      }
    }

    const boot = async () => {
      profileSyncing = true
      await recover()
      await loadOperatingHours(api)
      await syncServerStatus()
      await loadSavedCards()
      profileSyncing = false
    }

    boot()
    const offHours = subscribeOperatingHours((next) => {
      operatingHours = next
    })
    const onPageShow = (event) => {
      if (event.persisted) boot()
    }
    window.addEventListener("pageshow", onPageShow)
    return () => {
      window.removeEventListener("pageshow", onPageShow)
      offHours()
    }
  })

  $effect(() => {
    if (emailVerified && isValidEmail(email)) {
      loadSavedCards()
    } else {
      savedCard = null
    }
  })

  function selectPayment(val) {
    if (val === "sbp") {
      sbpNotice = true
      return
    }
    sbpNotice = false
    payment_method = val
  }

  function onEmailInput() {
    emailVerified = false
    editContact = true
    otpNotice = ""
    clearEmailVerifiedInProfile()
    savedCard = null
    useOneClick = true
  }

  async function sendCode() {
    if (!canSendCode) return
    err = null
    otpNotice = ""
    sendingCode = true
    try {
      await api("/email_otp/send", {
        method: "POST",
        body: JSON.stringify({ email: email.trim().toLowerCase() })
      })
      otpNotice = "Код отправлен на почту"
      emailVerified = false
    } catch (e) {
      err = e.message
    } finally {
      sendingCode = false
    }
  }

  async function verifyCode() {
    if (!isValidEmail(email) || !otpCode.trim()) return
    err = null
    verifyingCode = true
    try {
      const res = await api("/email_otp/verify", {
        method: "POST",
        body: JSON.stringify({
          email: email.trim().toLowerCase(),
          code: otpCode.trim()
        })
      })
      if (res?.verified) {
        emailVerified = true
        otpNotice = "Email подтверждён"
        saveGuestProfile({ name, email, emailVerified: true })
        savedProfile = true
        editContact = false
        await loadSavedCards()
      }
    } catch (e) {
      emailVerified = false
      err = e.message
    } finally {
      verifyingCode = false
    }
  }

  function beginPayLoading() {
    err = null
    payError = null
    payState = PAY_BTN.loading
  }

  function beginPayOrdering() {
    err = null
    payError = null
    payState = PAY_BTN.ordering
  }

  async function resumeInlinePayment() {
    const pending = loadPaymentSession()
    if (!pending?.order_id || !pending.payment_started) return false

    inlineSession = pending
    inlineAwaitingOnly = true
    payState = PAY_BTN.awaiting
    await reconnectGuestOrder(api)

    try {
      const token = pending.reconnect_token
      const q = token ? `?reconnect_token=${encodeURIComponent(token)}` : ""
      const res = await api(`/orders/${pending.order_id}/finalize${q}`, { method: "POST" })
      if (res.payment_settled || res.status === "accepted") {
        await completeInlineSuccess(pending.order_id)
        return true
      }
    } catch {
      /* poll via CheckoutInlinePayment */
    }
    return true
  }

  async function refreshSavedCardsAfterPayment() {
    for (let attempt = 0; attempt < SAVED_CARD_RETRY_ATTEMPTS; attempt += 1) {
      await loadSavedCards()
      if (savedCard) return
      await new Promise((resolve) => setTimeout(resolve, SAVED_CARD_RETRY_MS))
    }
  }

  async function completeInlineSuccess(orderId) {
    clearPaymentSession()
    inlineSession = null
    inlineAwaitingOnly = false
    await refreshSavedCardsAfterPayment()
    await redirectAfterSuccess(orderId)
  }

  function handleInlineFail(message) {
    payError = classifyCheckoutPayError(message || "Оплата не прошла")
    payState = PAY_BTN.error
    inlineSession = null
    inlineAwaitingOnly = false
  }

  function resetPayIdle() {
    payState = PAY_BTN.idle
    payError = null
  }

  async function redirectAfterSuccess(orderId) {
    payState = PAY_BTN.success
    await new Promise((r) => setTimeout(r, SUCCESS_REDIRECT_MS))
    clearGuestOrderSession()
    push(`/order/${orderId}`)
  }

  async function submitOneClick() {
    if (!canPay || !savedCard?.id) return
    beginPayLoading()
    if (!clientOrderUuid) clientOrderUuid = crypto.randomUUID()

    try {
      const serverOk = await syncServerStatus()
      if (!serverOk) {
        payError = classifyCheckoutPayError("Подтвердите email кодом из письма")
        payState = PAY_BTN.error
        return
      }

      const res = await api("/orders", {
        method: "POST",
        body: JSON.stringify({
          name,
          email: email.trim().toLowerCase(),
          payment_method: "card",
          saved_card_id: savedCard.id,
          client_order_uuid: clientOrderUuid
        })
      })

      saveGuestOrderSession(res.order_id, res.reconnect_token)
      saveGuestProfile({ name, email, emailVerified: true })
      clearCartCache()
      clientOrderUuid = null

      if (res.recurrent_charge) {
        await waitForOrderSettled(api, {
          orderId: res.order_id,
          reconnectToken: res.reconnect_token,
          subscribe: subscribeGuestOrderStatus
        })
        await redirectAfterSuccess(res.order_id)
        return
      }

      if (res.payment_url || res.provider_payment_id) {
        await handleOnlinePaymentRedirect(res)
        return
      }

      await redirectAfterSuccess(res.order_id)
    } catch (e) {
      if (isOfflineError(e) || isOfflineLikeError(e)) {
        payError = classifyCheckoutPayError("Сбой сети. Повторите позже.")
      } else {
        payError = classifyCheckoutPayError(e.message)
      }
      payState = PAY_BTN.error
      if (/подтвердите email/i.test(e.message || "")) {
        emailVerified = false
        editContact = true
        clearEmailVerifiedInProfile()
      }
    }
  }

  async function beginInlinePayment(res) {
    let config = {}
    try {
      config = await api("/config")
    } catch {
      config = {}
    }

    const session = buildInlinePaymentSession(res, config)
    savePaymentSession(session)
    inlineSession = session
    inlineAwaitingOnly = false
    payState = PAY_BTN.paying
  }

  async function handleOnlinePaymentRedirect(res) {
    if (res.payment_iframe && (res.provider_payment_id || res.payment_url)) {
      await beginInlinePayment(res)
      return
    }
    if (res.payment_url) {
      window.location.href = res.payment_url
    }
  }

  async function submitNewCard() {
    if (!canPay) return
    beginPayOrdering()
    if (!clientOrderUuid) clientOrderUuid = crypto.randomUUID()
    let inlineStarted = false

    try {
      const serverOk = await syncServerStatus()
      if (!serverOk) {
        payError = classifyCheckoutPayError("Подтвердите email кодом из письма")
        payState = PAY_BTN.error
        return
      }

      const orderBody = {
        name,
        email: email.trim().toLowerCase(),
        payment_method,
        client_order_uuid: clientOrderUuid
      }

      let res
      try {
        res = await api("/orders", {
          method: "POST",
          body: JSON.stringify(orderBody)
        })
      } catch (e) {
        if (isOfflineError(e)) {
          await enqueueOrder(orderBody)
          window.dispatchEvent(new CustomEvent("shop:offline-order-queued"))
          otpNotice = "Заказ сохранён. Отправим при появлении сети."
          resetPayIdle()
          return
        }
        throw e
      }

      saveGuestOrderSession(res.order_id, res.reconnect_token)
      saveGuestProfile({ name, email, emailVerified: true })
      clearCartCache()
      savedProfile = true
      editContact = false
      clientOrderUuid = null

      if (res.payment_url || res.provider_payment_id) {
        inlineStarted = true
        await handleOnlinePaymentRedirect(res)
        return
      }

      inlineStarted = true
      await redirectAfterSuccess(res.order_id)
    } catch (e) {
      payError = classifyCheckoutPayError(e.message)
      payState = PAY_BTN.error
      if (/подтвердите email/i.test(e.message || "")) {
        emailVerified = false
        editContact = true
        clearEmailVerifiedInProfile()
        otpNotice = "Подтвердите email кодом из письма"
      }
    } finally {
      if (!inlineStarted && payState === PAY_BTN.ordering) resetPayIdle()
    }
  }

  function submit() {
    if (showSavedCard) submitOneClick()
    else submitNewCard()
  }

  function bindOtherCard() {
    useOneClick = false
    payState = PAY_BTN.idle
    payError = null
    submitNewCard()
  }
</script>

<div>
  <div class="mb-4 flex items-center gap-3">
    <button type="button" class="text-2xl text-[#ff8c42]" onclick={() => push("/cart")} aria-label="Назад в корзину">
      ‹
    </button>
    <h1 class="text-xl font-bold">Оформление</h1>
  </div>

  {#if savedProfile && !editContact && emailVerified && !profileSyncing}
    <div class="mb-4 rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-4">
      <p class="mb-1 text-sm text-[#a0a0a0]">Контакты</p>
      <p class="font-medium text-white">{name}</p>
      <p class="text-sm text-[#a0a0a0]">{maskEmail(email)}</p>
      <button
        type="button"
        class="mt-2 text-sm text-[#ff8c42]"
        onclick={() => {
          editContact = true
          emailVerified = false
          otpCode = ""
        }}
      >
        Изменить
      </button>
    </div>
  {:else}
    <label class="mb-3 block">
      <span class="mb-1 block text-sm text-[#a0a0a0]">Имя</span>
      <input
        bind:value={name}
        class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2"
        autocomplete="name"
      />
    </label>
    <label class="mb-3 block">
      <span class="mb-1 block text-sm text-[#a0a0a0]">Email</span>
      <input
        bind:value={email}
        oninput={onEmailInput}
        type="email"
        inputmode="email"
        autocomplete="email"
        class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2"
        placeholder="you@example.com"
      />
    </label>
    <div class="mb-3 flex gap-2">
      <button
        type="button"
        class="rounded-lg bg-[#3a3a3a] px-4 py-2 text-sm text-white disabled:opacity-50"
        disabled={!canSendCode}
        onclick={sendCode}
      >
        {sendingCode ? "Отправляем…" : "Отправить код"}
      </button>
    </div>
    <label class="mb-3 block">
      <span class="mb-1 block text-sm text-[#a0a0a0]">Код из письма</span>
      <input
        bind:value={otpCode}
        inputmode="numeric"
        maxlength="6"
        class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2 tracking-widest"
        placeholder="123456"
      />
    </label>
    <button
      type="button"
      class="mb-4 w-full rounded-lg border border-[#ff8c42] py-2 text-sm text-[#ff8c42] disabled:opacity-50"
      disabled={verifyingCode || !otpCode.trim() || !isValidEmail(email)}
      onclick={verifyCode}
    >
      {verifyingCode ? "Проверяем…" : "Подтвердить email"}
    </button>
    {#if otpNotice}
      <p class="mb-3 text-sm text-green-400" role="status">{otpNotice}</p>
    {/if}
  {/if}

  <div class="mb-6">
    <span class="mb-2 block text-sm text-[#a0a0a0]">Способ оплаты</span>
    <div class="flex gap-3">
      {#each [["card", "Картой"]] as [val, label]}
        <button
          type="button"
          class="flex flex-1 items-center justify-center gap-2 rounded-lg border px-3 py-2 text-sm
            {payment_method === val ? 'border-[#ff8c42] bg-[#ff8c42]/10 text-[#ff8c42]' : 'border-[#3a3a3a] text-[#a0a0a0]'}"
          onclick={() => selectPayment(val)}
        >
          {label}
        </button>
      {/each}
      <button
        type="button"
        class="flex flex-1 items-center justify-center gap-2 rounded-lg border border-[#3a3a3a] px-3 py-2 text-sm text-[#757575] opacity-60"
        aria-disabled="true"
        onclick={() => selectPayment("sbp")}
      >
        СБП
      </button>
    </div>
    {#if sbpNotice}
      <p class="mt-2 text-sm text-[#a0a0a0]" role="status">Будет позже</p>
    {/if}
  </div>

  {#if showSavedCard}
    <div class="mb-4 rounded-xl border border-[#ff8c42]/30 bg-[#2a2a2a] p-4" data-testid="saved-card-block">
      <p class="mb-1 text-sm text-[#a0a0a0]">Сохранённая карта</p>
      <p class="font-medium text-white">{savedCardLabel}</p>
      <button
        type="button"
        class="mt-2 text-sm text-[#ff8c42]"
        onclick={() => {
          useOneClick = false
          payState = PAY_BTN.idle
          payError = null
        }}
      >
        Оплатить другой картой
      </button>
    </div>
  {:else if savedCardsLoading && emailVerified}
    <p class="mb-4 text-sm text-[#a0a0a0]">Проверяем сохранённые карты…</p>
  {/if}

  {#if err}
    <p class="mb-4 text-sm text-red-400">{err}</p>
  {/if}

  {#if operatingHours.loaded && operatingHours.is_open === false && operatingHours.closed_message}
    <div
      class="mb-4 rounded-lg border border-amber-500/40 bg-amber-950/90 px-3 py-2 text-sm text-amber-100"
      role="status"
      data-testid="checkout-closed-banner"
    >
      {operatingHours.closed_message}
    </div>
  {/if}

  <CheckoutPayButton
    state={payState}
    disabled={!canPay || profileSyncing}
    errorInfo={payError}
    onPay={submit}
    onRetry={submit}
    onBindOther={bindOtherCard}
  />

  {#if inlineSession}
    <CheckoutInlinePayment
      session={inlineSession}
      awaitingOnly={inlineAwaitingOnly}
      onSettled={() => completeInlineSuccess(inlineSession.order_id)}
      onFail={handleInlineFail}
    />
  {/if}
</div>
