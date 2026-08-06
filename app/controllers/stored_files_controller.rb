class StoredFilesController < ApplicationController
  before_action :set_organization
  before_action :set_stored_file

  def show
    authorize!(@stored_file, :show?)
    download = StoredFiles::Download.new(actor: Current.user).call(
      organization: @organization,
      stored_file: @stored_file
    )

    send_data download.bytes,
      filename: download.name,
      type: download.content_type,
      disposition: "attachment"
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_stored_file
    @stored_file = @organization.stored_files.find(params[:id])
  end
end
