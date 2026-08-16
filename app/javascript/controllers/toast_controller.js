import { Controller } from "@hotwired/stimulus"

// Toast de flash: some sozinho depois de um tempo, no clique no X, ou
// arrastando pra cima no mobile. Cada toast se remove do proprio DOM --
// sem estado compartilhado entre instancias, sem precisar de um
// controller "pai" pra gerenciar a pilha.
export default class extends Controller {
  static values = { dismissAfter: Number }

  connect() {
    this.dragStartY = null
    this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    // Ja saindo (ex.: X clicado durante o swipe) -- nao duplica a animacao
    // nem o listener de remocao.
    if (this.element.classList.contains("toast-leaving")) return

    this.element.style.transform = ""
    this.element.classList.add("toast-leaving")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
  }

  // So sobe: soltar no meio do caminho volta pro lugar, sem exigir precisao
  // do usuario. Pausa o timer enquanto o dedo esta na tela -- soltar sem
  // arrastar o suficiente nao deve fazer o toast sumir de surpresa logo em seguida.
  //
  // Guarda contra "ja saindo": sem isso, tocar no toast bem no instante em
  // que o timer dispara faz o touchMove seguinte sobrescrever o transform
  // por cima da animacao de saida ja em andamento -- a animacao nunca
  // termina de verdade e o toast fica preso na tela. Nao setar dragStartY
  // aqui basta: touchMove/touchEnd ja checam esse valor antes de agir.
  touchStart(event) {
    if (this.element.classList.contains("toast-leaving")) return

    this.dragStartY = event.touches[0].clientY
    clearTimeout(this.timeout)
  }

  touchMove(event) {
    if (this.dragStartY === null) return

    const delta = Math.min(0, event.touches[0].clientY - this.dragStartY)
    this.element.style.transform = `translateY(${delta}px)`
  }

  touchEnd(event) {
    if (this.dragStartY === null) return

    const delta = event.changedTouches[0].clientY - this.dragStartY
    this.dragStartY = null

    if (delta < -40) {
      this.dismiss()
    } else {
      this.element.style.transform = ""
      this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
    }
  }
}
