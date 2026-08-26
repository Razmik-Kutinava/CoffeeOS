<script>
  import { loadPlgBlockConfigs, plgBlockHasContent } from "../lib/shopPlgBlocks.js"

  let { blocks = loadPlgBlockConfigs() } = $props()
</script>

<section class="plg-section" data-testid="shop-lk-plg-section" aria-label="Маркетинговые блоки">
  {#each blocks as block (block.id)}
    <div class="plg-slot" data-testid="shop-lk-plg-slot">
      {#if plgBlockHasContent(block)}
        {#if block.imageUrl}
          <img src={block.imageUrl} alt="" class="plg-image" loading="lazy" />
        {/if}
        {#if block.ctaLabel && block.href}
          <a href={block.href} class="plg-cta">{block.ctaLabel}</a>
        {/if}
      {:else}
        <div class="plg-placeholder" aria-hidden="true"></div>
      {/if}
    </div>
  {/each}
</section>

<style>
  .plg-section {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    padding: 0 16px 16px;
  }

  .plg-slot {
    min-height: 72px;
    border-radius: 12px;
    overflow: hidden;
    background: #2a2a2a;
  }

  .plg-placeholder {
    width: 100%;
    height: 72px;
    background: linear-gradient(135deg, #333 0%, #2a2a2a 100%);
    border: 1px dashed #444;
    border-radius: 12px;
  }

  .plg-image {
    width: 100%;
    height: 72px;
    object-fit: cover;
    display: block;
  }

  .plg-cta {
    display: block;
    padding: 8px;
    color: #ff8c42;
    font-size: 13px;
    text-decoration: none;
  }
</style>
