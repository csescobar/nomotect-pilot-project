// Registers the Syncfusion EJ2 license key before any EJ2 component is loaded.
// The key is injected server-side into window.SYNCFUSION_LICENSE_KEY by the
// application layout (config/initializers/syncfusion.rb → app/views/layouts/application.html.erb).
//
// This module must be imported once in application.js before any EJ2 import.
import { registerLicense, L10n } from "@syncfusion/ej2-base";

const key = window.SYNCFUSION_LICENSE_KEY || "";
if (key) {
  registerLicense(key);
}

// Global localization strings for EJ2 components
L10n.load({
  en: {
    grid: {
      EmptyRecord: "No records to display",
      True: "True",
      False: "False",
      Search: "Search",
      Columnchooser: "Columns",
      FilterButton: "Filter",
      ClearButton: "Clear",
      SelectAll: "Select All"
    },
    pager: {
      currentPageInfo: "{0} of {1} pages",
      totalItemsInfo: "({0} items)",
      firstPageTooltip: "First page",
      lastPageTooltip: "Last page",
      nextPageTooltip: "Next page",
      previousPageTooltip: "Previous page"
    }
  },
  "pt-BR": {
    grid: {
      EmptyRecord: "Nenhum registro a exibir",
      True: "Verdadeiro",
      False: "Falso",
      Search: "Pesquisar",
      Columnchooser: "Colunas",
      FilterButton: "Filtrar",
      ClearButton: "Limpar",
      SelectAll: "Selecionar todos"
    },
    pager: {
      currentPageInfo: "{0} de {1} páginas",
      totalItemsInfo: "({0} itens)",
      firstPageTooltip: "Primeira página",
      lastPageTooltip: "Última página",
      nextPageTooltip: "Próxima página",
      previousPageTooltip: "Página anterior"
    }
  }
});
