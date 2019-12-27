class Users::ApprovalsController < ApplicationController
  before_action :authenticate_user!, :correct_url_user?, :update_user_last_web_visit_at, except: %i[add apps friends]
  before_action :url_redirect, only: %i[add apps friends]

  def new
    @approvals_presenter = Users::ApprovalsPresenter.new(current_user, params)
    @approval = Approval.new
    gon.push(
      devs: (Developer.all - current_user.developers).pluck(:company_name),
      users: User.pluck(:email).map { |email| Digest::MD5.hexdigest(email) }
    )
  end

  def add
    redirect_to(new_user_approval_path(current_user, approvable_type: "User", email: params["email"]))
  end

  def create
    result = Users::Approvals::CreateUserApproval.call(
      current_user: current_user,
      approvable: approval_params[:approvable]
    )
    approvals_presenter_and_gon(approvable_type: "User") if result.success?
    redirect_to(result.path, result.message)
  end

  def index
    approvals_presenter_and_gon(params)
    render "approvals"
  end

  def apps
    redirect_to(user_apps_path(current_user))
  end

  def friends
    redirect_to(user_friends_path(current_user))
  end

  def update
    result = Users::Approvals::UpdateApproval.call(
      current_user: current_user,
      params: params
    )
    if result.approvable_type == "Developer"
      result.approvable.notify_if_subscribed("new_approval", approval_zapier_data(result.approval))
    end
    approvals_presenter_and_gon(approvable_type: result.approvable_type)
  end

  def destroy
    result = Users::Approvals::DestroyApproval.call(
      current_user: current_user,
      params: params
    )
    approvals_presenter_and_gon(approvable_type: result.approvable_type)
    render "update"
  end

  private

  def approval_params
    params
      .require(:approval)
      .permit(:approvable, :approvable_type)
  end
end
