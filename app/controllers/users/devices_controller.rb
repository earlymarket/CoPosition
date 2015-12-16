class Users::DevicesController < ApplicationController

  acts_as_token_authentication_handler_for User
  protect_from_forgery with: :null_session
  before_action :authenticate_user!

  def index
    @devices = current_user.devices.map do |dev|
      dev.checkins.last.reverse_geocode! if dev.checkins.exists?
      dev
    end
  end

  def show
    @device = Device.find(params[:id]) if user_owns_device?
    if @device.fogged?
      @fogmessage = "Currently fogged"
    else
      @fogmessage = "Fog"
    end
  end

  def new
    @device = Device.new
    @device.uuid = params[:uuid] if params[:uuid]
    @adding_current_device = true if params[:curr_device]
    @redirect_target = params[:redirect] if params[:redirect]
  end

  def create
    @device = Device.find_by uuid: allowed_params[:uuid]
    if @device
      # Providing that there isn't anyone currently assigned
      if @device.user.nil?
        create_device
        redirect_using_param_or_default unless via_app
      elsif req_from_coposition_app?
        render status: 400, json: { message: 'This device has already been assigned to a user' }
      else
        flash[:alert] = "This device has already been assigned an account!"
        redirect_to new_user_device_path
      end
    else
      if req_from_coposition_app?
        render status: 400, json: { message: 'The UUID provided does not match an existing device' }
      else
        flash[:alert] = "Not found"
        redirect_to new_user_device_path
      end
    end
  end

  def destroy
    Device.find(params[:id]).destroy if user_owns_device?
    flash[:notice] = "Device deleted"
    redirect_to user_devices_path
  end

  def checkin
    @checkin_id = params[:checkin_id]
    Device.find(params[:id]).checkins.find(@checkin_id).delete if user_owns_device?
    redirect_to user_device_path
  end

  def switch_privilege_for_developer
    @device = Device.find(params[:id]) if user_owns_device?
    @developer = Developer.find(params[:developer])
    @device.change_privilege_for(@developer, @device.reverse_privilege_for(@developer))
    @privilege = @device.privilege_for(@developer)
    @r_privilege = @device.reverse_privilege_for(@developer)
  end

  def add_current
    flash[:notice] = "Just enter a friendly name, and this device is good to go."
    redirect_to new_user_device_path(uuid: Device.create.uuid, curr_device: true)
  end

  def fog
    @device = Device.find(params[:id])
    if @device.switch_fog
      @message = "has been fogged."
      @button_text = "Fogged"
    else
      @message = "is no longer fogged."
      @button_text = "Fog"
    end
  end

  def set_delay
    @device = Device.find(params[:id])
    @device.delayed = params[:mins]
    @device.save
  end

  private
    def via_app
      render json: @device.to_json if req_from_coposition_app?
    end

    def allowed_params
      params.require(:device).permit(:uuid,:name)
    end

    def create_device
      @device.user = current_user
      @device.name = allowed_params[:name]
      @device.developers << current_user.approved_developers.map do |app|
        app.developer
      end
      @device.save
      flash[:notice] = "This device has been bound to your account!"

      @device.create_checkin(lat: params[:location].split(",").first,
          lng: params[:location].split(",").last) unless params[:location].blank?
    end

    def redirect_using_param_or_default(default: user_device_path(current_user.id, @device.id))
      if params[:redirect].blank?
        redirect_to default
      else
        redirect_to params[:redirect]
      end
    end
end
