import { Controller } from "@hotwired/stimulus";
import { TextBox } from "@syncfusion/ej2-inputs";

// EJ2 TextBox Stimulus Controller
// Usage: data-controller="ej2-textbox" on container div or directly on input/textarea
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "" },
    value:       { type: String, default: "" },
    readonly:    { type: Boolean, default: false },
    multiline:   { type: Boolean, default: false }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.textbox) {
      this.textbox.destroy();
      this.textbox = null;
    }
  }

  getValue() {
    return this.textbox?.value ?? "";
  }

  setValue(val) {
    if (this.textbox) this.textbox.value = val;
  }

  #init() {
    if (this.textbox) return;

    const input = ["INPUT", "TEXTAREA"].includes(this.element.tagName)
      ? this.element
      : (this.element.querySelector("input, textarea") || this.element);

    this.textbox = new TextBox({
      placeholder:   this.placeholderValue,
      value:         this.valueValue,
      readonly:      this.readonlyValue,
      multiline:     this.multilineValue,
      floatLabelType: "Auto",
      change: (args) => {
        this.element.dispatchEvent(new CustomEvent("ej2-textbox:change", {
          bubbles: true,
          detail: { value: args.value }
        }));
      }
    });

    this.textbox.appendTo(input);
  }
}
