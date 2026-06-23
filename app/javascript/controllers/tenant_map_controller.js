import { Controller } from "@hotwired/stimulus"
import { addOsmTileLayer, loadLeaflet } from "platform/leaflet_setup"

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
      this.leaflet = await loadLeaflet()
    }
    if (this.map) return

    const lat = this.readCoord(this.latitudeTarget.value, this.latValue)
    const lng = this.readCoord(this.longitudeTarget.value, this.lngValue)

    this.map = this.leaflet.map(this.mapTarget).setView([lat, lng], 14)
    addOsmTileLayer(this.leaflet, this.map)

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
}
