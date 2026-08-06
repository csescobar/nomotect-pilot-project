import { Controller } from "@hotwired/stimulus";
import { NumericTextBox } from "@syncfusion/ej2-inputs";

// EJ2 NumericTextBox Stimulus Controller
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "" },
    value:       { type: Number, default: 0 },
    min:         { type: Number, default: null },
    max:         { type: Number, default: null },
    step:        { type: Number, default: 1 },
    format:      { type: String, default: "n0" }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.numeric) {
      this.numeric.destroy();
      this.numeric = null;
    }
  }

  getValue() {
    return this.numeric?.value ?? 0;
  }

  setValue(val) {
    if (this.numeric) this.numeric.value = val;
  }

  #init() {
    if (this.numeric) return;

    const input = this.element.tagName === "INPUT"
      ? this.element
      : (this.element.querySelector("input") || this.element);

    const opts = {
      placeholder:   this.placeholderValue,
      value:         this.valueValue,
      step:          this.stepValue,
      format:        this.formatValue,
      floatLabelType: "Auto",
      change: (args) => {
        this.element.dispatchEvent(new CustomEvent("ej2-numeric:change", {
          bubbles: true,
          detail: { value: args.value }
        }));
      }
    };

    if (this.minValue !== null) opts.min = this.minValue;
    if (this.maxValue !== null) opts.max = this.maxValue;

    this.numeric = new NumericTextBox(opts);
    this.numeric.appendTo(input);
  }
}
