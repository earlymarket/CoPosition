require 'rails_helper'

RSpec.describe Api::V1::Users::DevicesController, type: :controller do
  include ControllerMacros

  let(:device) { FactoryGirl.create :device }
  let(:empty_device) { FactoryGirl.create :device }
  let(:developer) do
    dev = FactoryGirl.create :developer
    Approval.link(user, dev, 'Developer')
    Approval.accept(user, dev, 'Developer')
    Approval.link(second_user, dev, 'Developer')
    Approval.accept(second_user, dev, 'Developer')
    dev
  end
  let(:user) do
    us = FactoryGirl.create :user
    us.devices << device
    us
  end
  let(:second_user) do
    us = FactoryGirl.create :user
    us.devices << FactoryGirl.create(:device)
    us
  end
  let(:params) { { user_id: user.id, format: :json } }
  let(:device_params) { params.merge(id: device.id) }
  let(:create_params) { params.merge(device: { name: 'new' }) }
  let(:private_device_info) { %w(uuid fogged delayed) }

  before do
    api_request_headers(developer, user)
  end

  describe 'GET' do
    it 'returns a list of devices of a specific user' do
      get :index, params: params
      expect(res_hash.first['id']).to be device.id
    end

    it 'does not return friends cloaked devices' do
      second_user.devices.each{ |device| device.update! cloaked: true }
      get :index, params: params.merge(user_id: second_user.id)
      expect(res_hash.size).to eq 0
    end

    it 'does return cloaked devices if request from copo_app' do
      request.headers['X-Secret-App-Key'] = 'this-is-a-mobile-app'
      second_user.devices.each{ |device| device.update! cloaked: true }
      get :index, params: params.merge(user_id: second_user.id)
      expect(res_hash.size).to eq second_user.devices.count
    end

    it 'records the request' do
      expect(developer.requests.count).to be 0
      get :index, params: params
      expect(developer.requests.count).to be 1
    end

    it 'returns filtered information on a device belonging to a user' do
      get :show, params: device_params
      expect(res_hash[:data]['id']).to be device.id
      expect(res_hash[:data].keys).to_not include(*private_device_info)
    end

    it 'returns full info if request is from copo app or from developer with control' do
      developer.configs.create(device: device)
      get :show, params: device_params
      expect(res_hash[:data]['uuid']).to eq device.uuid
      expect(res_hash[:config]['id']).to eq developer.configs.find_by(device: device).id
      expect(res_hash[:data].keys).to include(*private_device_info)
    end

    it 'returns an error message if device does not exist' do
      get :show, params: device_params.merge(id: 9999999)
      expect(res_hash[:error]).to eq('Device does not exist')
      expect(response.status).to eq 404
    end
  end

  describe 'POST' do
    it 'creates a device with a UUID provided' do
      create_params[:device] = { uuid: empty_device.uuid }
      config_count = developer.configs.count
      post :create, params: create_params
      expect(developer.configs.count).to be config_count + 1
      expect(res_hash[:data]['user_id']).to be user.id
      expect(res_hash[:data]['uuid']).to eq empty_device.uuid
    end

    it 'fails to to create a device with a taken UUID' do
      create_params[:device] = { uuid: device.uuid }
      count = user.devices.count
      post :create, params: create_params
      expect(user.devices.count).to be count
      expect(res_hash[:error]).to match 'registered to another user'
    end

    it 'fails to to create a device with a taken name' do
      create_params[:device] = { name: device.name }
      post :create, params: create_params
      expect(res_hash[:error]).to match device.name
    end
  end

  describe 'PUT' do
    it 'updates settings' do
      put :update, params: device_params.merge(device: { fogged: true })
      expect(res_hash[:data]['fogged']).to eq(true)
      put :update, params: device_params.merge(device: { fogged: false })
      device.reload
      expect(res_hash[:data]['fogged']).to eq(false)
    end

    it 'rejects non-existant device ids' do
      put :update, params: device_params.merge(id: 9999999, device: { fogged: true })
      expect(response.status).to eq(404)
      expect(res_hash[:error]).to eq('Device does not exist')
    end

    it 'returns an error if updating with same name as another device' do
      user.devices << empty_device
      put :update, params: device_params.merge(id: empty_device.id, device: { name: device.name })
      expect(response.status).to eq(400)
      expect(res_hash[:error]['name'][0]).to match 'already been taken'
    end

    it 'does not allow you to update someone elses device' do
      put :update, params: {
        user_id: second_user.id, id: second_user.devices.last.id, device: { fogged: true }, format: :json
      }
      expect(response.status).to eq(403)
      expect(res_hash[:error]).to eq('User does not own device')
    end
  end
end
