<div class="page-skeleton flex flex-col gap-3 py-4" aria-busy="true" aria-label="Загрузка">
  <div class="h-4 w-2/5 animate-pulse rounded bg-[#2a2a2a]"></div>
  <div class="flex gap-3 overflow-hidden">
    {#each [1, 2, 3] as _}
      <div class="h-40 w-40 shrink-0 animate-pulse rounded-xl bg-[#2a2a2a]"></div>
    {/each}
  </div>
  <div class="mt-2 h-4 w-1/3 animate-pulse rounded bg-[#2a2a2a]"></div>
  <div class="flex gap-3 overflow-hidden">
    {#each [1, 2, 3] as _}
      <div class="h-40 w-40 shrink-0 animate-pulse rounded-xl bg-[#2a2a2a]"></div>
    {/each}
  </div>
</div>
