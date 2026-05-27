<script>
  import { push } from "svelte-spa-router"
</script>

<header
  class="fixed left-0 right-0 top-0 z-40 border-b border-[#3a3a3a] bg-[#1a1a1a]/95 backdrop-blur"
>
  <div class="mx-auto flex max-w-lg items-center justify-between px-3 py-3">
    <button
      type="button"
      class="border-none bg-transparent p-0 text-lg font-semibold text-[#ff8c42] cursor-pointer"
      onclick={() => push("/")}
    >
      CoffeeOS
    </button>
    <div class="flex items-center gap-3">
      <a
        href="/blog"
        target="_blank"
        rel="noopener noreferrer"
        class="text-xs text-[#ff8c42] hover:underline">Блог</a>
      <span class="text-xs text-[#a0a0a0]">Витрина</span>
    </div>
  </div>
</header>
