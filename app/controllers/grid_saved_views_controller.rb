class GridSavedViewsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :set_grid
  before_action :set_saved_view, only: %i[update destroy]

  def create
    saved_view = Current.user.grid_saved_views.new(saved_view_params.merge(grid_key: @definition.key))
    if saved_view.save
      redirect_to grid_path(@definition.key, view_id: saved_view.id), status: :see_other, notice: t("grid_engine.saved_views.created")
    else
      redirect_to grid_path(@definition.key), status: :see_other, alert: saved_view.errors.full_messages.to_sentence
    end
  end

  def update
    if @saved_view.update(saved_view_params)
      redirect_to grid_path(@definition.key, view_id: @saved_view.id), status: :see_other, notice: t("grid_engine.saved_views.updated")
    else
      redirect_to grid_path(@definition.key), status: :see_other, alert: @saved_view.errors.full_messages.to_sentence
    end
  end

  def destroy
    @saved_view.destroy!
    redirect_to grid_path(@definition.key), status: :see_other, notice: t("grid_engine.saved_views.destroyed")
  end

  private

  def set_grid
    @definition = GridEngine::Catalog.fetch(params[:grid_id])
  rescue KeyError
    head :not_found
  end

  def set_saved_view
    @saved_view = Current.user.grid_saved_views.for_grid(@definition.key).find(params[:id])
  end

  def saved_view_params
    raw = params.require(:grid_saved_view).permit(:name, :default, :query_json, :preferences_json)
    {
      name: raw[:name],
      default: ActiveModel::Type::Boolean.new.cast(raw[:default]),
      query: parse_json_object(raw[:query_json]),
      preferences: parse_json_object(raw[:preferences_json])
    }
  end

  def parse_json_object(value)
    return value.to_h if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
    parsed = JSON.parse(value.presence || "{}")
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError, TypeError
    {}
  end
end
