import { Controller } from "@hotwired/stimulus";
import { DropDownList } from "@syncfusion/ej2-dropdowns";

// EJ2 DropDownList Stimulus Controller
export default class extends Controller {
  static values = {
    placeholder:     { type: String, default: "" },
    value:           { type: String, default: "" },
    items:           { type: Array,  default: [] },
    allowFiltering:  { type: Boolean, default: true }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.dropdown) {
      this.dropdown.destroy();
      this.dropdown = null;
    }
  }

  getValue() {
    return this.dropdown?.value ?? null;
  }

  setValue(val) {
    if (this.dropdown) this.dropdown.value = val;
  }

  #init() {
    if (this.dropdown) return;

    const input = this.element.tagName === "INPUT"
      ? this.element
      : (this.element.querySelector("input") || this.element);

    this.dropdown = new DropDownList({
      placeholder:    this.placeholderValue,
      value:          this.valueValue || null,
      dataSource:     this.itemsValue,
      fields:         { text: "text", value: "value" },
      allowFiltering: this.allowFilteringValue,
      floatLabelType: "Auto",
      change: (args) => {
        this.element.dispatchEvent(new CustomEvent("ej2-dropdown:change", {
          bubbles: true,
          detail: { value: args.value, text: args.itemData?.text }
        }));
      }
    });

    this.dropdown.appendTo(input);
  }
}
