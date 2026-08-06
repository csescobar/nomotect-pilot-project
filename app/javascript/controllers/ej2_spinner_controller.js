import { Controller } from "@hotwired/stimulus";
import { createSpinner, showSpinner, hideSpinner } from "@syncfusion/ej2-popups";

// EJ2 Spinner Stimulus Controller
// Usage: data-controller="ej2-spinner"
// Options:
//   data-ej2-spinner-label-value — Optional label text string for loading overlay
export default class extends Controller {
  static values = {
    label: { type: String, default: "Loading..." }
  };

  connect() {
    this.#init();
  }

  toggle() {
    if (!this.targetContainer) return;

    if (this.isLoading) {
      hideSpinner(this.targetContainer);
      this.isLoading = false;
    } else {
      showSpinner(this.targetContainer);
      this.isLoading = true;
    }
  }

  show() {
    if (this.targetContainer) {
      showSpinner(this.targetContainer);
      this.isLoading = true;
    }
  }

  hide() {
    if (this.targetContainer) {
      hideSpinner(this.targetContainer);
      this.isLoading = false;
    }
  }

  #init() {
    this.targetContainer = this.element.querySelector(".ej2-spinner-target") || this.element;
    createSpinner({
      target: this.targetContainer,
      label:  this.labelValue
    });
    this.isLoading = false;
  }
}
