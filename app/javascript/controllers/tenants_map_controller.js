import { Controller } from "@hotwired/stimulus"
import { addOsmTileLayer, loadLeaflet } from "platform/leaflet_setup"

// B1.14-3d: все точки продаж с координатами на списке УК.
export default class extends Controller {
  static targets = ["map", "empty"]
  static values = {
    tenants: { type: Array, default: [] },
    defaultLat: { type: Number, default: 55.7558 },
    defaultLng: { type: Number, default: 37.6173 }
  }

  connect() {
    this.map = null
    this.init()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  async init() {
    const pins = this.tenantsValue.filter((t) => Number.isFinite(t.lat) && Number.isFinite(t.lng))
    if (pins.length === 0) {
      if (this.hasEmptyTarget) this.emptyTarget.hidden = false
      if (this.hasMapTarget) this.mapTarget.hidden = true
      return
    }

    if (this.hasEmptyTarget) this.emptyTarget.hidden = true
    if (this.hasMapTarget) this.mapTarget.hidden = false

    const L = await loadLeaflet()
    const center = this.centerFor(pins)
    this.map = L.map(this.mapTarget).setView(center, pins.length === 1 ? 14 : 11)
    addOsmTileLayer(L, this.map)

    const bounds = []
    pins.forEach((pin) => {
      const latlng = [pin.lat, pin.lng]
      bounds.push(latlng)
      const popup = `<strong>${this.escape(pin.name)}</strong><br>${this.escape(pin.address)}<br><a href="${this.escape(pin.card_url)}">Карточка</a>`
      L.marker(latlng).bindPopup(popup).addTo(this.map)
    })

    if (bounds.length > 1) {
      this.map.fitBounds(bounds, { padding: [24, 24] })
    }

    window.requestAnimationFrame(() => this.map?.invalidateSize())
  }

  centerFor(pins) {
    if (pins.length === 1) return [pins[0].lat, pins[0].lng]
    const lat = pins.reduce((sum, p) => sum + p.lat, 0) / pins.length
    const lng = pins.reduce((sum, p) => sum + p.lng, 0) / pins.length
    return [lat || this.defaultLatValue, lng || this.defaultLngValue]
  }

  escape(text) {
    return String(text ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/"/g, "&quot;")
  }
}
