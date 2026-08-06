import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._scrollToBottom()
    // Watch for DOM mutations so new log entries auto-scroll
    this._observer = new MutationObserver(() => this._scrollToBottom())
    this._observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this._observer && this._observer.disconnect()
  }

  _scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
