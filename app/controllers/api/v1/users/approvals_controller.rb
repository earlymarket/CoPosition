class Api::V1::Users::ApprovalsController < Api::ApiController
  respond_to :json

  before_action :authenticate, :find_user

  def create
  	# For some reason respond_with doesn't work here
  	# TODO: research why
    @dev.request_approval_from(@user).select(:id, :approved, :pending).first
    @approval = Approval.where(user: @user, developer: @dev)
    render json: @approval.to_json
  end

  def approve
    @approval = Approval.where(id: params[:id], user: @user).first
    @approval.approve!
    @approved_devs = @user.approved_developers
    render nothing: true
  end

  def pending_approvals
    @pending_approvals = @user.pending_approvals
    render json: @pending_approvals
  end

  def status
  	respond_with approval_status: @dev.approval_status_for(@user) 
  end	

end