class Users::ApprovalsController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_url_user?

  def new
    @approvals_presenter = Users::ApprovalsPresenter.new(current_user, params[:approvable_type])
    @approval = Approval.new
    gon.push(devs: Developer.all.pluck(:company_name))
  end

  def create
    result = Users::Approvals::CreateUserApproval.call(
      current_user: current_user,
      approvable: approval_params[:approvable]
    )
    approvals_presenter_and_gon("User") if result.success?
    redirect_to(result.path, result.message)
  end

  def index
    approvals_presenter_and_gon(params[:approvable_type])
    render "approvals"
  end

  def update
    result = Users::Approvals::UpdateApproval.call(
      current_user: current_user,
      params: params
    )
    if result.approvable_type == "Developer"
      result.approvable.notify_if_subscribed("new_approval", approval_zapier_data(result.approval))
    end
    approvals_presenter_and_gon(result.approvable_type)
  end

  def destroy
    result = Users::Approvals::DestroyApproval.call(
      current_user: current_user,
      params: params
    )
    approvals_presenter_and_gon(result.approvable_type)
    render "update"
  end

  private

  def approval_params
    params
      .require(:approval)
      .permit(:approvable, :approvable_type)
  end
end
