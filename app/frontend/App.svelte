<script>
  import Router from "svelte-spa-router"
  import { wrap } from "svelte-spa-router/wrap"
  import { push } from "svelte-spa-router"
  import { onMount } from "svelte"
  import Header from "./components/Header.svelte"
  import BottomNav from "./components/BottomNav.svelte"
  import RouteLoading from "./components/RouteLoading.svelte"
  import SlowRequestOverlay from "./components/SlowRequestOverlay.svelte"
  import ShopPwaBanner from "./components/ShopPwaBanner.svelte"
  import { flushOrderQueue } from "./lib/shopOfflineQueue.js"
  import { flushCartQueue } from "./lib/shopOfflineCart.js"
  import Catalog from "./routes/Catalog.svelte"
  import { initTelegram } from "./lib/telegram.js"
  import { installSlowRequestTracker } from "./lib/slowRequest.js"
  import { api } from "./lib/api.js"
  import {
    lastGuestOrderId,
    reconnectGuestOrder,
    returningFromPaymentPage
  } from "./lib/shopGuestSession.js"

  installSlowRequestTracker()
  initTelegram()

  function lazyRoute(importer) {
    return wrap({
      asyncComponent: importer,
      loadingComponent: RouteLoading
    })
  }

  const routes = {
    "/": Catalog,
    "/product/:id": lazyRoute(() => import("./routes/Product.svelte")),
    "/cart": lazyRoute(() => import("./routes/Cart.svelte")),
    "/checkout": lazyRoute(() => import("./routes/Checkout.svelte")),
    "/payment": lazyRoute(() => import("./routes/Payment.svelte")),
    "/payment-result": lazyRoute(() => import("./routes/PaymentResult.svelte")),
    "/profile": lazyRoute(() => import("./routes/Profile.svelte")),
    "/favorites": lazyRoute(() => import("./routes/Favorites.svelte")),
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
    if (hash.includes("payment-result") || hash.includes("/payment")) return

    const onCheckout = hash.includes("checkout")
    if (!onCheckout && !returningFromPaymentPage()) return

    await reconnectGuestOrder(api)
    push(`/payment-result?status=fail&order_id=${orderId}`)
  }

  onMount(() => {
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
    recoverAfterPaymentReturn()

    return () => {
      window.removeEventListener("pageshow", onPageShow)
      window.removeEventListener("shop:offline-order-sent", onOfflineSent)
    }
  })

</script>

<div class="min-h-screen bg-[#1a1a1a] text-white">
  <SlowRequestOverlay />
  <ShopPwaBanner />
  <Header />
  <main class="mx-auto max-w-lg px-3 pb-28 pt-14">
    <Router {routes} options={{ hash: true }} />
  </main>
  <BottomNav />
</div>
