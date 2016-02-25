class Api::V1::Users::DevicesController < Api::ApiController
  respond_to :json

  acts_as_token_authentication_handler_for User, only: [:update, :switch_privilege, :switch_all_privileges]

  before_action :authenticate, :check_user_approved_developer
  before_action :check_user, only: [:update, :switch_privilege, :switch_all_privileges]

  def index
    list = []
    @user.devices.except(:fogged).map do |devc|
      if devc.privilege_for(@dev) == "complete"
        list << devc.device_checkin_hash
      end
    end
    respond_with list
  end

  def show
    list = []
    @user.devices.where(id: params[:id]).except(:fogged).map do |devc|
      if devc.privilege_for(@dev) == "complete"
        list << devc.device_checkin_hash
      else
        return head status: :unauthorized
      end
    end
    respond_with list
  end

  def update
    device = @user.devices.where(id: params[:id]).first
    if device_exists? device
      device.update(device_params)
      render json: device
    end
  end

  def switch_privilege
    model = model_find(params[:permissible_type])
    @permissible = model.where(id: params[:permissible_id]).first
    device = @user.devices.where(id: params[:id]).first
    if (device_exists? device) && (resource_exists?(params[:permissible_type], @permissible))
      device.change_privilege_for(@permissible, params[:privilege])
      render status: 200, json: device.permissions.where(permissible: @permissible)
    end
  end

  def switch_all_privileges
    model = model_find(params[:permissible_type])
    @permissible = model.where(id: params[:permissible_id]).first
    devices = @user.devices
    permissions = []
    if (device_exists? devices) && (resource_exists?(params[:permissible_type], @permissible))
      devices.each do |device|
        device.change_privilege_for(@permissible, params[:privilege])
        permissions << device.permissions.where(permissible: @permissible)
      end
      render status: 200, json: permissions
    end
  end

  private

    def check_user
      unless current_user?(params[:user_id])
        render status: 403, json: { message: 'Incorrect User' }
      end
    end

    def device_params
      params.require(:device).permit(:name, :fogged, :delayed, :alias)
    end

end

