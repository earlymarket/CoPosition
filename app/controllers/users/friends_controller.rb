class Users::FriendsController < ApplicationController
  before_action :friends?

  def show
    @friend = User.find(params[:id])
    @devices = @friend.devices
  end

  def show_device
    @friend = User.find(params[:id])
    @device = @friend.devices.find(params[:device_id])
    @paginated_checkins = @friend.get_checkins(current_user, @device).order(created_at: :desc) \
      .paginate(page: params[:page], per_page: 1000)
    @checkins = @paginated_checkins
    @checkins = @checkins.map do |checkin|
      checkin.get_data
    end unless @device.can_bypass_fogging?(current_user)
    gon.checkins = @paginated_checkins
  end

  private
    def friends?
      friend = User.find(params[:id])
      unless friend.approved?(current_user)
        flash[:notice] = 'You are not friends with that user'
        redirect_to user_friends_path(current_user)
      end
    end
end
