<script>
  import { onMount, onDestroy, tick } from "svelte"
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
    saveGuestOrderSession
  } from "../lib/shopGuestSession.js"
  import { savePaymentSession } from "../lib/tbankPayment.js"
  import {
    getOperatingHours,
    loadOperatingHours,
    shopIsOpenForPay,
    subscribeOperatingHours
  } from "../lib/shopOperatingHours.js"
  import {
    createNewCardFormState,
    isPayEnabled as isNewCardPayEnabled,
    setSaveCard
  } from "../lib/shopNewCardForm.js"
  import { encryptCardPayload, submitThreeDsChallenge } from "../lib/tbankCardEncrypt.js"
  import { digitsOnly } from "../lib/tbankCardFormat.js"
  import {
    PAY_FSM,
    MIN_LOADER_MS,
    SUCCESS_REDIRECT_MS,
    apiWithPayTimeout,
    fsmFromPaymentError,
    isPayFsmClickable,
    withMinLoaderMs
  } from "../lib/shopPayFsm.js"
  import { waitForOrderSettled } from "../lib/shopPaySettle.js"
  import { loadSavedCardsWithRetry } from "../lib/shopSavedCards.js"
  import {
    ensureCheckoutCartPeek,
    CHECKOUT_PAY_EVENT,
    openCheckoutPayStack,
    closeCheckoutPayStack
  } from "../lib/cartSheetStore.js"
  import { REPEAT_AUTOPAY_KEY, refreshFrequentProducts } from "../lib/frequentRepeatStore.js"
  import { restoreGuestSession } from "../lib/restoreGuestSession.js"
  import PaymentMethodsSheet from "../components/PaymentMethodsSheet.svelte"
  import ThreeDsOverlay from "../components/ThreeDsOverlay.svelte"

  let name = $state("")
  let email = $state("")
  let otpCode = $state("")
  let emailVerified = $state(false)
  let sendingCode = $state(false)
  let verifyingCode = $state(false)
  let otpNotice = $state("")
  let submitting = $state(false)
  let err = $state(null)
  let savedProfile = $state(false)
  let editContact = $state(true)
  let operatingHours = $state(getOperatingHours())

  // Шаг 3: экран выбора карт (1000008925)
  let paymentSheetOpen = $state(false)
  let savedCards = $state([])
  let cardsLoading = $state(false)
  let selectedCardId = $state(null)
  let selectionMode = $state("saved_card") // saved_card | new_card
  let newCardState = $state(createNewCardFormState())
  let payFsmState = $state(PAY_FSM.DEFAULT)
  let showThreeDsOverlay = $state(false)
  let threeDsAborted = $state(false)

  const canSendCode = $derived(isValidEmail(email) && !sendingCode)
  const canPay = $derived(
    isValidEmail(email) && emailVerified && !submitting && shopIsOpenForPay()
  )
  const sheetCanPay = $derived(
    canPay &&
      (selectionMode === "saved_card"
        ? !!selectedCardId
        : isNewCardPayEnabled(newCardState))
  )
  /** Место под peek-шторку заказа; при оплате — полный stacked stack. */
  const checkoutPadClass = $derived(paymentSheetOpen ? "pb-[92vh]" : "pb-[32vh]")

  function closePaymentSheet() {
    paymentSheetOpen = false
    closeCheckoutPayStack()
  }

  onMount(() => {
    const profile = loadGuestProfile()
    if (profile) {
      name = profile.name
      email = profile.email
      emailVerified = profile.emailVerified
      savedProfile = true
      editContact = false
    }

    ensureCheckoutCartPeek().catch(() => {})

    const onCheckoutPay = () => {
      openPaymentSheet()
    }
    window.addEventListener(CHECKOUT_PAY_EVENT, onCheckoutPay)

    // «Оплатить в 1 клик» из секции повтора: снять флаг и сразу открыть шит оплаты
    try {
      if (sessionStorage.getItem(REPEAT_AUTOPAY_KEY)) {
        sessionStorage.removeItem(REPEAT_AUTOPAY_KEY)
        openPaymentSheet()
      }
    } catch (_e) {
      /* ignore */
    }

    const syncServerStatus = async () => {
      const result = await restoreGuestSession()
      if (result.verified) {
        emailVerified = true
        return
      }
      // Сеть упала — локальный флаг не сбрасываем; сервер «не verified» — уже сбросил в profile
      const profile = loadGuestProfile()
      emailVerified = !!(
        profile &&
        profile.email === email.trim().toLowerCase() &&
        profile.emailVerified
      )
    }

    const recover = async () => {
      const orderId = lastGuestOrderId()
      if (!orderId) return
      await reconnectGuestOrder(api)
      if (returningFromPaymentPage()) {
        push(`/payment-result?status=fail&order_id=${orderId}`)
      }
    }

    recover()
    syncServerStatus()
    loadOperatingHours(api)
    const offHours = subscribeOperatingHours((next) => {
      operatingHours = next
    })

    const onPageShow = (event) => {
      if (event.persisted) recover()
    }
    window.addEventListener("pageshow", onPageShow)
    return () => {
      window.removeEventListener("pageshow", onPageShow)
      window.removeEventListener(CHECKOUT_PAY_EVENT, onCheckoutPay)
      offHours?.()
      closeCheckoutPayStack()
    }
  })

  onDestroy(() => {
    closeCheckoutPayStack()
  })

  async function loadSavedCards() {
    if (!isValidEmail(email) || !emailVerified) {
      savedCards = []
      return
    }
    cardsLoading = true
    try {
      const q = encodeURIComponent(email.trim().toLowerCase())
      const res = await api(`/user/cards?email=${q}`)
      savedCards = Array.isArray(res?.cards) ? res.cards : []
      const primary = res?.primary
      if (primary?.id) {
        selectedCardId = primary.id
        selectionMode = "saved_card"
      } else if (savedCards[0]?.id) {
        selectedCardId = savedCards[0].id
        selectionMode = "saved_card"
      } else {
        selectedCardId = null
      }
    } catch {
      savedCards = []
    } finally {
      cardsLoading = false
    }
  }

  async function openPaymentSheet() {
    err = null
    if (!isValidEmail(email)) {
      err = "Укажите email"
      editContact = true
      return
    }
    if (!emailVerified) {
      err = "Подтвердите email кодом из письма"
      editContact = true
      return
    }
    if (!shopIsOpenForPay()) {
      err = operatingHours.closed_message || "Сейчас нельзя оформить заказ"
      return
    }
    if (submitting) return
    openCheckoutPayStack()
    paymentSheetOpen = true
    await loadSavedCards()
  }

  function onEmailInput() {
    const profile = loadGuestProfile()
    if (profile && profile.email === email.trim().toLowerCase() && profile.emailVerified) {
      emailVerified = true
      return
    }
    emailVerified = false
    otpNotice = ""
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
      await api("/email_otp/verify", {
        method: "POST",
        body: JSON.stringify({
          email: email.trim().toLowerCase(),
          code: otpCode.trim()
        })
      })
      emailVerified = true
      otpNotice = "Email подтверждён"
      saveGuestProfile({ name, email, emailVerified: true })
      savedProfile = true
      editContact = false
      await refreshFrequentProducts(email.trim().toLowerCase())
    } catch (e) {
      emailVerified = false
      err = e.message
    } finally {
      verifyingCode = false
    }
  }

  function onSelectCard(card) {
    selectionMode = "saved_card"
    selectedCardId = card.id
    payFsmState = PAY_FSM.DEFAULT
  }

  function onSelectNewCard() {
    selectionMode = "new_card"
    selectedCardId = null
    newCardState = createNewCardFormState()
    payFsmState = PAY_FSM.DEFAULT
  }

  /** 3DS прерван (закрыли overlay) → Client Error, карта не сохранена на FE. */
  function onThreeDsClose() {
    if (payFsmState !== PAY_FSM.THREE_DS && payFsmState !== PAY_FSM.PROCESSING) {
      showThreeDsOverlay = false
      return
    }
    threeDsAborted = true
    showThreeDsOverlay = false
    payFsmState = PAY_FSM.CLIENT_ERROR
    submitting = false
  }

  async function completePaySuccess(orderId, { wantedSave = false, savedCard = null } = {}) {
    payFsmState = PAY_FSM.SUCCESS
    selectionMode = "saved_card"
    // После 3DS/soft-fail: stale saved_card из FA-ответа ненадёжен — ретраим GET.
    let cards = []
    if (wantedSave && !savedCard) {
      cards = await loadSavedCardsWithRetry(
        async () => {
          await loadSavedCards()
          return savedCards
        },
        { attempts: 5, delayMs: 400 }
      )
    } else {
      await loadSavedCards()
      cards = savedCards
    }
    const appeared = Array.isArray(cards) && cards.length > 0
    if (wantedSave && !savedCard && !appeared) {
      newCardState = setSaveCard(createNewCardFormState(), false)
    } else {
      newCardState = createNewCardFormState()
    }
    await new Promise((r) => setTimeout(r, SUCCESS_REDIRECT_MS))
    closePaymentSheet()
    push(`/payment-result?status=ok&order_id=${orderId}`)
  }

  async function handleThreeDsResponse(res) {
    threeDsAborted = false
    payFsmState = PAY_FSM.THREE_DS
    showThreeDsOverlay = true
    saveGuestOrderSession(res.order_id, res.reconnect_token)
    savePaymentSession({
      order_id: res.order_id,
      reconnect_token: res.reconnect_token,
      payment_started: true
    })
    try {
      await tick()
      submitThreeDsChallenge(res.three_ds)
      payFsmState = PAY_FSM.PROCESSING
      await waitForOrderSettled(api, {
        orderId: res.order_id,
        reconnectToken: res.reconnect_token,
        isCancelled: () => threeDsAborted
      })
      if (threeDsAborted) return
      showThreeDsOverlay = false
      // FA 3DS-ответ ещё без saved_card — completePaySuccess ретраит список.
      await completePaySuccess(res.order_id, {
        wantedSave: res.save_card === true,
        savedCard: null
      })
    } catch (e) {
      showThreeDsOverlay = false
      if (threeDsAborted || e?.kind === "three_ds_abort") {
        payFsmState = PAY_FSM.CLIENT_ERROR
        return
      }
      if (payFsmState !== PAY_FSM.CLIENT_ERROR) {
        payFsmState = fsmFromPaymentError(e, { httpStatus: e.httpStatus })
      }
    }
  }

  async function onSheetPay() {
    if (!sheetCanPay) return
    if (!isPayFsmClickable(payFsmState)) return
    err = null
    submitting = true
    payFsmState = PAY_FSM.CONNECTING
    const formSnapshot = { ...newCardState }
    const wantedSave = selectionMode === "new_card" ? !!newCardState.save_card : false

    try {
      saveGuestProfile({ name, email, emailVerified: true })

      const res = await withMinLoaderMs(MIN_LOADER_MS, async () => {
        payFsmState = PAY_FSM.CONNECTING
        let payload
        if (selectionMode === "new_card") {
          const cfg = await apiWithPayTimeout(api, "/payments/card_config")
          if (!cfg?.rsa_public_key) {
            throw new Error("Ключ шифрования карты не настроен")
          }
          const CardData = encryptCardPayload(
            {
              pan: digitsOnly(newCardState.pan_masked),
              expDate: newCardState.exp_date,
              cvv: newCardState.cvv,
              cardHolder: name
            },
            cfg.rsa_public_key
          )
          payload = await apiWithPayTimeout(api, "/payments/new_card", {
            method: "POST",
            body: JSON.stringify({
              name,
              email: email.trim().toLowerCase(),
              payment_method: "card",
              CardData,
              save_card: wantedSave
            })
          })
        } else {
          payload = await apiWithPayTimeout(api, "/payments/one_click", {
            method: "POST",
            body: JSON.stringify({
              name,
              email: email.trim().toLowerCase(),
              payment_method: "card",
              card_id: selectedCardId
            })
          })
        }
        payFsmState = PAY_FSM.PROCESSING
        return payload
      })

      saveGuestOrderSession(res.order_id, res.reconnect_token)

      if (res.three_ds?.acs_url || res.tbank_status === "3DS_CHECKING") {
        await handleThreeDsResponse(res)
        return
      }

      await completePaySuccess(res.order_id, {
        wantedSave,
        savedCard: res.saved_card
      })
    } catch (e) {
      // Net/Client Error: форма новой карты остаётся заполненной.
      if (selectionMode === "new_card") {
        newCardState = formSnapshot
      }
      payFsmState = fsmFromPaymentError(e, { httpStatus: e.httpStatus })
      if (/подтвердите email/i.test(e.message || "")) {
        emailVerified = false
        editContact = true
        clearEmailVerifiedInProfile()
        err = e.message
      }
    } finally {
      if (payFsmState !== PAY_FSM.SUCCESS && payFsmState !== PAY_FSM.THREE_DS) {
        submitting = false
      }
    }
  }

  function onSheetPayRetry() {
    payFsmState = PAY_FSM.DEFAULT
    onSheetPay()
  }
