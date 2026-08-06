class GridsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :show, if: -> { request.format.json? }

  def show
    @definition = GridEngine::Catalog.fetch(params[:id])
    @saved_views = Current.user.grid_saved_views.for_grid(@definition.key)
    requested_query = permitted_query.to_h
    @selected_view = @saved_views.find_by(id: params[:view_id])
    @selected_view ||= @saved_views.find_by(default: true) if params[:view_id].blank? && requested_query.empty?
    @query_params = @selected_view&.query.presence || requested_query
    @preferences = @selected_view&.preferences.presence || {}
    @ast = GridEngine::Query::Parser.new(@definition).parse(@query_params)
    @result = GridEngine::ActiveRecordAdapter.new(@definition).call(@ast, scope: grid_scope)

    respond_to do |format|
      format.html
      format.json do
        if filter_choice_request?
          field_name = params[:field] || params[:column] || extract_filter_field
          render json: GridEngine::SyncfusionAdapter.new(@definition).filter_choice_response(@result, field: field_name)
        elsif params[:adapter] == "syncfusion"
          render json: GridEngine::SyncfusionAdapter.new(@definition).response(@result)
        else
          render json: GridEngine::TabulatorAdapter.new(@definition).response(@result)
        end
      end
      format.csv do
        relation = GridEngine::ActiveRecordAdapter.new(@definition).call(export_ast, scope: grid_scope).records
        send_data GridEngine::CsvExporter.new(@definition).call(relation, columns: selected_columns),
          filename: "#{@definition.key}-#{Date.current.iso8601}.csv",
          type: "text/csv"
      end
    end
  rescue KeyError, GridEngine::Query::ValidationError
    head :unprocessable_content
  end

  private

  def permitted_query
    if params[:adapter] == "syncfusion" || params[:skip].present? || params[:take].present? || params[:sorted].present? || params[:where].present?
      parse_syncfusion_params
    else
      params.permit(:page, :per_page, filters: %i[column operator value], sorts: %i[column direction])
    end
  end

  def parse_syncfusion_params
    take = params[:take].to_i
    take = 25 if take <= 0
    skip = params[:skip].to_i
    page = (skip / take) + 1

    sorts = Array(params[:sorted]).map do |s|
      dir = s["direction"].to_s.downcase.start_with?("desc") ? "desc" : "asc"
      { column: s["name"] || s["field"], direction: dir }
    end

    filters = []
    Array(params[:where]).each do |w|
      extract_syncfusion_filters(w, filters)
    end

    if params[:search].is_a?(Array)
      params[:search].each do |s|
        key = s["key"]
        next if key.blank?

        fields = Array(s["fields"])
        field = fields.first || @definition.columns.keys.first
        filters << { column: field, operator: "contains", value: key } if field
      end
    end

    ActionController::Parameters.new(
      page: page,
      per_page: take,
      sorts: sorts,
      filters: filters
    ).permit(:page, :per_page, filters: %i[column operator value], sorts: %i[column direction])
  end

  def extract_syncfusion_filters(filter_obj, result_array)
    return unless filter_obj.is_a?(Hash) || filter_obj.is_a?(ActionController::Parameters)

    if filter_obj["predicates"].is_a?(Array)
      filter_obj["predicates"].each { |pred| extract_syncfusion_filters(pred, result_array) }
    elsif filter_obj["field"].present?
      op = map_syncfusion_operator(filter_obj["operator"])
      result_array << { column: filter_obj["field"], operator: op, value: filter_obj["value"] }
    end
  end

  def map_syncfusion_operator(op)
    case op.to_s.downcase
    when "equal", "eq" then "eq"
    when "notequal", "ne" then "not_eq"
    when "contains" then "contains"
    when "startswith" then "starts_with"
    when "greaterthan", "gt" then "gt"
    when "greaterthanorequal", "gte" then "gte"
    when "lessthan", "lt" then "lt"
    when "lessthanorequal", "lte" then "lte"
    else "contains"
    end
  end

  def filter_choice_request?
    return true if params[:action] == "filterchoice" || params[:distinct] == "true"

    where = Array(params[:where])
    where.size == 1 && where.first.is_a?(Hash) && where.first["field"].present? && params[:skip].nil? && params[:requiresCounts].nil?
  end

  def extract_filter_field
    where = Array(params[:where])
    where.first["field"] if where.first.is_a?(Hash)
  end

  def selected_columns
    params[:columns] || @preferences["columns"]
  end

  def export_ast
    GridEngine::Query::Ast.new(filters: @ast.filters, sorts: @ast.sorts, page: 1, per_page: GridEngine::CsvExporter::MAX_ROWS)
  end

  def grid_scope
    GridEngine::Catalog.scope_for(@definition.key, user: Current.user, organization: Current.organization)
  end
end
