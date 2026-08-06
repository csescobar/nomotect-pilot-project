import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "toggle", "backdrop"]

  connect() {
    this.element.classList.add("application-shell--enhanced")
    this.mediaQuery = window.matchMedia("(max-width: 48rem)")
    this.boundEscape = this.handleEscape.bind(this)
    this.boundMediaChange = this.handleMediaChange.bind(this)
    document.addEventListener("keydown", this.boundEscape)
    this.mediaQuery.addEventListener("change", this.boundMediaChange)
    this.handleMediaChange(this.mediaQuery)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundEscape)
    this.mediaQuery.removeEventListener("change", this.boundMediaChange)
    document.body.classList.remove("navigation-drawer-open")
  }

  toggle() {
    this.drawerTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.drawerTarget.hidden = false
    this.backdropTarget.hidden = false
    document.body.classList.add("navigation-drawer-open")
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close(returnFocus = true) {
    this.drawerTarget.hidden = true
    this.backdropTarget.hidden = true
    document.body.classList.remove("navigation-drawer-open")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    if (returnFocus) this.toggleTarget.focus()
  }

  handleEscape(event) {
    if (event.key === "Escape" && !this.drawerTarget.hidden) this.close()
  }

  handleMediaChange(event) {
    if (event.matches) {
      this.close(false)
    } else {
      this.drawerTarget.hidden = false
      this.backdropTarget.hidden = true
      document.body.classList.remove("navigation-drawer-open")
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }
}
