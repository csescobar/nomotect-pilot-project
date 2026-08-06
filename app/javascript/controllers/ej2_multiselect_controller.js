import { Controller } from "@hotwired/stimulus";
import { MultiSelect } from "@syncfusion/ej2-dropdowns";

// EJ2 MultiSelect Stimulus Controller
export default class extends Controller {
  static values = {
    placeholder:    { type: String, default: "" },
    value:          { type: Array,  default: [] },
    items:          { type: Array,  default: [] },
    allowFiltering: { type: Boolean, default: true },
    showSelectAll:  { type: Boolean, default: true }
  };

  connect() {
    this.#init();
  }

  disconnect() {
    if (!this.element.isConnected && this.multiselect) {
      this.multiselect.destroy();
      this.multiselect = null;
    }
  }

  getValues() {
    return this.multiselect?.value ?? [];
  }

  #init() {
    if (this.multiselect) return;

    const input = this.element.tagName === "INPUT"
      ? this.element
      : (this.element.querySelector("input") || this.element);

    this.multiselect = new MultiSelect({
      placeholder:    this.placeholderValue,
      value:          this.valueValue.length ? this.valueValue : null,
      dataSource:     this.itemsValue,
      fields:         { text: "text", value: "value" },
      allowFiltering: this.allowFilteringValue,
      showSelectAll:  this.showSelectAllValue,
      mode:           "Box",
      floatLabelType: "Auto",
      change: (args) => {
        this.element.dispatchEvent(new CustomEvent("ej2-multiselect:change", {
          bubbles: true,
          detail: { value: args.value }
        }));
      }
    });

    this.multiselect.appendTo(input);
  }
}
