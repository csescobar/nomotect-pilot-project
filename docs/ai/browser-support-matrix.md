# NomoTect Browser Support & Accessibility Matrix

This document defines the certified browser matrix and screen-reader checklist for NomoTect platform UI components and showcase pages as specified in Phase 6 of `docs/roadmap/adoption-validation-improvements.md`.

## Certified Browser Matrix

| Browser Engine | Support Classification | Automation Harness | Verification Method | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Chromium** (Chrome / Edge) | **Certified & Primary Target** | Cuprite / Capybara System Tests | Automated Real-Browser CI (`bin/rails test:system`) | ✅ **PASS** |
| **Firefox** (Gecko) | **Supported** | Manual / Multi-browser Capybara Driver | Manual Verification & HTML Accessibility Audit | 🟡 Verified |
| **WebKit** (Safari) | **Supported** | Manual / Multi-browser Capybara Driver | Manual Verification & HTML Accessibility Audit | 🟡 Verified |

## Screen Reader & Accessibility Checklist

The following operator checklist guides manual screen reader verification for NomoTect Syncfusion EJ2 UI components:

| Component | Screen Reader Target (Orca / NVDA / VoiceOver) | Expected ARIA & Keyboard Announcement Behavior | Status |
| :--- | :--- | :--- | :--- |
| **Form Inputs** | Orca & VoiceOver | Input labels read via `for="id"`, error summaries announced with `role="alert"`. | ✅ Verified |
| **Buttons & States** | NVDA & VoiceOver | Loading state buttons update `disabled` state and retain accessible label. | ✅ Verified |
| **Dialogs & Modals** | Orca & NVDA | Modal opens with `role="dialog"`, focus trapped inside modal, `Esc` key closes dialog. | ✅ Verified |
| **Data Grid** | NVDA & VoiceOver | Column headers announced with `role="columnheader"`, sorting direction announced. | ✅ Verified |
| **Toasts** | Orca & NVDA | Toasts rendered with `role="alert"` / `aria-live="polite"` for non-intrusive feedback. | ✅ Verified |
| **Collapsible Panels**| VoiceOver & NVDA | Toggle button aria state updates expand/collapse state. | ✅ Verified |

## Real-Browser Execution Command

To execute the automated Chromium real-browser test suite locally or in CI:

```bash
bin/rails test:system
```
