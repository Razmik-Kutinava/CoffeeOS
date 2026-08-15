<script>
  import Router from "svelte-spa-router"
  import { wrap } from "svelte-spa-router/wrap"
  import { push } from "svelte-spa-router"
  import { onMount } from "svelte"
  import Header from "./components/Header.svelte"
  import CartSheet from "./components/CartSheet.svelte"
  import RouteLoading from "./components/RouteLoading.svelte"
  import SlowRequestOverlay from "./components/SlowRequestOverlay.svelte"
  import ShopPwaBanner from "./components/ShopPwaBanner.svelte"
  import ShopClosedBanner from "./components/ShopClosedBanner.svelte"
  import { flushOrderQueue } from "./lib/shopOfflineQueue.js"
  import { flushCartQueue } from "./lib/shopOfflineCart.js"
  import Catalog from "./routes/Catalog.svelte"
  import CartRedirect from "./routes/CartRedirect.svelte"
  import { initTelegram } from "./lib/telegram.js"
  import { installShopWebViewCompat } from "./lib/shopWebView.js"
  import { installShopWebViewLayout } from "./lib/shopWebViewLayout.js"
  import { installSlowRequestTracker } from "./lib/slowRequest.js"
  import { api } from "./lib/api.js"
  import { bootstrapShopTenant } from "./lib/shopTenantHeader.js"
  import { restoreGuestSession } from "./lib/restoreGuestSession.js"
  import { loadOperatingHours } from "./lib/shopOperatingHours.js"
  import {
    lastGuestOrderId,
    reconnectGuestOrder,
    returningFromPaymentPage
  } from "./lib/shopGuestSession.js"
  import {
    loadPendingOrder,
    createVisibilityStatusGuard
  } from "./lib/codeblackPendingOrder.js"
  import { checkOrderStatus } from "./lib/shopSbpPay.js"

  installSlowRequestTracker()
  initTelegram()
  installShopWebViewCompat()
  installShopWebViewLayout()

  const pendingStatusGuard = createVisibilityStatusGuard()

  function lazyRoute(importer) {
    return wrap({
      asyncComponent: importer,
      loadingComponent: RouteLoading
    })
  }

  const routes = {
    "/": Catalog,
    "/product/:id": lazyRoute(() => import("./routes/Product.svelte")),
    "/cart": CartRedirect,
    "/checkout": lazyRoute(() => import("./routes/Checkout.svelte")),
    "/payment-result": lazyRoute(() => import("./routes/PaymentResult.svelte")),
    "/profile": lazyRoute(() => import("./routes/Profile.svelte")),
    "/orders": lazyRoute(() => import("./routes/Orders.svelte")),
    "/order/:id": lazyRoute(() => import("./routes/OrderStatus.svelte")),
    "/reviews": lazyRoute(() => import("./routes/Reviews.svelte")),
    "/deposits": lazyRoute(() => import("./routes/Deposits.svelte")),
    "/bonuses": lazyRoute(() => import("./routes/Bonuses.svelte")),
    "/top-up": lazyRoute(() => import("./routes/TopUp.svelte")),
    "/certificate": lazyRoute(() => import("./routes/Certificate.svelte")),
    "/category/:id": lazyRoute(() => import("./routes/CategoryProducts.svelte"))
  }

  async function recoverAfterPaymentReturn() {
    const orderId = lastGuestOrderId()
    if (!orderId) return

    const hash = window.location.hash || ""
    if (hash.includes("payment-result")) return

    const onCheckout = hash.includes("checkout")
    if (onCheckout) return

    if (!returningFromPaymentPage()) return

    await reconnectGuestOrder(api)
    push(`/payment-result?status=fail&order_id=${orderId}`)
  }

  async function recoverCodeblackPendingOrder() {
    const pending = loadPendingOrder()
    if (!pending?.orderId) return

    const hash = window.location.hash || ""
    if (hash.includes("payment-result")) return

    return pendingStatusGuard.run(async () => {
      try {
        await reconnectGuestOrder(api)
        const st = await checkOrderStatus(api, { orderId: pending.orderId })
        if (st === "CONFIRMED") {
          push(`/payment-result?status=ok&order_id=${pending.orderId}`)
          return
        }
        if (st === "REJECTED" || st === "CANCELED") {
          push(`/payment-result?status=fail&order_id=${pending.orderId}`)
          return
        }
        push(`/payment-result?status=waiting&order_id=${pending.orderId}`)
      } catch {
        push(`/payment-result?status=waiting&order_id=${pending.orderId}`)
      }
    })
  }

  function onVisibilityChange() {
    if (document.visibilityState !== "visible") return
    recoverCodeblackPendingOrder()
  }

  onMount(() => {
    // Сначала Silent Refresh: иначе /config без customer_id → нет last_ordered →
    // залипший Fly Overnight без «повторить»/рекомендаций.
    restoreGuestSession()
      .catch(() => ({ verified: false }))
      .then(() => bootstrapShopTenant(api))
      .then((cfg) => {
        if (!cfg?.operating_hours) loadOperatingHours(api).catch(() => {})
      })
      .catch(() => {
        loadOperatingHours(api).catch(() => {})
      })
    flushCartQueue(api).catch(() => {})
    flushOrderQueue(api).catch(() => {})

    const onPageShow = (event) => {
      if (event.persisted || returningFromPaymentPage()) {
        recoverAfterPaymentReturn()
      }
    }
    const onOfflineSent = (event) => {
      const orderId = event.detail?.order_id
      if (orderId) push(`/order/${orderId}`)
    }
    window.addEventListener("pageshow", onPageShow)
    window.addEventListener("shop:offline-order-sent", onOfflineSent)
    document.addEventListener("visibilitychange", onVisibilityChange)
    recoverAfterPaymentReturn()
    recoverCodeblackPendingOrder()

    return () => {
      window.removeEventListener("pageshow", onPageShow)
      window.removeEventListener("shop:offline-order-sent", onOfflineSent)
      document.removeEventListener("visibilitychange", onVisibilityChange)
    }
  })

</script>

<div class="min-h-[var(--shop-vvh)] bg-[#1a1a1a] text-white">
  <SlowRequestOverlay />
  <ShopPwaBanner />
  <ShopClosedBanner />
  <Header />
  <main class="mx-auto max-w-lg px-3 pb-4 pt-[calc(4.5rem+var(--shop-safe-top))]">
    <Router {routes} options={{ hash: true }} />
  </main>
  <CartSheet />
</div>
