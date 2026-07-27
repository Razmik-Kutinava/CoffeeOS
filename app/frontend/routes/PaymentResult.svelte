<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { clearGuestOrderSession, reconnectGuestOrder } from "../lib/shopGuestSession.js"
  import { clearPaymentSession } from "../lib/tbankPayment.js"
  import {
    pollSbpPaymentStatus,
    isSbpReturnSuccessStatus,
    SBP_INCOMPLETE_MESSAGE
  } from "../lib/shopSbpPay.js"

  let status = $state("fail")
  let orderId = $state("")
  let message = $state("")
  let err = $state(null)
  let loading = $state(true)

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

    try {
      await reconnectGuestOrder(api)
      clearPaymentSession()

      if (isSbpReturnSuccessStatus(status)) {
        await pollSbpPaymentStatus(api, { orderId })
        clearGuestOrderSession()
        push(`/order/${orderId}`)
        return
      }

      if (status === "cancel") {
        message = SBP_INCOMPLETE_MESSAGE
      } else {
        try {
          await api(`/orders/${orderId}/abandon`, { method: "POST" })
        } catch {
          /* abandon best-effort */
        }
        message = SBP_INCOMPLETE_MESSAGE
      }
    } catch (e) {
      // timeout / terminal / network — без бесконечного Loading
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
{:else if err}
  <p class="mb-4 text-red-400" role="alert">{err}</p>
  <button type="button" class="text-[#ff8c42]" onclick={() => push("/orders")}>История заказов</button>
{:else}
  <div class="py-8 text-center" data-testid="payment-result-incomplete">
    <p class="mb-4 text-[#a0a0a0]">{message}</p>
    <button type="button" class="text-[#ff8c42]" onclick={() => push("/")}>В каталог</button>
  </div>
{/if}
