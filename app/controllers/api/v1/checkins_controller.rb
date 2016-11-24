class Api::V1::CheckinsController < Api::ApiController
  respond_to :json

  skip_before_action :find_user, only: [:create, :batch_create]
  before_action :device_exists?, only: [:create, :batch_create]
  before_action :check_user_approved_approvable, :find_device, except: [:create, :batch_create]

  def index
    per_page = params[:per_page].to_i <= 1000 ? params[:per_page] : 1000
    args = {
      copo_app: req_from_coposition_app?,
      permissible: @permissible,
      device: @device,
      page: params[:page],
      per_page: per_page,
      type: params[:type],
      time_unit: params[:time_unit],
      time_amount: params[:time_amount],
      date: params[:date],
      near: params[:near],
      unique_places: params[:unique_places],
      action: action_name
    }
    # Need paginated checkins for response headers when specific device provided
    # If no device provided, checkins are sanitized then paginated
    # If device provided, checkins must be paginated then sanitized (sanitizing removes pagination info)
    # This is due to the limiting factor of reverse_geocoding checkins when from a single device
    paginated_checkins = @user.filtered_checkins(args)
    checkins = @device ? @device.sanitize_checkins(paginated_checkins, args) : paginated_checkins
    paginated_response_headers(paginated_checkins)
    render json: checkins
  end

  def last
    checkin = @user.safe_checkin_info(
      copo_app: req_from_coposition_app?,
      permissible: @permissible,
      device: @device,
      type: params[:type],
      date: params[:date],
      near: params[:near],
      action: action_name
    )
    render json: checkin
  end

  def create
    checkin = @device.checkins.create(allowed_params)
    if checkin.save
      @device.notify_subscribers('new_checkin', checkin)
      config = @dev.configs.find_by(device_id: @device.id)
      render json: { data: [checkin], config: config }
    else
      render status: 400, json: { error: 'You must provide a lat and lng' }
    end
  end

  def batch_create
    success = @device.checkins.batch_create(request.raw_post)
    if success
      render json: { message: 'Checkins created' }, status: 200
    else
      render json: { error: 'Checkins not created' }, status: 422
    end
  end

  private

  def device_exists?
    return unless (@device = Device.find_by(uuid: request.headers['X-UUID'])).nil?
    render status: 400, json: { error: 'You must provide a valid uuid' }
  end

  def allowed_params
    params.require(:checkin).permit(:lat, :lng, :created_at, :fogged)
  end

  def find_device
    @device = Device.find(params[:device_id]) if params[:device_id]
  end
end
