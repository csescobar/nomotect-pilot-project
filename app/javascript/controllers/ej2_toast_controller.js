import { Controller } from "@hotwired/stimulus";
import { Toast } from "@syncfusion/ej2-notifications";

// EJ2 Toast Stimulus Controller
// Usage: data-controller="ej2-toast"
// Options:
//   data-ej2-toast-title-value    — Default toast title string
//   data-ej2-toast-content-value  — Default toast content string
//   data-ej2-toast-time-out-value — Timeout in ms (default: 4000, 0 for persistent)
export default class extends Controller {
  static values = {
    title:   { type: String, default: "" },
    content: { type: String, default: "" },
    timeOut: { type: Number, default: 4000 }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.toast) {
      this.toast.destroy();
      this.toast = null;
    }
  }

  showSuccess(event) {
    const msg = event.params?.message || "Operation completed successfully!";
    this.#showToast("Success", "Success", msg, "e-toast-success");
  }

  showError(event) {
    const msg = event.params?.message || "An error occurred during execution.";
    this.#showToast("Error", "Error", msg, "e-toast-danger");
  }

  showWarning(event) {
    const msg = event.params?.message || "Warning: Action requires review.";
    this.#showToast("Warning", "Warning", msg, "e-toast-warning");
  }

  showInfo(event) {
    const msg = event.params?.message || "System notification updated.";
    this.#showToast("Info", "Information", msg, "e-toast-info");
  }

  #init() {
    if (this.toast) return;

    const targetElement = this.element.querySelector(".ej2-toast-container") || this.element;

    this.toast = new Toast({
      position: { X: "Right", Y: "Top" },
      timeOut:  this.timeOutValue,
      showCloseButton: true,
      newestOnTop: true,
      animation: {
        show: { effect: "SlideRightIn" },
        hide: { effect: "SlideRightOut" }
      }
    });

    this.toast.appendTo(targetElement);
  }

  #showToast(title, defaultTitle, content, cssClass) {
    if (!this.toast) return;

    this.toast.show({
      title: title || defaultTitle,
      content: content,
      cssClass: cssClass
    });
  }
}
