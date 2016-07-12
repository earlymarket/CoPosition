class Api::V1::UsersController < Api::ApiController
  respond_to :json

  skip_before_action :find_user, :authenticate,  only: :auth
  before_action :check_user_approved_approvable, only: :show

  def show
    @user = @user.public_info unless req_from_coposition_app?
    respond_with @user
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
