class Users::UsersController < ApplicationController
  def show
    redirect_to action: 'show', controller: 'users/dashboards', user_id: params[:id]
  end

  def me
    render status: 200,
      json: User.find(doorkeeper_token.resource_owner_id).public_info_hash
  end
end
