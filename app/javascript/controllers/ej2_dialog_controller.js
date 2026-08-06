import { Controller } from "@hotwired/stimulus";
import { Dialog } from "@syncfusion/ej2-popups";

// EJ2 Dialog Stimulus Controller
// Usage: data-controller="ej2-dialog"
// Options:
//   data-ej2-dialog-header-value          — Dialog header title string
//   data-ej2-dialog-show-close-icon-value — Show top-right X close button (default: true)
//   data-ej2-dialog-is-modal-value         — Render backdrop modal (default: true)
//   data-ej2-dialog-width-value            — CSS width string (default: "460px")
//   data-ej2-dialog-visible-value          — Open initially (default: false)
export default class extends Controller {
  static values = {
    header:        { type: String,  default: "" },
    showCloseIcon: { type: Boolean, default: true },
    isModal:       { type: Boolean, default: true },
    width:         { type: String,  default: "460px" },
    visible:       { type: Boolean, default: false }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.dialog) {
      this.dialog.destroy();
      this.dialog = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Public Actions
  // ---------------------------------------------------------------------------
  open() {
    if (this.dialog) {
      this.dialog.show();
    }
  }

  close() {
    if (this.dialog) {
      this.dialog.hide();
    }
  }

  toggle() {
    if (!this.dialog) return;

    if (this.dialog.visible) {
      this.close();
    } else {
      this.open();
    }
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------
  #init() {
    if (this.dialog) return;

    // Find inner dialog container or use element itself
    const targetElement = this.element.querySelector(".ej2-dialog-container") || this.element;

    this.dialog = new Dialog({
      header:        this.headerValue || targetElement.getAttribute("data-header") || "",
      showCloseIcon: this.showCloseIconValue,
      isModal:       this.isModalValue,
      width:         this.widthValue,
      visible:       this.visibleValue,
      target:        document.body,
      animationSettings: { effect: "Zoom", duration: 150 },
      open: () => {
        this.element.dispatchEvent(new CustomEvent("ej2-dialog:open", { bubbles: true }));
      },
      close: () => {
        this.element.dispatchEvent(new CustomEvent("ej2-dialog:close", { bubbles: true }));
      }
    });

    this.dialog.appendTo(targetElement);
  }
}
