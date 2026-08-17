import { Controller } from "@hotwired/stimulus"

// Atualiza o resumo de preco (turbo-frame "price_summary") a cada mudanca
// nos campos de quantidade. So dispara um novo GET -- quem calcula o
// dinheiro e sempre o PriceCalculator no servidor (NOTES.md, invariante 1),
// o JS aqui nunca soma nada.
export default class extends Controller {
  static targets = [ "frame" ]
  static values = { url: String }

  update() {
    const params = new URLSearchParams(new FormData(this.element))
    this.frameTarget.src = `${this.urlValue}?${params}`
  }
}
