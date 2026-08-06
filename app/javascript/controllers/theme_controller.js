import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "nomotect-theme"
const ALLOWED_THEMES = ["light", "dark"]

export default class extends Controller {
  static targets = ["select"]

  connect() {
    const preference = localStorage.getItem(STORAGE_KEY) || "light"
    this.apply(preference)
    if (this.hasSelectTarget) this.selectTarget.value = ALLOWED_THEMES.includes(preference) ? preference : "light"
  }

  change(event) {
    this.apply(event.target.value)
  }

  apply(preference) {
    const theme = ALLOWED_THEMES.includes(preference) ? preference : "light"
    localStorage.setItem(STORAGE_KEY, theme)
    document.documentElement.dataset.theme = theme
  }
}
