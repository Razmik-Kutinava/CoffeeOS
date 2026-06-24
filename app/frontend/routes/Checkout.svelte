<script>
  import { onMount, tick } from "svelte"
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
    clearGuestOrderSession,
    guestReconnectToken
  } from "../lib/shopGuestSession.js"
  import {
    savePaymentSession,
    loadPaymentSession,
    clearPaymentSession
  } from "../lib/tbankPayment.js"
  import { clearCartCache } from "../lib/shopCartCache.js"
  import { submitThreeDsChallenge } from "../lib/tbankCardEncrypt.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import { waitForOrderSettled } from "../lib/shopOneClickPay.js"
  import {
    PAY_FSM,
    MIN_LOADER_MS,
    SUCCESS_REDIRECT_MS,
    withMinLoaderMs,
    apiWithPayTimeout,
    fsmFromPaymentError,
    isPayFsmBusy,
    isPayFsmClickable
  } from "../lib/shopPayFsm.js"
  import {
    loadCachedSavedCard,
    saveCachedSavedCard,
    clearCachedSavedCard
  } from "../lib/shopSavedCardCache.js"
  import { formatCardListLabel } from "../lib/paymentMethodLabels.js"
  import PaymentMethodsSheet from "../components/PaymentMethodsSheet.svelte"
  import NewCardSheet from "../components/NewCardSheet.svelte"
  import ThreeDsOverlay from "../components/ThreeDsOverlay.svelte"
  import { SAVED_CARD_RETRY_MS, SAVED_CARD_RETRY_ATTEMPTS } from "../lib/shopCheckoutInlinePay.js"
  import {
    getOperatingHours,
    loadOperatingHours,
    shopIsOpenForPay,
    subscribeOperatingHours
  } from "../lib/shopOperatingHours.js"

  let name = $state("")
  let email = $state("")
  let otpCode = $state("")
  let emailVerified = $state(false)
  let sendingCode = $state(false)
  let verifyingCode = $state(false)
  let otpNotice = $state("")
  let err = $state(null)
  let savedProfile = $state(false)
  let profileSyncing = $state(true)
  let editContact = $state(true)
  let savedCard = $state(null)
  let savedCards = $state([])
  let savedCardsLoading = $state(false)
  let selectedCardId = $state(null)
  let selectionMode = $state("new_card")
  let payFsmState = $state(PAY_FSM.DEFAULT)
  let useOneClick = $state(true)
  let clientOrderUuid = $state(null)
  let showPaymentMethodsSheet = $state(false)
  let showNewCardSheet = $state(false)
  let showThreeDsOverlay = $state(false)
  let operatingHours = $state(getOperatingHours())

  const payBusy = $derived(isPayFsmBusy(payFsmState))
  const canPay = $derived(
    isValidEmail(email) &&
      emailVerified &&
      !payBusy &&
      !savedCardsLoading &&
      shopIsOpenForPay()
  )
  const paymentSummaryLabel = $derived(
    selectionMode === "saved_card" && savedCard
      ? formatCardListLabel(savedCard)
      : selectionMode === "new_card"
        ? "Новая карта"
        : "Выберите способ оплаты"
  )
  const canOpenPaymentSheet = $derived(
    isValidEmail(email) && emailVerified && !profileSyncing
  )
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

  function resetPaymentFsm() {
    payFsmState = PAY_FSM.DEFAULT
    showThreeDsOverlay = false
  }

  function selectSavedCard(card) {
    if (!card?.id) return
    savedCard = card
    selectedCardId = card.id
    selectionMode = "saved_card"
    useOneClick = true
    saveCachedSavedCard(email, card)
    resetPaymentFsm()
  }

  function selectNewCardOption() {
    selectionMode = "new_card"
    useOneClick = false
    selectedCardId = null
    resetPaymentFsm()
  }

  function applySavedCardFromSources(primary, cards = null) {
    if (Array.isArray(cards)) savedCards = cards
    if (primary?.id) {
      if (!savedCards.some((c) => c.id === primary.id)) {
        savedCards = [...savedCards, primary]
      }
      selectSavedCard(primary)
      return
    }
    const cached = loadCachedSavedCard(email)
    if (cached?.id) {
      selectSavedCard(cached)
      return
    }
    savedCard = null
    selectedCardId = null
    if (savedCards.length > 0) {
      selectSavedCard(savedCards[0])
      return
    }
    selectNewCardOption()
  }

  async function loadSavedCards() {
    if (!emailVerified || !isValidEmail(email)) {
      savedCard = null
      savedCards = []
      selectedCardId = null
      selectionMode = "new_card"
      return
    }
    savedCardsLoading = true
    try {
      const q = encodeURIComponent(email.trim().toLowerCase())
      const res = await api(`/saved_cards?email=${q}`)
      applySavedCardFromSources(res?.primary || null, res?.cards || [])
    } catch {
      applySavedCardFromSources(null, [])
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
      if (await resumePendingBankPayment()) return
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

  function onEmailInput() {
    emailVerified = false
    editContact = true
    otpNotice = ""
    clearEmailVerifiedInProfile()
    clearCachedSavedCard(email)
    savedCard = null
    savedCards = []
    selectedCardId = null
    selectionMode = "new_card"
    useOneClick = true
    showPaymentMethodsSheet = false
    resetPaymentFsm()
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

  function beginPayConnecting() {
    err = null
    payFsmState = PAY_FSM.CONNECTING
  }

  /** Возврат с банка без завершения — проверяем finalize. */
  async function resumePendingBankPayment() {
    const pending = loadPaymentSession()
    if (!pending?.order_id || !pending.payment_started) return false

    payFsmState = PAY_FSM.PROCESSING
    await reconnectGuestOrder(api)

    try {
      const token = pending.reconnect_token || guestReconnectToken()
      const q = token ? `?reconnect_token=${encodeURIComponent(token)}` : ""
      const res = await api(`/orders/${pending.order_id}/finalize${q}`, { method: "POST" })
      if (res.payment_settled || res.status === "accepted") {
        clearPaymentSession()
        if (res.saved_card) applySavedCardFromSources(res.saved_card)
        else await refreshSavedCardsAfterPayment()
        push(`/order/${pending.order_id}`)
        return true
      }
    } catch {
      /* оплата ещё не подтверждена */
    }

    clearPaymentSession()
    resetPayIdle()
    return false
  }

  async function refreshSavedCardsAfterPayment() {
    for (let attempt = 0; attempt < SAVED_CARD_RETRY_ATTEMPTS; attempt += 1) {
      await loadSavedCards()
      if (savedCard) return
      await new Promise((resolve) => setTimeout(resolve, SAVED_CARD_RETRY_MS))
    }
  }

  function resetPayIdle() {
    resetPaymentFsm()
  }

  async function completePaymentSuccess(orderId, savedCardPayload) {
    if (savedCardPayload) applySavedCardFromSources(savedCardPayload)
    else await refreshSavedCardsAfterPayment()
    payFsmState = PAY_FSM.SUCCESS
    clearPaymentSession()
    await new Promise((r) => setTimeout(r, SUCCESS_REDIRECT_MS))
    clearGuestOrderSession()
    showThreeDsOverlay = false
    showPaymentMethodsSheet = false
    showNewCardSheet = false
    push(`/order/${orderId}`)
  }

  async function settleAfterCharge(orderId, reconnectToken) {
    payFsmState = PAY_FSM.PROCESSING
    const settled = await waitForOrderSettled(api, {
      orderId,
      reconnectToken,
      subscribe: subscribeGuestOrderStatus
    })
    await completePaymentSuccess(orderId, settled?.saved_card)
  }

  async function handleThreeDsResponse(res) {
    payFsmState = PAY_FSM.THREE_DS
    showThreeDsOverlay = true
    savePaymentSession({
      order_id: res.order_id,
      reconnect_token: res.reconnect_token,
      payment_started: true,
      card_binding: res.save_card === true
    })
    try {
      await tick()
      submitThreeDsChallenge(res.three_ds)
      await settleAfterCharge(res.order_id, res.reconnect_token)
    } catch (e) {
      showThreeDsOverlay = false
      payFsmState = fsmFromPaymentError(e, { httpStatus: e.httpStatus })
    }
  }

  async function handlePaymentResponse(res) {
    saveGuestOrderSession(res.order_id, res.reconnect_token)
    saveGuestProfile({ name, email, emailVerified: true })
    clearCartCache()
    clientOrderUuid = null

    if (res.tbank_status === "3DS_CHECKING" && res.three_ds?.acs_url) {
      await handleThreeDsResponse(res)
      return
    }

    if (res.tbank_status === "CONFIRMED" || res.status === "accepted") {
      await completePaymentSuccess(res.order_id, res.saved_card)
      return
    }

    if (res.recurrent_charge || res.provider_payment_id) {
      await settleAfterCharge(res.order_id, res.reconnect_token)
      return
    }

    payFsmState = PAY_FSM.BANK_ERROR
  }

  async function submitOneClick() {
    if (!canPay || !savedCard?.id) return
    if (!isPayFsmClickable(payFsmState)) return

    beginPayConnecting()
    if (!clientOrderUuid) clientOrderUuid = crypto.randomUUID()

    try {
      const serverOk = await syncServerStatus()
      if (!serverOk) {
        payFsmState = PAY_FSM.CLIENT_ERROR
        return
      }

      const res = await withMinLoaderMs(MIN_LOADER_MS, async () => {
        payFsmState = PAY_FSM.CONNECTING
        const payload = await apiWithPayTimeout(api, "/payments/one_click", {
          method: "POST",
          body: JSON.stringify({
            name,
            email: email.trim().toLowerCase(),
            payment_method: "card",
            card_id: savedCard.id,
            client_order_uuid: clientOrderUuid
          })
        })
        payFsmState = PAY_FSM.PROCESSING
        return payload
      })

      await handlePaymentResponse(res)
    } catch (e) {
      payFsmState = fsmFromPaymentError(e, { httpStatus: e.httpStatus })
      if (/подтвердите email/i.test(e.message || "")) {
        emailVerified = false
        editContact = true
        clearEmailVerifiedInProfile()
      }
    }
  }

  async function handleNewCardSuccess(res) {
    showNewCardSheet = false
    await handlePaymentResponse(res)
  }

  async function handleNewCardThreeDs(res) {
    showNewCardSheet = false
    showPaymentMethodsSheet = false
    await handleThreeDsResponse(res)
  }

  function handleNewCardFsmChange(state) {
    payFsmState = state
  }

  function openPaymentMethodsSheet() {
    if (!canOpenPaymentSheet) return
    err = null
    showPaymentMethodsSheet = true
  }

  function openNewCardSheet() {
    if (!canPay) return
    err = null
    showNewCardSheet = true
  }

  async function handlePayFromSheet() {
    if (savedCardsLoading) await loadSavedCards()
    if (selectionMode === "saved_card") {
      await submitOneClick()
      return
    }
    showPaymentMethodsSheet = false
    openNewCardSheet()
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

  {#if emailVerified}
    <button
      type="button"
      class="mb-6 w-full rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-4 text-left disabled:opacity-50"
      disabled={!canOpenPaymentSheet}
      data-testid="payment-method-summary"
      onclick={openPaymentMethodsSheet}
    >
      <span class="mb-1 block text-sm text-[#a0a0a0]">Способ оплаты</span>
      <span class="flex items-center justify-between gap-2 font-medium text-white">
        {#if savedCardsLoading}
          Проверяем карты…
        {:else}
          {paymentSummaryLabel}
        {/if}
        <span class="text-[#ff8c42]" aria-hidden="true">›</span>
      </span>
    </button>
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

  <PaymentMethodsSheet
    open={showPaymentMethodsSheet}
    cards={savedCards}
    loading={savedCardsLoading}
    {selectedCardId}
    {selectionMode}
    fsmState={payFsmState}
    {canPay}
    onClose={() => {
      if (isPayFsmClickable(payFsmState)) showPaymentMethodsSheet = false
    }}
    onSelectCard={selectSavedCard}
    onSelectNewCard={selectNewCardOption}
    onPay={handlePayFromSheet}
    onRetry={handlePayFromSheet}
  />

  <NewCardSheet
    open={showNewCardSheet}
    {name}
    {email}
    cardHolderName={name}
    fsmState={payFsmState}
    onFsmChange={handleNewCardFsmChange}
    onClose={() => {
      if (isPayFsmClickable(payFsmState)) showNewCardSheet = false
    }}
    onSuccess={handleNewCardSuccess}
    onThreeDs={handleNewCardThreeDs}
  />

  <ThreeDsOverlay
    open={showThreeDsOverlay}
    onClose={() => {
      if (payFsmState === PAY_FSM.THREE_DS) {
        showThreeDsOverlay = false
        payFsmState = PAY_FSM.BANK_ERROR
      }
    }}
  />
</div>
