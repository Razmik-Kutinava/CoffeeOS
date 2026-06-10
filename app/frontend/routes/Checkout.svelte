<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    loadGuestProfile,
    saveGuestProfile,
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

  let name = $state("")
  let email = $state("")
  let otpCode = $state("")
  let promo_code = $state("")
  let payment_method = $state("card")
  let sbpNotice = $state(false)
  let emailVerified = $state(false)
  let sendingCode = $state(false)
  let verifyingCode = $state(false)
  let otpNotice = $state("")
  let submitting = $state(false)
  let err = $state(null)
  let savedProfile = $state(false)
  let editContact = $state(true)

  const canSendCode = $derived(isValidEmail(email) && !sendingCode)
  const canPay = $derived(
    !!name?.trim() && isValidEmail(email) && emailVerified && !submitting
  )

  onMount(() => {
    const profile = loadGuestProfile()
    if (profile) {
      name = profile.name
      email = profile.email
      emailVerified = profile.emailVerified
      savedProfile = true
      editContact = false
    }

    const syncServerStatus = async () => {
      if (!isValidEmail(email)) return
      try {
        const status = await api("/email_otp/status")
        if (status.verified && status.email === email.trim().toLowerCase()) {
          emailVerified = true
        }
      } catch {
        /* session may be empty */
      }
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
    const onPageShow = (event) => {
      if (event.persisted) recover()
    }
    window.addEventListener("pageshow", onPageShow)
    return () => window.removeEventListener("pageshow", onPageShow)
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
    } catch (e) {
      emailVerified = false
      err = e.message
    } finally {
      verifyingCode = false
    }
  }

  async function submit() {
    if (!canPay) return
    err = null
    submitting = true
    let redirecting = false
    try {
      saveGuestProfile({ name, email, emailVerified: true })

      const res = await api("/orders", {
        method: "POST",
        body: JSON.stringify({
          name,
          email: email.trim().toLowerCase(),
          promo_code: promo_code || undefined,
          payment_method
        })
      })

      saveGuestOrderSession(res.order_id, res.reconnect_token)

      if (res.payment_url || res.provider_payment_id) {

        if (res.payment_iframe && (res.provider_payment_id || res.payment_url)) {
          let config = {}
          try {
            config = await api("/config")
          } catch {
            config = {}
          }
          savePaymentSession({
            order_id: res.order_id,
            total: res.total,
            provider_payment_id: res.provider_payment_id,
            terminal_key: res.terminal_key || config.terminal_key,
            payment_url: res.payment_url,
            reconnect_token: res.reconnect_token,
            payment_iframe: true,
            payment_method,
            integration_script_url: config.integration_script_url
          })
          redirecting = true
          push("/payment")
          return
        }

        redirecting = true
        window.location.href = res.payment_url
        return
      }

      redirecting = true
      push(`/order/${res.order_id}`)
    } catch (e) {
      err = e.message
    } finally {
      if (!redirecting) submitting = false
    }
  }
</script>

<div>
  <div class="mb-4 flex items-center gap-3">
    <button type="button" class="text-2xl text-[#ff8c42]" onclick={() => push("/cart")} aria-label="Назад в корзину">
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

  <label class="mb-6 block">
    <span class="mb-1 block text-sm text-[#a0a0a0]">Промокод (необязательно)</span>
    <input bind:value={promo_code} class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2" />
  </label>

  <div class="mb-6">
    <span class="mb-2 block text-sm text-[#a0a0a0]">Способ оплаты</span>
    <div class="flex gap-3">
      {#each [["card", "Картой"], ["cash", "Наличные"]] as [val, label]}
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

  {#if err}
    <p class="mb-4 text-sm text-red-400">{err}</p>
  {/if}

  <button
    type="button"
    class="w-full rounded-xl bg-[#ff8c42] py-4 text-lg font-semibold text-black disabled:opacity-50"
    disabled={!canPay}
    onclick={submit}
  >
    {submitting
      ? payment_method === "cash"
        ? "Оформляем…"
        : "Идёт оплата…"
      : payment_method === "cash"
        ? "Оформить (наличные)"
        : "Оплатить →"}
  </button>
</div>
