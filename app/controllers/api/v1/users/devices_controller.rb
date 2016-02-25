class Api::V1::Users::DevicesController < Api::ApiController
  respond_to :json

  acts_as_token_authentication_handler_for User, only: :update

  before_action :authenticate, :check_user_approved_approvable
  before_action :check_user, only: :update

  def index
    devices = @user.devices
    render json: devices
  end

  def show
    device = @user.devices.where(id: params[:id])
    render json: device
  end

  def update
    device = @user.devices.where(id: params[:id]).first
    if device_exists? device
      device.update(device_params)
      render json: device
    end
  end

  private

    def check_user
      unless current_user?(params[:user_id])
        render status: 403, json: { message: 'User does not own device' }
      end
    end

    def device_params
      params.require(:device).permit(:name, :fogged, :delayed, :alias)
    end

end

