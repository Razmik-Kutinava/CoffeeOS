<script>
  import Router from "svelte-spa-router"
  import { wrap } from "svelte-spa-router/wrap"
  import Header from "./components/Header.svelte"
  import BottomNav from "./components/BottomNav.svelte"
  import RouteLoading from "./components/RouteLoading.svelte"
  import Catalog from "./routes/Catalog.svelte"
  import { initTelegram } from "./lib/telegram.js"

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
    "/profile": lazyRoute(() => import("./routes/Profile.svelte")),
    "/favorites": lazyRoute(() => import("./routes/Favorites.svelte")),
    "/orders": lazyRoute(() => import("./routes/Orders.svelte")),
    "/reviews": lazyRoute(() => import("./routes/Reviews.svelte")),
    "/deposits": lazyRoute(() => import("./routes/Deposits.svelte")),
    "/bonuses": lazyRoute(() => import("./routes/Bonuses.svelte")),
    "/top-up": lazyRoute(() => import("./routes/TopUp.svelte")),
    "/certificate": lazyRoute(() => import("./routes/Certificate.svelte")),
    "/category/:id": lazyRoute(() => import("./routes/CategoryProducts.svelte"))
  }

</script>

<div class="min-h-screen bg-[#1a1a1a] text-white">
  <Header />
  <main class="mx-auto max-w-lg px-3 pb-28 pt-14">
    <Router {routes} options={{ hash: true }} />
  </main>
  <BottomNav />
</div>
