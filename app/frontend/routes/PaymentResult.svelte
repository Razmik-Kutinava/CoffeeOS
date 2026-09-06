<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { clearGuestOrderSession, reconnectGuestOrder, guestReconnectToken } from "../lib/shopGuestSession.js"
  import { loadGuestProfile, loadReceiptEmail, saveReceiptEmail } from "../lib/shopGuestProfile.js"
  import { clearPaymentSession } from "../lib/tbankPayment.js"
  import { clearPendingOrder } from "../lib/codeblackPendingOrder.js"
  import {
    pollSbpPaymentStatus,
    isSbpReturnSuccessStatus,
    checkOrderStatus,
    SBP_INCOMPLETE_MESSAGE,
    SBP_WAITING_FOR_BANK_MESSAGE,
    SBP_I_PAID_LABEL
  } from "../lib/shopSbpPay.js"
  import OrderSuccessEmailBlock from "../components/OrderSuccessEmailBlock.svelte"
  import { submitOrderEmail, shouldAskReceiptEmail } from "../lib/emailCollection.js"

  let status = $state("fail")
  let orderId = $state("")
  let message = $state("")
  let err = $state(null)
  let loading = $state(true)
  let waitingForBank = $state(false)
  let checkingPaid = $state(false)
  let emailSubmitting = $state(false)
  let prefillEmail = $state("")
  let askReceiptEmail = $state(true)
  let reconnectToken = $state("")

  /** После успешной оплаты: финализировать сессию, но остаться на экране с email-блоком. */
  async function prepareSuccessScreen() {
    try {
      await pollSbpPaymentStatus(api, { orderId })
    } catch (e) {
      if (e?.kind === "sbp_timeout" || e?.kind === "sbp_terminal") {
        message = e.message || SBP_INCOMPLETE_MESSAGE
        err = null
        status = "fail"
        return false
      }
      throw e
    }
    clearPendingOrder()
    clearGuestOrderSession()
    waitingForBank = false
    status = "ok"
    return true
  }

  async function onIPaid() {
    if (!orderId || checkingPaid) return
    checkingPaid = true
    err = null
    try {
      const st = await checkOrderStatus(api, { orderId })
      if (st === "CONFIRMED") {
        const ok = await prepareSuccessScreen()
        if (!ok) return
        return
      }
      if (st === "REJECTED" || st === "CANCELED") {
        waitingForBank = false
        message = SBP_INCOMPLETE_MESSAGE
        return
      }
      // PENDING — остаёмся на WAITING_FOR_BANK
    } catch (e) {
      err = e.message || SBP_INCOMPLETE_MESSAGE
    } finally {
      checkingPaid = false
    }
  }

  async function handleEmailSubmit({ email, marketing_consent }) {
    emailSubmitting = true
    try {
      await submitOrderEmail(api, {
        orderId,
        email,
        marketing_consent,
        reconnect_token: reconnectToken || undefined
      })
      saveReceiptEmail(email)
      askReceiptEmail = false
      err = null
      await new Promise((r) => setTimeout(r, 800))
      push("/")
    } catch (e) {
      err = e.message || "Не удалось сохранить email"
    } finally {
      emailSubmitting = false
    }
  }

  async function handleEmailSkip() {
    await new Promise((r) => setTimeout(r, 200))
    push("/")
  }

  onMount(async () => {
    const query = window.location.hash.split("?")[1] || ""
    const params = new URLSearchParams(query)
    status = params.get("status") || "fail"
    orderId = params.get("order_id") || ""

    if (!orderId) {
      err = "Не найден заказ"
      loading = false
      return
    }

    reconnectToken = guestReconnectToken() || ""
    const savedReceipt = loadReceiptEmail()
    const profile = loadGuestProfile()
    // Prefill may use profile email; hide block only after receipt LS was saved (#71 QA).
    prefillEmail = savedReceipt || profile?.email || ""
    askReceiptEmail = shouldAskReceiptEmail(savedReceipt)

    try {
      await reconnectGuestOrder(api)
      clearPaymentSession()

      if (status === "waiting") {
        waitingForBank = true
        loading = false
        return
      }

      // success / ok / ok_sbp — показать email-блок, не редиректить сразу
      if (status === "ok" || status === "ok_sbp" || isSbpReturnSuccessStatus(status)) {
        await prepareSuccessScreen()
        loading = false
        return
      }

      if (status === "cancel") {
        clearPendingOrder()
        message = SBP_INCOMPLETE_MESSAGE
      } else {
        try {
          await api(`/orders/${orderId}/abandon`, { method: "POST" })
        } catch {
          /* abandon best-effort */
        }
        clearPendingOrder()
        message = SBP_INCOMPLETE_MESSAGE
      }
    } catch (e) {
      if (e?.kind === "sbp_timeout" || e?.kind === "sbp_terminal") {
        message = e.message || SBP_INCOMPLETE_MESSAGE
        err = null
      } else {
        err = e.message || SBP_INCOMPLETE_MESSAGE
      }
    } finally {
      loading = false
    }
  })
</script>

{#if loading}
  <div class="py-8 text-center" data-testid="payment-result-loading">
    <p class="text-[#a0a0a0]">Проверяем оплату…</p>
  </div>
{:else if waitingForBank}
  <div class="py-8 text-center font-mono" data-testid="payment-waiting-for-bank">
    <p class="mb-6 text-[#a0a0a0]">{SBP_WAITING_FOR_BANK_MESSAGE}</p>
    {#if err}
      <p class="mb-4 text-red-400" role="alert">{err}</p>
    {/if}
    <button
      type="button"
      class="border border-[#333] px-4 py-2 text-[#e0e0e0] hover:border-[#666]"
      data-testid="payment-i-paid"
      disabled={checkingPaid}
      onclick={onIPaid}
    >
      [ {checkingPaid ? "…" : SBP_I_PAID_LABEL} ]
    </button>
  </div>
{:else if status === "ok" || status === "ok_sbp"}
  <div class="py-8" data-testid="payment-result-success">
    <div class="mb-4 text-center">
      <p class="text-lg font-medium text-green-400">✔ Чек сформирован</p>
    </div>

    {#if askReceiptEmail}
      <OrderSuccessEmailBlock
        {orderId}
        email={prefillEmail}
        marketingConsent={false}
        loading={emailSubmitting}
        onSubmit={handleEmailSubmit}
        onSkip={handleEmailSkip}
      />
    {:else}
      <div class="mt-4 text-center">
        <button
          type="button"
          class="text-[#ff8c42]"
          data-testid="payment-result-continue"
          onclick={handleEmailSkip}
        >
          В каталог
        </button>
      </div>
    {/if}

    {#if err}
      <p class="mt-4 text-sm text-red-400" role="alert">{err}</p>
    {/if}
  </div>
{:else if err}
  <p class="mb-4 text-red-400" role="alert">{err}</p>
  <button type="button" class="text-[#ff8c42]" onclick={() => push("/orders")}>История заказов</button>
{:else}
  <div class="py-8 text-center" data-testid="payment-result-incomplete">
    <p class="mb-4 text-[#a0a0a0]">{message}</p>
    <button type="button" class="text-[#ff8c42]" onclick={() => push("/")}>В каталог</button>
  </div>
{/if}
