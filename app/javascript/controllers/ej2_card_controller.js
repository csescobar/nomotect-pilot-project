import { Controller } from "@hotwired/stimulus";

// EJ2 Card Stimulus Controller
// Usage: data-controller="ej2-card"
// Options:
//   data-ej2-card-expanded-value — Boolean indicating if collapsible panel is expanded (default: false)
export default class extends Controller {
  static targets = ["content", "toggleIcon", "toggleText"];
  static values = {
    expanded: { type: Boolean, default: false }
  };

  connect() {
    this.#updateState();
  }

  toggle() {
    this.expandedValue = !this.expandedValue;
  }

  expandedValueChanged() {
    this.#updateState();
  }

  #updateState() {
    if (!this.hasContentTarget) return;

    if (this.expandedValue) {
      this.contentTarget.classList.remove("is-collapsed");
      this.element.classList.add("is-expanded");
      if (this.hasToggleIconTarget) this.toggleIconTarget.textContent = "▲";
    } else {
      this.contentTarget.classList.add("is-collapsed");
      this.element.classList.remove("is-expanded");
      if (this.hasToggleIconTarget) this.toggleIconTarget.textContent = "▼";
    }
  }
}
