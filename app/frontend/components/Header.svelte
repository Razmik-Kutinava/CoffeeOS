<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { User, ChevronDown, MessageCircle } from "lucide-svelte"
  import { getOperatingHours, subscribeOperatingHours } from "../lib/shopOperatingHours.js"
  import { formatProfileIdShort } from "../lib/shopProfileHeader.js"
  import {
    getTenantHeaderState,
    subscribeTenantHeader,
    toggleTenantDropdown,
    closeTenantDropdown,
    selectTenant
  } from "../lib/shopTenantHeader.js"
  import { api } from "../lib/api.js"
  import SupportContactSheet from "./SupportContactSheet.svelte"

  let hours = $state(getOperatingHours())
  let tenantHeader = $state(getTenantHeaderState())
  let profileId = $state(null)
  let narrow = $state(false)
  let rootEl = $state(null)
  let supportSheetRef = $state(null)

  function profileLinkLabel() {
    if (!profileId) return "Профиль"
    return `Профиль › ${formatProfileIdShort(profileId)}`
  }

  function onAddressClick() {
    if (!tenantHeader.switchable) return
    toggleTenantDropdown()
  }

  function onDocClick(event) {
    if (!tenantHeader.dropdownOpen) return
    if (rootEl && !rootEl.contains(event.target)) closeTenantDropdown()
  }

  function onSupportChatClick() {
    if (supportSheetRef) {
      supportSheetRef.open()
    }
  }

  onMount(() => {
    const unsubHours = subscribeOperatingHours((next) => {
      hours = next
    })
    const unsubTenant = subscribeTenantHeader((next) => {
      tenantHeader = next
    })

    const mq = window.matchMedia("(max-width: 359px)")
    const syncNarrow = () => {
      narrow = mq.matches
    }
    syncNarrow()
    mq.addEventListener("change", syncNarrow)
    document.addEventListener("click", onDocClick)

    api("profile")
      .then((data) => {
        profileId = data?.id ? String(data.id) : null
      })
      .catch(() => {
        profileId = null
      })

    return () => {
      unsubHours()
      unsubTenant()
      mq.removeEventListener("change", syncNarrow)
      document.removeEventListener("click", onDocClick)
    }
  })
</script>

<header
  class="fixed left-0 right-0 top-0 z-40 border-b border-[#3a3a3a] bg-[#1a1a1a]/95 backdrop-blur"
  style:padding-top="var(--shop-safe-top)"
>
  <div class="mx-auto flex max-w-lg items-start justify-between gap-2 px-3 py-2.5">
    <div bind:this={rootEl} class="relative flex min-w-0 flex-1 flex-col items-start gap-0.5">
      {#if tenantHeader.switchable}
        <button
          type="button"
          data-testid="shop-header-tenant-address"
          class="flex w-full items-start gap-1 border-none bg-transparent p-0 text-left text-sm font-semibold leading-snug text-[#ff8c42] cursor-pointer"
          onclick={onAddressClick}
          aria-expanded={tenantHeader.dropdownOpen}
          aria-haspopup="listbox"
        >
          <span class="min-w-0 whitespace-normal break-words">{tenantHeader.displayAddress}</span>
          <ChevronDown class="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
        </button>
      {:else}
        <span
          data-testid="shop-header-tenant-address"
          class="w-full text-left text-sm font-semibold leading-snug text-[#ff8c42] whitespace-normal break-words"
        >
          {tenantHeader.displayAddress}
        </span>
      {/if}
      {#if hours.loaded && hours.schedule_display}
        <span
          class="text-[10px] leading-tight text-[#a0a0a0]"
          data-testid="shop-hours-display"
        >
          {hours.schedule_display}
        </span>
      {/if}
      {#if tenantHeader.dropdownOpen}
        <ul
          data-testid="shop-tenant-dropdown"
          class="absolute left-0 top-full z-50 mt-1 max-h-48 w-full min-w-[12rem] overflow-y-auto rounded-md border border-[#3a3a3a] bg-[#242424] py-1 shadow-lg"
          role="listbox"
        >
          {#each tenantHeader.tenants as row (row.id)}
            <li role="option" aria-selected={row.is_current}>
              <button
                type="button"
                class="w-full border-none bg-transparent px-3 py-2 text-left text-xs leading-snug text-[#e8e8e8] hover:bg-[#333] cursor-pointer whitespace-normal break-words"
                class:font-semibold={row.is_current}
                class:text-[#ff8c42]={row.is_current}
                onclick={() => selectTenant(row.id)}
              >
                {row.display_address}
              </button>
            </li>
          {/each}
        </ul>
      {/if}
    </div>
    <div class="flex shrink-0 items-center gap-2">
      <button
        type="button"
        data-testid="shop-header-support-chat"
        class="border-none bg-transparent p-0 text-[#a0a0a0] hover:text-[#ff8c42] cursor-pointer transition"
        onclick={onSupportChatClick}
        aria-label="Связь с поддержкой"
      >
        <MessageCircle class="h-5 w-5" aria-hidden="true" />
      </button>

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
  </div>
</header>

<SupportContactSheet bind:this={supportSheetRef} />
