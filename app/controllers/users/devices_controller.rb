class Users::DevicesController < ApplicationController
  before_action :authenticate_user!, :correct_url_user?, except: :shared
  before_action :published?, only: :shared
  before_action :require_ownership, only: [:show, :destroy, :update]

  def index
    @presenter = ::Users::DevicesPresenter.new(current_user, params, 'index')
    gon.push(@presenter.index_gon)
  end

  def show
    @presenter = ::Users::DevicesPresenter.new(current_user, params, 'show')
    gon.push(@presenter.show_gon)
    respond_to do |format|
      format.html { flash[:notice] = 'Right click on the map to check-in' }
      format.any(:csv, :gpx, :geojson) { send_data @presenter.checkins, filename: @presenter.filename }
    end
  end

  def new
    @device = Device.new
    @device.uuid = params[:uuid] if params[:uuid]
  end

  def shared
    @presenter = ::Users::DevicesPresenter.new(current_user, params, 'shared')
    gon.push(@presenter.shared_gon)
  end

  def info
    presenter = ::Users::DevicesPresenter.new(current_user, params, 'info')
    @device = presenter.device
    @config = presenter.config
  end

  def create
    result = Users::Devices::CreateDevice.call(user: current_user,
                                               developer: Developer.default(coposition: true),
                                               params: params)
    if result.success?
      gon.checkins = result.checkin
      redirect_to user_device_path(id: result.device.id)
    else
      redirect_to new_user_device_path, notice: result.error
    end
  end

  def destroy
    Checkin.where(device: params[:id]).delete_all
    Device.find(params[:id]).destroy
    flash[:notice] = 'Device deleted'
    redirect_to user_devices_path
  end

  def update
    result = ::Users::Devices::UpdateDevice.call(params: params)
    @device = result.device
    flash[:notice] = result.notice
    return unless request.format.json?
    if result.success?
      render status: 200, json: {}
    else
      render status: 400, json: result.error
    end
  end

  private

  def require_ownership
    return if user_owns_device?
    flash[:notice] = 'You do not own that device'
    redirect_to root_path
  end

  def published?
    device = Device.find(params[:id])
    return if device.published? && !device.cloaked?
    redirect_to root_path, notice: 'Could not find shared device'
  end
end
