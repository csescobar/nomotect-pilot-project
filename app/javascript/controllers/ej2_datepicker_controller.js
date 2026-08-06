import { Controller } from "@hotwired/stimulus";
import { DatePicker } from "@syncfusion/ej2-calendars";

// EJ2 DatePicker Stimulus Controller
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "" },
    value:       { type: String, default: "" },
    format:      { type: String, default: "dd/MM/yyyy" },
    min:         { type: String, default: "" },
    max:         { type: String, default: "" }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.datepicker) {
      this.datepicker.destroy();
      this.datepicker = null;
    }
  }

  getValue() {
    return this.datepicker?.value ?? null;
  }

  #init() {
    if (this.datepicker) return;

    const input = this.element.tagName === "INPUT"
      ? this.element
      : (this.element.querySelector("input") || this.element);

    const opts = {
      placeholder:   this.placeholderValue,
      format:        this.formatValue,
      floatLabelType: "Auto",
      change: (args) => {
        this.element.dispatchEvent(new CustomEvent("ej2-datepicker:change", {
          bubbles: true,
          detail: { value: args.value }
        }));
      }
    };

    if (this.valueValue) opts.value = new Date(this.valueValue);
    if (this.minValue)   opts.min   = new Date(this.minValue);
    if (this.maxValue)   opts.max   = new Date(this.maxValue);

    this.datepicker = new DatePicker(opts);
    this.datepicker.appendTo(input);
  }
}
