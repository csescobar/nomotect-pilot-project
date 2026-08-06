import { Controller } from "@hotwired/stimulus";
import { Button } from "@syncfusion/ej2-buttons";

// EJ2 Button Stimulus Controller
// Usage: data-controller="ej2-button"
// Options:
//   data-ej2-button-is-primary-value     — Boolean indicating primary button variant
//   data-ej2-button-disabled-value       — Boolean indicating disabled state
//   data-ej2-button-icon-css-value       — String icon CSS class
export default class extends Controller {
  static values = {
    isPrimary: { type: Boolean, default: false },
    disabled:  { type: Boolean, default: false },
    iconCss:   { type: String,  default: "" }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.button) {
      this.button.destroy();
      this.button = null;
    }
  }

  toggleLoading(event) {
    const btn = event.currentTarget;
    if (btn.classList.contains("is-loading")) {
      btn.classList.remove("is-loading");
      btn.removeAttribute("disabled");
    } else {
      btn.classList.add("is-loading");
      btn.setAttribute("disabled", "true");
      setTimeout(() => {
        btn.classList.remove("is-loading");
        btn.removeAttribute("disabled");
      }, 3000);
    }
  }

  #init() {
    if (this.button) return;

    const targetElement = this.element.querySelector("button") || this.element;

    this.button = new Button({
      isPrimary: this.isPrimaryValue,
      disabled:  this.disabledValue,
      iconCss:   this.iconCssValue
    });

    this.button.appendTo(targetElement);
  }
}
