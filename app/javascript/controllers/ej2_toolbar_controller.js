import { Controller } from "@hotwired/stimulus";
import { Toolbar } from "@syncfusion/ej2-navigations";

// EJ2 Toolbar Stimulus Controller
// Usage: data-controller="ej2-toolbar"
// Options:
//   data-ej2-toolbar-overflow-mode-value — Overflow mode: "Popup" | "Scrollable" | "Extended" (default: "Popup")
export default class extends Controller {
  static values = {
    overflowMode: { type: String, default: "Popup" }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.toolbar) {
      this.toolbar.destroy();
      this.toolbar = null;
    }
  }

  #init() {
    if (this.toolbar) return;

    // Find inner container or use element itself
    const targetElement = this.element.querySelector(".ej2-toolbar-element") || this.element;

    this.toolbar = new Toolbar({
      overflowMode: this.overflowModeValue
    });

    this.toolbar.appendTo(targetElement);
  }
}
