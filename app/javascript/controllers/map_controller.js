import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Mapa minimo: um pin no ponto de encontro, tiles do OpenStreetMap. Sem
// busca, sem camadas extras -- so o que o turista precisa pra achar onde
// embarcar. scrollWheelZoom desligado de proposito: um mapa embutido numa
// pagina que rola nao deve sequestrar o scroll do mouse.
export default class extends Controller {
  static values = { lat: Number, lng: Number, label: String }

  connect() {
    const map = L.map(this.element, { scrollWheelZoom: false }).setView([ this.latValue, this.lngValue ], 14)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      maxZoom: 19
    }).addTo(map)

    L.marker([ this.latValue, this.lngValue ]).addTo(map).bindPopup(this.labelValue)
  }
}
