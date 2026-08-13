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
  import { saveShopRefreshToken } from "../lib/shopLocalStorage.js"
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
    resolveCheckoutSheetInlineError,
    shouldAutoOpenNewCardOnClientError,
    withMinLoaderMs
  } from "../lib/shopPayFsm.js"
  import { waitForOrderSettled } from "../lib/shopPaySettle.js"
  import { loadSavedCardsWithRetry } from "../lib/shopSavedCards.js"
  import {
    ensureCheckoutCartPeek,
    CHECKOUT_PAY_EVENT,
    openCheckoutPayStack,
    closeCheckoutPayStack,
    cartSheetError
  } from "../lib/cartSheetStore.js"
  import { REPEAT_AUTOPAY_KEY } from "../lib/frequentRepeatStore.js"
  import { restoreGuestSession } from "../lib/restoreGuestSession.js"
  import { paymentMethodLoadErrorMessage } from "../lib/paymentMethodI18n.js"
  import { initSbpPayment, redirectToSbp } from "../lib/shopSbpPay.js"
  import {
    chargeSbpAutopay,
    pickDefaultPaymentSelection,
    resolveSaveSbpAccountForSbpMode,
    DEFAULT_SAVE_SBP_ACCOUNT,
    SBP_AUTOPAY_TOASTS
  } from "../lib/shopSbpAutopay.js"
  import { savePendingOrder } from "../lib/codeblackPendingOrder.js"
  import {
    setTokenInvalid,
    clearTokenInvalid,
    persistPaymentSelection,
    loadPaymentSelection,
    consumeOpenPaymentSheet,
    mapPaymentErrorSurface,
    isInvalidRebillPaymentError,
    refreshInvalidRebillFlag
  } from "../lib/repeatInvalidTokenStore.js"
  import { formatPhoneMask, normalizePhoneToE164Ru } from "../lib/phoneOtp.js"
  import PaymentMethodsSheet from "../components/PaymentMethodsSheet.svelte"
  import PhoneAuthWizard from "../components/PhoneAuthWizard.svelte"
  import ThreeDsOverlay from "../components/ThreeDsOverlay.svelte"

  let name = $state("")
  let email = $state("")
  let emailVerified = $state(false)
  let phoneDisplay = $state("+7")
  let phoneVerified = $state(false)
  let otpNotice = $state("")
  let offerSaveToProfile = $state(false)
  let savingToProfile = $state(false)
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
  let selectionMode = $state("saved_card") // saved_card | new_card | sbp | sbp_account
  let saveSbpAccount = $state(DEFAULT_SAVE_SBP_ACCOUNT)
  let saveSbpAccountTouched = $state(false)
  let sbpAccounts = $state([])
  let newCardState = $state(createNewCardFormState())
  let payFsmState = $state(PAY_FSM.DEFAULT)
  let showThreeDsOverlay = $state(false)
  let threeDsAborted = $state(false)
  let sheetInlineError = $state(null)
  let cardsLoadError = $state(null)

  const phoneE164 = $derived(normalizePhoneToE164Ru(phoneDisplay))
  const identityReady = $derived(
    phoneVerified || (isValidEmail(email) && emailVerified)
  )
  const canPay = $derived(identityReady && !submitting && shopIsOpenForPay())
  const sheetCanPay = $derived(
    canPay &&
      (selectionMode === "sbp" || selectionMode === "sbp_account"
        ? true
        : selectionMode === "saved_card"
          ? !!selectedCardId
          : isNewCardPayEnabled(newCardState))
  )
  /** Место под peek-шторку заказа; при оплате — полный stacked stack. */
  const checkoutPadClass = $derived(paymentSheetOpen ? "pb-[92vh]" : "pb-[32vh]")

  function closePaymentSheet() {
    persistPaymentSelection({ selectedCardId, selectionMode })
    paymentSheetOpen = false
    sheetInlineError = null
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

    // Автозаполнение из серверного профиля (Email↔Phone merge)
    api("profile")
      .then((p) => {
        if (!p?.id) return
        if (p.first_name || p.last_name) {
          name = [p.first_name, p.last_name].filter(Boolean).join(" ")
        } else if (p.name) {
          name = p.name
        }
        if (p.email) {
          email = p.email
          emailVerified = !!p.email_verified
        }
        if (p.phone) {
          phoneDisplay = formatPhoneMask(p.phone)
          phoneVerified = !!p.phone_verified
        }
        savedProfile = true
        editContact = false
      })
      .catch(() => {})

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
      } else if (consumeOpenPaymentSheet()) {
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
    if (!identityReady) {
      savedCards = []
      sbpAccounts = []
      cardsLoadError = null
      return true
    }
    cardsLoading = true
    cardsLoadError = null
    try {
      const q =
        isValidEmail(email) && emailVerified
          ? `?email=${encodeURIComponent(email.trim().toLowerCase())}`
          : ""
      const res = await api(`/user/cards${q}`)
      savedCards = Array.isArray(res?.cards) ? res.cards : []
      sbpAccounts = Array.isArray(res?.sbp_accounts) ? res.sbp_accounts : []
      const primary = res?.primary
      const persisted = loadPaymentSelection()
      const picked = pickDefaultPaymentSelection({
        sbpAccounts,
        cards: savedCards,
        primary,
        persisted
      })
      selectedCardId = picked.selectedCardId
      selectionMode = picked.selectionMode
      if (selectionMode === "sbp") {
        saveSbpAccount = resolveSaveSbpAccountForSbpMode({
          userTouched: saveSbpAccountTouched,
          current: saveSbpAccount
        })
      }
      return true
    } catch (e) {
      savedCards = []
      sbpAccounts = []
      cardsLoadError = e?.message || paymentMethodLoadErrorMessage()
      return false
    } finally {
      cardsLoading = false
    }
  }

  async function openPaymentSheet() {
    err = null
    sheetInlineError = null
    cardsLoadError = null
    if (!identityReady) {
      err = "Подтвердите телефон"
      editContact = true
      return
    }
    if (!shopIsOpenForPay()) {
      err = operatingHours.closed_message || "Сейчас нельзя оформить заказ"
      return
    }
    if (submitting) return
    const loaded = await loadSavedCards()
    if (!loaded) {
      cartSheetError.set(cardsLoadError || paymentMethodLoadErrorMessage())
      paymentSheetOpen = false
      closeCheckoutPayStack()
      return
    }
    openCheckoutPayStack()
    paymentSheetOpen = true
  }

  async function retryLoadSavedCards() {
    cardsLoadError = null
    sheetInlineError = null
    await loadSavedCards()
  }

  async function saveContactToProfile() {
    savingToProfile = true
    err = null
    try {
      if (emailVerified && isValidEmail(email)) {
        await api("profile", {
          method: "PATCH",
          body: JSON.stringify({
            first_name: name.trim().split(/\s+/)[0] || "Гость",
            last_name: name.trim().split(/\s+/).slice(1).join(" ")
          })
        })
      }
      offerSaveToProfile = false
      otpNotice = "Сохранено в профиль"
    } catch (e) {
      if (e.httpStatus === 401) {
        offerSaveToProfile = false
      } else {
        err = e.message
      }
    } finally {
      savingToProfile = false
    }
  }

  function onWizardPhoneChange(display) {
    phoneDisplay = display
    phoneVerified = false
    offerSaveToProfile = true
  }

  function onWizardVerified({ refreshToken } = {}) {
    if (refreshToken) saveShopRefreshToken(refreshToken)
    phoneVerified = true
    otpNotice = "Телефон подтверждён"
    savedProfile = true
    editContact = false
  }

  function onWizardError(message) {
    err = message
  }

  function onSelectCard(card) {
    selectionMode = "saved_card"
    selectedCardId = card.id
    payFsmState = PAY_FSM.DEFAULT
    sheetInlineError = null
    persistPaymentSelection({ selectedCardId: card.id, selectionMode: "saved_card" })
  }

  function onSelectNewCard() {
    selectionMode = "new_card"
    selectedCardId = null
    newCardState = createNewCardFormState()
    payFsmState = PAY_FSM.DEFAULT
    sheetInlineError = null
    persistPaymentSelection({ selectedCardId: null, selectionMode: "new_card" })
  }

  /** G7 D4=C: отказ банка (CLIENT_ERROR) → сразу форма новой карты; уже на new_card — только сброс FSM. */
  $effect(() => {
    if (!shouldAutoOpenNewCardOnClientError(payFsmState)) return
    if (selectionMode === "new_card") {
      payFsmState = PAY_FSM.DEFAULT
      return
    }
    onSelectNewCard()
  })

  function onSelectSbp() {
    selectionMode = "sbp"
    selectedCardId = null
    saveSbpAccount = resolveSaveSbpAccountForSbpMode({
      userTouched: saveSbpAccountTouched,
      current: saveSbpAccount
    })
    payFsmState = PAY_FSM.DEFAULT
    sheetInlineError = null
    persistPaymentSelection({ selectedCardId: null, selectionMode: "sbp" })
  }

  function onSaveSbpAccountUserChange(checked) {
    saveSbpAccountTouched = true
    saveSbpAccount = !!checked
  }

  function onSelectSbpAccount() {
    selectionMode = "sbp_account"
    selectedCardId = null
    saveSbpAccount = false
    payFsmState = PAY_FSM.DEFAULT
    sheetInlineError = null
    persistPaymentSelection({ selectedCardId: null, selectionMode: "sbp_account" })
  }

  /** api-адаптер для shopSbpPay: body объектом (unit-контракт), наружу — JSON.stringify. */
  async function sbpApi(path, opts = {}) {
    const next = { ...opts }
    if (next.body != null && typeof next.body === "object") {
      next.body = JSON.stringify(next.body)
    }
    try {
      return await apiWithPayTimeout(api, path, next)
    } catch (e) {
      e.status = e.httpStatus
      const prev = e.body && typeof e.body === "object" ? e.body : {}
      e.body = {
        error: prev.error || e.message,
        error_code: prev.error_code || e.error_code
      }
      throw e
    }
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
    clearTokenInvalid(selectedCardId)
    refreshInvalidRebillFlag()
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
    sheetInlineError = null
    submitting = true
    payFsmState = PAY_FSM.CONNECTING
    const formSnapshot = { ...newCardState }
    const wantedSave = selectionMode === "new_card" ? !!newCardState.save_card : false

    try {
      saveGuestProfile({ name, email, emailVerified: true })

      if (selectionMode === "sbp" || selectionMode === "sbp_account") {
        const orderRes = await withMinLoaderMs(MIN_LOADER_MS, async () => {
          payFsmState = PAY_FSM.CONNECTING
          const payload = await apiWithPayTimeout(api, "/orders", {
            method: "POST",
            body: JSON.stringify({
              name,
              email: email.trim().toLowerCase(),
              payment_method: "sbp"
            })
          })
          payFsmState = PAY_FSM.PROCESSING
          return payload
        })
        saveGuestOrderSession(orderRes.order_id, orderRes.reconnect_token)

        if (selectionMode === "sbp_account") {
          try {
            const charged = await chargeSbpAutopay(sbpApi, { orderId: orderRes.order_id })
            await completePaySuccess(charged.order_id || orderRes.order_id, { wantedSave: false })
            return
          } catch (chargeErr) {
            if (chargeErr?.error_code === "CHARGE_DECLINED" || /CHARGE_DECLINED/i.test(chargeErr?.body?.error_code || "")) {
              sheetInlineError = SBP_AUTOPAY_TOASTS.CHARGE_DECLINED
              selectionMode = "sbp"
              saveSbpAccount = false
              const paymentUrl = await initSbpPayment(sbpApi, {
                orderId: orderRes.order_id,
                saveSbpAccount: false
              })
              savePendingOrder(orderRes.order_id)
              redirectToSbp(paymentUrl)
              return
            }
            payFsmState = fsmFromPaymentError(chargeErr, { httpStatus: chargeErr.httpStatus })
            // Не сырой chargeErr.message («Failed to fetch»).
            sheetInlineError = resolveCheckoutSheetInlineError(chargeErr, payFsmState)
            if (sheetInlineError == null && payFsmState !== PAY_FSM.NET_ERROR) {
              sheetInlineError = SBP_AUTOPAY_TOASTS.CONNECTION_ERROR
            }
            return
          }
        }

        try {
          const paymentUrl = await initSbpPayment(sbpApi, {
            orderId: orderRes.order_id,
            saveSbpAccount: !!saveSbpAccount
          })
          savePendingOrder(orderRes.order_id)
          redirectToSbp(paymentUrl)
        } catch (initErr) {
          sheetInlineError = SBP_AUTOPAY_TOASTS.SERVICE_UNAVAILABLE
          payFsmState = PAY_FSM.CLIENT_ERROR
          throw initErr
        }
        return
      }

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
      if (isInvalidRebillPaymentError(e)) {
        setTokenInvalid(selectedCardId)
      }
      // CTA несёт copy (NET/CLIENT/BANK); сырой e.message («Failed to fetch») в шторку не кладём.
      if (mapPaymentErrorSurface({ httpStatus: e.httpStatus, phase: "pay" }) === "inline") {
        sheetInlineError = resolveCheckoutSheetInlineError(e, payFsmState)
      }
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

  {#if savedProfile && !editContact && identityReady}
    <div class="mb-4 rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-4">
      <p class="mb-1 text-sm text-[#a0a0a0]">Контакты</p>
      <p class="font-medium text-white">{name}</p>
      {#if isValidEmail(email)}
        <p class="text-sm text-[#a0a0a0]">{maskEmail(email)}</p>
      {/if}
      {#if phoneE164}
        <p class="text-sm text-[#a0a0a0]">{phoneDisplay}</p>
      {/if}
      <button
        type="button"
        class="mt-2 text-sm text-[#ff8c42]"
        onclick={() => {
          editContact = true
          phoneVerified = false
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
    {#if otpNotice}
      <p class="mb-3 text-sm text-green-400" role="status">{otpNotice}</p>
    {/if}
    {#if offerSaveToProfile && identityReady}
      <button
        type="button"
        class="mb-4 w-full rounded-lg bg-[#3a3a3a] py-2 text-sm text-white disabled:opacity-50"
        disabled={savingToProfile}
        onclick={saveContactToProfile}
        data-testid="checkout-save-to-profile"
      >
        {savingToProfile ? "Сохраняем…" : "Сохранить в профиль"}
      </button>
    {/if}

    <PhoneAuthWizard
      onPhoneChange={onWizardPhoneChange}
      onVerified={onWizardVerified}
      onError={onWizardError}
    />
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
    {sbpAccounts}
    loading={cardsLoading}
    loadError={cardsLoadError}
    inlineError={sheetInlineError}
    {selectedCardId}
    {selectionMode}
    bind:saveSbpAccount
    canPay={sheetCanPay}
    fsmState={payFsmState}
    bind:newCardState
    onClose={() => {
      if (isPayFsmClickable(payFsmState)) closePaymentSheet()
    }}
    {onSelectCard}
    {onSelectNewCard}
    onChangeCard={onSelectNewCard}
    {onSelectSbp}
    {onSelectSbpAccount}
    {onSaveSbpAccountUserChange}
    onPay={onSheetPay}
    onRetry={onSheetPayRetry}
    onRetryLoad={retryLoadSavedCards}
  />

  <ThreeDsOverlay open={showThreeDsOverlay} onClose={onThreeDsClose} />
</div>
