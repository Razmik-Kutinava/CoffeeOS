import { Controller } from "@hotwired/stimulus"

// B1.14: карта точки в УК (Leaflet + OSM). Клик → lat/lng в поля формы.
export default class extends Controller {
  static targets = ["panel", "map", "latitude", "longitude"]
  static values = {
    lat: { type: Number, default: 55.7558 },
    lng: { type: Number, default: 37.6173 }
  }

  connect() {
    this.leaflet = null
    this.map = null
    this.marker = null
    this.ensureStylesheet()
  }

  disconnect() {
    this.destroyMap()
  }

  toggle(event) {
    event.preventDefault()
    const hidden = this.panelTarget.hidden
    this.panelTarget.hidden = !hidden
    if (!hidden) {
      this.destroyMap()
      return
    }
    this.openMap()
  }

  async openMap() {
    if (!this.leaflet) {
      this.leaflet = (await import("leaflet")).default
      this.fixDefaultIcons(this.leaflet)
    }
    if (this.map) return

    const lat = this.readCoord(this.latitudeTarget.value, this.latValue)
    const lng = this.readCoord(this.longitudeTarget.value, this.lngValue)

    this.map = this.leaflet.map(this.mapTarget).setView([lat, lng], 14)
    this.leaflet
      .tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: "&copy; OpenStreetMap"
      })
      .addTo(this.map)

    if (this.hasCoordinates()) this.placeMarker(lat, lng)

    this.map.on("click", (e) => {
      const { lat: clickLat, lng: clickLng } = e.latlng
      this.latitudeTarget.value = clickLat.toFixed(7)
      this.longitudeTarget.value = clickLng.toFixed(7)
      this.placeMarker(clickLat, clickLng)
    })

    window.requestAnimationFrame(() => this.map?.invalidateSize())
  }

  coordsInput() {
    if (!this.map || !this.leaflet) return
    const lat = this.readCoord(this.latitudeTarget.value, this.latValue)
    const lng = this.readCoord(this.longitudeTarget.value, this.lngValue)
    if (this.hasCoordinates()) {
      this.placeMarker(lat, lng)
      this.map.setView([lat, lng], this.map.getZoom())
    }
  }

  hasCoordinates() {
    return this.latitudeTarget.value !== "" && this.longitudeTarget.value !== ""
  }

  readCoord(raw, fallback) {
    const n = parseFloat(raw)
    return Number.isFinite(n) ? n : fallback
  }

  placeMarker(lat, lng) {
    if (this.marker) {
      this.marker.setLatLng([lat, lng])
    } else {
      this.marker = this.leaflet.marker([lat, lng]).addTo(this.map)
    }
  }

  destroyMap() {
    if (this.map) {
      this.map.remove()
      this.map = null
      this.marker = null
    }
  }

  ensureStylesheet() {
    if (document.getElementById("leaflet-css")) return
    const link = document.createElement("link")
    link.id = "leaflet-css"
    link.rel = "stylesheet"
    link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
    link.integrity = "sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
    link.crossOrigin = ""
    document.head.appendChild(link)
  }

  fixDefaultIcons(L) {
    delete L.Icon.Default.prototype._getIconUrl
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
      iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
      shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png"
    })
  }
}
