<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { clearGuestOrderSession, reconnectGuestOrder } from "../lib/shopGuestSession.js"
  import { clearPaymentSession } from "../lib/tbankPayment.js"

  let status = $state("fail")
  let orderId = $state("")
  let bound = $state(false)

  let message = $state("")
  let successTitle = $state("")
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
    bound = params.get("bound") === "1"

    if (!orderId) {
      err = "Не найден заказ"
      loading = false
      return
    }

    try {
      await reconnectGuestOrder(api)
      clearPaymentSession()

      if (status === "success") {
        if (bound) {
          successTitle = "Карта привязана / Оплачено"
        }
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
    {#if successTitle}
      <p class="mb-2 text-lg font-semibold text-white">{successTitle}</p>
    {/if}
    <p class="text-[#a0a0a0]">Проверяем оплату…</p>
  </div>
{:else if err}
  <p class="mb-4 text-red-400">{err}</p>
  <button type="button" class="text-[#ff8c42]" onclick={() => push("/orders")}>История заказов</button>
{:else}
  <p class="mb-4 text-[#a0a0a0]">{message}</p>
  <div class="flex flex-col gap-3">
    <button type="button" class="rounded-xl bg-[#ff8c42] py-3 font-semibold text-black" onclick={() => push("/orders")}>
      История заказов
    </button>
    <button type="button" class="rounded-xl bg-[#ff8c42]/90 py-3 font-semibold text-black" onclick={() => push("/cart")}>
      В корзину
    </button>
    <button type="button" class="rounded-xl border border-[#3a3a3a] py-3 text-[#a0a0a0]" onclick={() => push("/checkout")}>
      Оформление
    </button>
  </div>
{/if}
