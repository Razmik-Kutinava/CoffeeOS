<script>
  import { openDeepLink } from "../lib/deepLink.js"
  import { SUPPORT_CHANNELS, getAvailableSupportChannels } from "../lib/supportConfig.js"
  import { Mail } from "lucide-svelte"

  let isOpen = $state(false)

  export function open() {
    isOpen = true
  }

  export function close() {
    isOpen = false
  }

  function handleChannelClick(channel) {
    if (channel.id === SUPPORT_CHANNELS.TELEGRAM.id && channel.url) {
      openDeepLink(channel.url)
      close()
    } else if (channel.id === SUPPORT_CHANNELS.EMAIL.id) {
      // Email flow not implemented yet
      close()
    }
  }

  function handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      close()
    }
  }

  function handleKeyDown(event) {
    if (isOpen && event.key === "Escape") {
      close()
    }
  }
</script>

<svelte:document on:keydown={handleKeyDown} />

{#if isOpen}
  <div
    role="presentation"
    class="fixed inset-0 z-50 bg-black/40"
    onclick={handleBackdropClick}
    data-testid="support-sheet-backdrop"
  />

  <div
    role="dialog"
    aria-modal="true"
    class="fixed bottom-0 left-0 right-0 z-50 flex flex-col rounded-t-2xl bg-[#1a1a1a] shadow-lg"
    data-testid="support-contact-sheet"
    style:max-width="100%"
    style:max-height="60vh"
  >
    <div class="flex items-center justify-between border-b border-[#3a3a3a] px-4 py-4">
      <h2 class="text-lg font-semibold text-[#e8e8e8]">Связь с поддержкой</h2>
      <button
        type="button"
        aria-label="Close"
        class="border-none bg-transparent p-0 text-[#a0a0a0] hover:text-[#e8e8e8] cursor-pointer text-sm"
        onclick={() => close()}
        data-testid="support-sheet-close"
      >
        ✕
      </button>
    </div>

    <div class="flex flex-col gap-2 overflow-y-auto p-4">
      {#each getAvailableSupportChannels() as channel (channel.id)}
        <button
          type="button"
          class="flex items-center gap-3 border border-[#3a3a3a] rounded-lg px-4 py-3 text-left bg-transparent hover:bg-[#242424] cursor-pointer transition"
          onclick={() => handleChannelClick(channel)}
          data-testid={`support-channel-${channel.id}`}
          disabled={!channel.url}
        >
          {#if channel.id === "telegram"}
            <svg
              class="h-5 w-5 shrink-0 fill-current text-[#0088cc]"
              viewBox="0 0 24 24"
              aria-hidden="true"
            >
              <path
                d="M20.665 3.717l-17.73 6.837c-1.356.523-1.35 1.597-.291 2.01l4.333 1.359 10.034-6.307c.462-.276.932.038.562.411l-8.153 7.36.013 4.297c0 .921.562 1.435 1.379 1.435.403 0 .811-.163 1.188-.487l2.783-2.528 4.585 3.412c.844.623 1.819.321 2.09-.857l3.716-17.697c.33-1.435-.404-2.224-1.482-1.816z"
              />
            </svg>
          {:else if channel.id === "email"}
            <Mail class="h-5 w-5 shrink-0 text-[#a0a0a0]" aria-hidden="true" />
          {/if}

          <div class="flex-1 min-w-0">
            <div class="font-medium text-[#e8e8e8]">{channel.name}</div>
            {#if channel.id === "telegram"}
              <div class="text-xs text-[#a0a0a0]">@code_black_support_bot</div>
            {:else if channel.id === "email"}
              <div class="text-xs text-[#a0a0a0]">Email (coming soon)</div>
            {/if}
          </div>

          {#if !channel.url && channel.id === "email"}
            <span class="text-xs text-[#808080]">скоро</span>
          {/if}
        </button>
      {/each}
    </div>
  </div>
{/if}

<style>
  :global(.support-sheet-open) {
    overflow: hidden;
  }
</style>
