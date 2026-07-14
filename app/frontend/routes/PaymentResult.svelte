<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { clearGuestOrderSession, reconnectGuestOrder } from "../lib/shopGuestSession.js"
  import { clearPaymentSession } from "../lib/tbankPayment.js"

  let status = $state("fail")
  let orderId = $state("")
  let message = $state("")
  let err = $state(null)
  let loading = $state(true)

  async function pollAccepted(maxAttempts = 20) {
    for (let i = 0; i < maxAttempts; i += 1) {
      const res = await api(`/orders/${orderId}/finalize`, { method: "POST" })
      if (res.payment_settled) return res
      await new Promise((r) => setTimeout(r, 1500))
    }
    throw new Error("Оплата ещё обрабатывается. Проверьте историю заказов через минуту.")
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

    try {
      await reconnectGuestOrder(api)
      clearPaymentSession()

      if (status === "success") {
        await pollAccepted()
        clearGuestOrderSession()
        push(`/order/${orderId}`)
        return
      } else if (status === "cancel") {
        message = "Оплата отменена. Корзина сохранена — можно попробовать снова."
      } else {
        await api(`/orders/${orderId}/abandon`, { method: "POST" })
        message = "Оплата не завершена. Корзина сохранена — можно попробовать снова."
      }
    } catch (e) {
      err = e.message
    } finally {
      loading = false
    }
  })
</script>

{#if loading}
  <div class="py-8 text-center">
    <p class="text-[#a0a0a0]">Проверяем оплату…</p>
  </div>
{:else if err}
  <p class="mb-4 text-red-400">{err}</p>
  <button type="button" class="text-[#ff8c42]" onclick={() => push("/orders")}>История заказов</button>
{:else}
  <div class="py-8 text-center">
    <p class="mb-4 text-[#a0a0a0]">{message}</p>
    <button type="button" class="text-[#ff8c42]" onclick={() => push("/")}>В каталог</button>
  </div>
{/if}
