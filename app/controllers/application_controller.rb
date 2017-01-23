class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
  include ApiApplicationMixin

  def record_not_found(exception)
    redirect_to root_path, alert: exception.message
  end

  def approvals_presenter_and_gon(type)
    @presenter = ::Users::ApprovalsPresenter.new(current_user, type)
    gon.push(@presenter.gon)
  end

  def correct_url_user?
    return if User.find(params[:user_id]) == current_user
    redirect_to controller: params[:controller], action: params[:action], user_id: current_user.friendly_id
  end

  def authenticate_admin!
    authenticate_user!

    redirect_to root_path, alert: "Unauthorized Access" unless current_user.admin?
  end
end
