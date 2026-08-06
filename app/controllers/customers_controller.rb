class CustomersController < ApplicationController
  before_action :set_organization
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    authorize!(@organization, :show?)
    @customers = Customers::VisibleTo.new(user: Current.user, organization: @organization).call
  end

  def show
    authorize!(@customer, :show?)
    @events = DomainEvent.where(aggregate_type: "Customer", aggregate_id: @customer.id).recent_first.limit(20)
  end

  def new
    @customer = @organization.customers.new
    authorize!(@customer, :create?)
  end

  def create
    @customer = @organization.customers.new(customer_params)
    authorize!(@customer, :create?)
    result = Customers::Create.new.call(organization: @organization, attributes: customer_params)
    redirect_to [ @organization, result.record ], status: :see_other, notice: t("customers.created")
  rescue ActiveRecord::RecordInvalid => error
    @customer = error.record
    render :new, status: :unprocessable_content
  end

  def edit
    authorize!(@customer, :update?)
  end

  def update
    authorize!(@customer, :update?)
    result = Customers::Update.new.call(customer: @customer, attributes: customer_params)
    redirect_to [ @organization, result.record ], status: :see_other, notice: t("customers.updated")
  rescue ActiveRecord::RecordInvalid => error
    @customer = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::StaleObjectError
    @customer.reload
    flash.now[:alert] = t("customers.conflict")
    render :edit, status: :conflict
  end

  def destroy
    authorize!(@customer, :destroy?)
    Customers::Destroy.new.call(customer: @customer)
    redirect_to organization_customers_path(@organization), status: :see_other, notice: t("customers.destroyed")
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_customer
    @customer = @organization.customers.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :email_address, :status, :notes, :lock_version)
  end
end
