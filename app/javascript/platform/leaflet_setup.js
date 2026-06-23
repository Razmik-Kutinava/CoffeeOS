// B1.14: общая загрузка Leaflet/OSM для карт УК.
export async function loadLeaflet() {
  ensureLeafletStylesheet()
  const L = (await import("leaflet")).default
  fixLeafletDefaultIcons(L)
  return L
}

export function ensureLeafletStylesheet() {
  if (document.getElementById("leaflet-css")) return
  const link = document.createElement("link")
  link.id = "leaflet-css"
  link.rel = "stylesheet"
  link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
  link.integrity = "sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
  link.crossOrigin = ""
  document.head.appendChild(link)
}

export function fixLeafletDefaultIcons(L) {
  delete L.Icon.Default.prototype._getIconUrl
  L.Icon.Default.mergeOptions({
    iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
    iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
    shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png"
  })
}

export function addOsmTileLayer(L, map) {
  return L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "&copy; OpenStreetMap"
  }).addTo(map)
}
