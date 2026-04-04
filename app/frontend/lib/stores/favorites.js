import { writable } from 'svelte/store';
import { api } from '../api.js';

function createFavorites() {
  const { subscribe, set, update } = writable([]);
  let ids = new Set();
  let loadInflight = null;

  return {
    subscribe,
    load: async () => {
      if (loadInflight) return loadInflight;
      loadInflight = (async () => {
        try {
          const data = await api("favorites");
          ids = new Set(data.map((p) => p.id));
          set(data);
        } catch {
          set([]);
        } finally {
          loadInflight = null;
        }
      })();
      return loadInflight;
    },
    isFavorite: (productId) => ids.has(productId),
    toggle: async (productId) => {
      if (ids.has(productId)) {
        await api(`favorites/${productId}`, { method: 'DELETE' });
        ids.delete(productId);
        update(items => items.filter(p => p.id !== productId));
      } else {
        await api('favorites', { method: 'POST', body: JSON.stringify({ product_id: productId }) });
        ids.add(productId);
        // reload to get full product data
        const data = await api('favorites');
        ids = new Set(data.map(p => p.id));
        set(data);
      }
    }
  };
}

export const favorites = createFavorites();
