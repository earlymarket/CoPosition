module Users
  class FriendsPresenter
    attr_reader :friend
    attr_reader :devices
    attr_reader :device
    attr_reader :show_checkins
    # for tests, maybe a better way of doing this
    attr_reader :show_device_gon
    attr_reader :index_gon

    def initialize(user, params, action)
      @user = user
      @friend = User.find(params[:id])
      @params = params
      send action
    end

    def show
      @devices = @friend.devices.where(cloaked: false).ordered_by_checkins.paginate(page: @params[:page], per_page: 5)
    end

    def show_device
      @device = @friend.devices.where(cloaked: false).find(@params[:device_id])
    end

    def index_gon
      {
        checkins: most_recent_checkins
      }
    end

    def show_device_gon
      checkins = device_checkins
      {
        checkins: checkins.paginate(page: 1, per_page: 1000),
        total: checkins.size
      }
    end

    def show_checkins
      {
        checkins: device_checkins.paginate(page: @params[:page], per_page: @params[:per_page])
      }
    end

    private

    def most_recent_checkins
      checkins =
        @devices.map do |device|
          safe_checkins = device.safe_checkin_info_for(permissible: @user)
          safe_checkins.first.as_json.merge(device: device.name) if safe_checkins.present?
        end
      checkins.compact.sort_by { |checkin| checkin["created_at"] }.reverse
    end

    def device_checkins
      device = @friend.devices.find(@params[:device_id])
      device.safe_checkin_info_for(permissible: @user, action: "index", multiple_devices: true)
    end
  end
end