</script>

<div class={checkoutPadClass} data-testid="checkout-page">
  <div class="mb-4 flex items-center gap-3">
    <button type="button" class="text-2xl text-[#ff8c42]" onclick={() => push("/")} aria-label="Назад в каталог">
      ‹
    </button>
    <h1 class="text-xl font-bold">Оформление</h1>
  </div>

  {#if savedProfile && !editContact && emailVerified}
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

  {#if err}
    <p class="mb-4 text-sm text-red-400" role="alert">{err}</p>
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

  <p class="mb-2 text-sm text-[#a0a0a0]" data-testid="checkout-pay-via-cart-hint">
    Оплата — кнопка «+сумма» в шторке заказа внизу экрана.
  </p>

  <PaymentMethodsSheet
    open={paymentSheetOpen}
    stacked={paymentSheetOpen}
    cards={savedCards}
    loading={cardsLoading}
    {selectedCardId}
    {selectionMode}
    canPay={sheetCanPay}
    fsmState={payFsmState}
    bind:newCardState
    onClose={() => {
      if (isPayFsmClickable(payFsmState)) closePaymentSheet()
    }}
    {onSelectCard}
    {onSelectNewCard}
    onPay={onSheetPay}
    onRetry={onSheetPayRetry}
  />

  <ThreeDsOverlay open={showThreeDsOverlay} onClose={onThreeDsClose} />
</div>
