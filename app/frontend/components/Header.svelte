<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { User } from "lucide-svelte"
  import { getOperatingHours, subscribeOperatingHours } from "../lib/shopOperatingHours.js"
  import { formatProfileIdShort } from "../lib/shopProfileHeader.js"
  import { api } from "../lib/api.js"

  let hours = $state(getOperatingHours())
  let profileId = $state(null)
  let narrow = $state(false)

  function profileLinkLabel() {
    if (!profileId) return "Профиль"
    return `Профиль › ${formatProfileIdShort(profileId)}`
  }

  onMount(() => {
    const unsubHours = subscribeOperatingHours((next) => {
      hours = next
    })

    const mq = window.matchMedia("(max-width: 359px)")
    const syncNarrow = () => {
      narrow = mq.matches
    }
    syncNarrow()
    mq.addEventListener("change", syncNarrow)

    api("profile")
      .then((data) => {
        profileId = data?.id ? String(data.id) : null
      })
      .catch(() => {
        profileId = null
      })

    return () => {
      unsubHours()
      mq.removeEventListener("change", syncNarrow)
    }
  })
</script>

<header
  class="fixed left-0 right-0 top-0 z-40 border-b border-[#3a3a3a] bg-[#1a1a1a]/95 backdrop-blur"
>
  <div class="mx-auto flex max-w-lg items-start justify-between gap-2 px-3 py-2.5">
    <div class="flex min-w-0 flex-1 flex-col items-start gap-0.5">
      <button
        type="button"
        class="border-none bg-transparent p-0 text-lg font-semibold text-[#ff8c42] cursor-pointer"
        onclick={() => push("/")}
      >
        CoffeeOS
      </button>
      {#if hours.loaded && hours.schedule_display}
        <span
          class="text-[10px] leading-tight text-[#a0a0a0]"
          data-testid="shop-hours-display"
        >
          {hours.schedule_display}
        </span>
      {/if}
    </div>
    <button
      type="button"
      data-testid="shop-header-profile"
      class="flex shrink-0 items-center gap-1 border-none bg-transparent p-0 pt-0.5 text-xs text-[#a0a0a0] cursor-pointer"
      onclick={() => push("/profile")}
    >
      {#if narrow}
        <span class="relative inline-flex">
          <User class="h-5 w-5" aria-hidden="true" />
          {#if profileId}
            <span
              class="absolute -right-2 -top-1.5 min-w-[1.1rem] rounded-full bg-[#ff8c42] px-0.5 text-center text-[9px] leading-tight font-medium text-[#1a1a1a]"
              data-testid="shop-header-profile-id-badge"
            >
              {formatProfileIdShort(profileId).slice(-4)}
            </span>
          {/if}
        </span>
        <span class="sr-only">{profileLinkLabel()}</span>
      {:else}
        <span data-testid="shop-header-profile-label">{profileLinkLabel()}</span>
      {/if}
    </button>
  </div>
</header>
