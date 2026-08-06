import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    this._timer = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  dismiss() {
    if (this._timer) clearTimeout(this._timer)
    this.element.style.opacity = "0"
    this.element.style.transition = "opacity 150ms ease"
    setTimeout(() => {
      this.element.remove()
    }, 150)
  }
}
