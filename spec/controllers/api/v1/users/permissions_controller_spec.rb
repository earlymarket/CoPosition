require 'rails_helper'

RSpec.describe Api::V1::Users::PermissionsController, type: :controller do
  include ControllerMacros
  let(:device) { FactoryGirl.create :device }
  let(:second_device) { FactoryGirl.create :device }
  let(:user) do
    u = FactoryGirl.create :user
    u.devices << device
    u
  end
  let(:second_user) do
    u = FactoryGirl.create :user
    u.devices << second_device
    u
  end
  let(:developer) { FactoryGirl.create :developer }
  let(:permission) do
    device.permitted_users << second_user
    device.developers << developer
    Permission.last
  end

  before do
    api_request_headers(developer, user)
  end

  describe 'index' do
    it 'should return a list of permissions' do
      permission
      get :index, device_id: device.id, user_id: user.id
      expect(res_hash.length).to eq Permission.count
      expect(res_hash.first.keys).to eq(Permission.column_names)
    end
  end

  describe 'update' do
    it 'should update the privilege level, bypass_fogging and bypass_delay attributes' do
      put :update,
          permission: {
            bypass_delay: true,
            bypass_fogging: true,
            privilege: 'last_only'
          },
          id: permission.id,
          device_id: device.id,
          user_id: user.id
      expect(res_hash[:privilege]).to eq 'last_only'
      expect(res_hash[:bypass_fogging]).to eq true
      expect(res_hash[:bypass_delay]).to eq true
    end

    it 'should fail to update permission if signed in user does not own permission' do
      request.headers['X-User-Token'] = second_user.authentication_token
      request.headers['X-User-Email'] = second_user.email
      put :update,
          user_id: second_user.id,
          device_id: second_device.id,
          id: permission.id
      expect(response.status).to be 403
      expect(res_hash[:error]).to eq 'You do not control that permission'
    end
  end

  describe 'update_all' do
    it 'should update all the permissions on a device' do
      permission
      put :update_all,
          device_id: device.id,
          user_id: user.id,
          permission: {
            privilege: 1
          }
      expect(res_hash.count).to eq 2
      expect(res_hash.all? { |permission| permission['privilege'] == 'last_only' }).to eq true
    end

    it 'should fail to update if user does not own device' do
      put :update_all,
          device_id: second_device.id,
          user_id: user.id
      expect(res_hash[:error]).to eq 'You do not control that device'
    end
  end
end
