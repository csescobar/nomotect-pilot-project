class Ej2ShowcaseController < ApplicationController
  allow_unauthenticated_access

  def show
    @active_section = params[:section] || "forms"
  end
end
