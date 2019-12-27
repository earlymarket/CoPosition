class Api::V1::UsersController < Api::ApiController
  respond_to :json

  skip_before_action :authenticate, only: :auth
  before_action :find_user, :check_user_approved_approvable, :update_last_mobile_visit_at, only: :show

  def show
    @user.private_profile = req_from_coposition_app?
    respond_with @user
  end

  def index
    @users = req_from_coposition_app? ? @dev.users.active_users.public_info : User.all
    respond_with @users
  end

  def auth
    subscriber = User.find_by(webhook_key: request.headers['X-Authentication-Key'])
    subscriber ||= Developer.find_by(api_key: request.headers['X-Authentication-Key'])
    if subscriber
      render status: 204, json: { message: 'Success' }
    else
      render status: 400, json: { error: 'Invalid webhook key supplied' }
    end
  end
end
