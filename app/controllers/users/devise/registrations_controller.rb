class Users::Devise::RegistrationsController < Devise::RegistrationsController
  protect_from_forgery with: :exception, unless: :req_from_coposition_app?
  respond_to :json
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  prepend_before_action :check_captcha, only: [:create]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    req_from_coposition_app? ? app_sign_up : super
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  def destroy
    resource_destroyed = resource.destroy_with_password(params[:user][:password])
    if resource_destroyed
      super
    else
      flash[:notice] = resource.errors.full_messages.first
      respond_with resource, location: edit_user_registration_path
    end
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  def app_sign_up
    user = User.new(user_api_params)
    if user.save
      render json: user.as_json, status: 201
    else
      warden.custom_failure!
      render json: user.errors, status: 422
    end
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :avatar])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :avatar, :zapier_enabled, :subscription])
  end

  def user_api_params
    params.require(:user).permit(:email, :password, :username)
  end

  # The path used after sign up.
  def after_sign_up_path_for(_resource)
    return session[:return_to] if session[:return_to]
    user_dashboard_path(current_user)
  end

  def check_captcha
    unless verify_recaptcha
      self.resource = resource_class.new sign_up_params
      resource.validate # Look for any other validation errors besides Recaptcha
      respond_with_navigational(resource) { render :new }
    end
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
