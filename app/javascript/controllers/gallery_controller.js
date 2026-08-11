import { Controller } from "@hotwired/stimulus"

// Lightbox simples: troca o src de uma unica <img> dentro do <dialog> em vez
// de montar um carrossel -- a pagina ja renderiza as miniaturas, o dialog so
// precisa mostrar a foto clicada em tamanho maior, com next/prev pra passear
// pelas outras sem fechar.
export default class extends Controller {
  static targets = ["dialog", "image"]
  static values = { urls: Array, alts: Array }

  open(event) {
    this.index = parseInt(event.params.index, 10)
    this.render()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  next() {
    this.index = (this.index + 1) % this.urlsValue.length
    this.render()
  }

  previous() {
    this.index = (this.index - 1 + this.urlsValue.length) % this.urlsValue.length
    this.render()
  }

  render() {
    this.imageTarget.src = this.urlsValue[this.index]
    this.imageTarget.alt = this.altsValue[this.index]
  }
}
