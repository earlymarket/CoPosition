require 'rails_helper'

RSpec.describe Api::V1::CheckinsController, type: :controller do
  include ControllerMacros, CityMacros

  let(:developer) { FactoryGirl.create :developer }
  let(:user) { FactoryGirl.create :user }
  let(:second_user) { FactoryGirl.create :user }
  let(:device) do
    device = FactoryGirl.create :device
    user.devices << device
    device
  end
  let(:checkin) { FactoryGirl.create :checkin, device: device }
  let(:subscription) { FactoryGirl.create :subscription, subscriber: user }
  let(:friend_sub) { FactoryGirl.create :subscription, subscriber: second_user, event: 'friend_new_checkin' }
  let(:create_headers) { request.headers['X-UUID'] = device.uuid }
  let(:address) { 'The Pilot Centre, Denham Aerodrome, Denham Aerodrome, Denham, Buckinghamshire UB9 5DF, UK' }
  let(:params) { { user_id: user.id, device_id: device.id } }
  let(:geocode_params) { params.merge(type: 'address') }
  let(:lat_lng) { { lat: Faker::Address.latitude, lng: Faker::Address.longitude } }
  let(:create_params) { { checkin: lat_lng } }
  let(:foggable_checkin_attributes) { %w(city postal_code) }
  let(:private_checkin_attributes) { %w(uuid fogged fogged_lat fogged_lng fogged_city) }

  before do |example|
    create_denhams
    api_request_headers(developer, user)
    unless example.metadata[:skip_before]
      device
      Approval.link(user, second_user, 'User')
      Approval.accept(second_user, user, 'User')
      Approval.link(user, developer, 'Developer')
      Approval.accept(user, developer, 'Developer')
    end
  end

  shared_context 'from copo app' do
    before do
      request.headers['X-Secret-App-Key'] = 'this-is-a-mobile-app'
      checkin.reload
    end
  end

  describe 'GET #last' do
    context 'without developer approval' do
      it "shouldn't fetch the last reported location", :skip_before do
        get :last, params: params
        expect(res_hash[:error]).to eq 'approval_status: No Approval'
      end
    end

    context 'with developer approval but without friend approval' do
      it "shouldn't fetch the last reported location", :skip_before do
        device
        Approval.link(user, developer, 'Developer')
        Approval.accept(user, developer, 'Developer')
        get :last, params: params.merge(permissible_id: second_user.id)
        expect(res_hash[:error]).to eq 'approval_status: No Approval'
      end
    end

    context 'with approval' do
      before do
        device.switch_fog
        checkin
      end

      it 'should fetch the last reported location (public attributes only)' do
        get :last, params: params
        expect(res_hash.first['lat']).to be checkin.lat
        expect(res_hash.first.keys).not_to include(*private_checkin_attributes)
      end

      it 'should fetch the last reported location for a friend' do
        get :last, params: params.merge(permissible_id: second_user.id)
        expect(res_hash.first['lat']).to be checkin.lat
      end

      it "should fetch the last reported location's address in full by default" do
        get :last, params: geocode_params
        expect(res_hash.first['address']).to eq address
        expect(res_hash.first['lat']).to eq checkin.lat
        expect(res_hash.first['lng']).to eq checkin.lng
      end

      it "should fog the last reported location's address and lat/lng if fogged" do
        device.switch_fog
        device.checkins.create(lat: 51.57123, lng: -0.50523)
        get :last, params: geocode_params
        expect(res_hash.first['city']).to eq 'Denham'
        expect(res_hash.first['lat']).not_to eq(51.57123)
        expect(res_hash.first['lng']).not_to eq(-0.50523)
        expect(res_hash.first.keys).not_to include(*private_checkin_attributes)
      end

      it 'should bypass fogging if bypass_fogging is true' do
        # Make it fogged
        device.switch_fog
        device.checkins.create(lat: 51.57471, lng: -0.50626)
        Permission.last.update(bypass_fogging: true)
        get :last, params: geocode_params
        expect(res_hash.first['address']).to eq address
        expect(res_hash.first['lat']).to eq(51.57471)
        expect((foggable_checkin_attributes - res_hash.first.keys).empty?).to be true
      end
    end

    context 'on a user' do
      it 'should fetch the last reported location' do
        device.switch_fog
        checkin
        get :last, params: { user_id: user.id }
        expect(res_hash.first['lat']).to be checkin.lat
      end
    end

    context 'from coposition app' do
      include_context 'from copo app'

      it "should fetch the user's last device checkin with all attributes" do
        get :last, params: params
        expect(res_hash.first['id']).to be checkin.id
        expect(res_hash.first.keys).to match checkin.attributes.keys
      end

      it 'should geocode last checkin if type param provided' do
        get :last, params: geocode_params
        expect(res_hash.first['city']).to eq 'Denham'
      end

      it 'should ignore fogging by default' do
        get :last, params: params
        expect(res_hash.first['lat']).to eq checkin.lat
      end
    end
  end

  describe 'GET #index when the device has 31 checkins' do
    before do
      31.times do
        FactoryGirl.create :checkin, device: device
      end
      device.permission_for(developer).update(privilege: 'complete')
    end

    context 'with no page param given' do
      it 'should fetch the most recent checkins (up to 30 checkins)' do
        get :index, params: params
        expect(res_hash.first['id']).to be device.checkins.first.id
        expect(response.header['X-Next-Page']).to eq '2'
        expect(response.header['X-Current-Page']).to eq '1'
        expect(response.header['X-Total-Entries']).to eq device.checkins.count.to_s
        expect(response.header['X-Per-Page']).to eq '30'
        expect(res_hash.size).to eq 30
      end

      it 'should geocode all checkins with type address' do
        device.permission_for(developer).update(bypass_fogging: true)
        get :index, params: geocode_params
        expect(res_hash.first['address']).to match 'The Pilot Centre'
        expect(res_hash.last['address']).to match 'The Pilot Centre'
      end
    end

    context 'with page param' do
      it 'should fetch the checkins on that page if they exist' do
        page = 2
        get :index, params: params.merge(page: page)
        expect(res_hash.first['id']).to be device.checkins.last.id
        expect(response.header['X-Current-Page']).to eq page.to_s
        expect(response.header['X-Next-Page']).to eq 'null'
      end

      it 'should fetch the right amount of checkins with per page provided' do
        page = 4
        get :index, params: params.merge(page: page, per_page: 5)
        expect(res_hash.size).to eq 5
        expect(response.header['X-Next-Page']).to eq '5'
        expect(response.header['X-Current-Page']).to eq page.to_s
      end

      it 'should not get any checkins if page does not exist' do
        get :index, params: params.merge(page: 3)
        expect(response.body).to eq '[]'
      end
    end

    context 'on a user' do
      it 'should fetch the most recent checkins (up to 30 checkins)' do
        get :index, params: { user_id: user.id }
        expect(res_hash.first['id']).to be device.checkins.first.id
      end
    end

    context 'copo mobile app' do
      include_context 'from copo app'

      it "should fetch all the user's device checkins" do
        get :index, params: params
        expect(res_hash.first.keys).to eq checkin.attributes.keys
        expect(res_hash.first['id']).to be checkin.id
      end

      it 'should ignore fogging by default' do
        get :index, params: params
        expect(res_hash.first['lng']).to be checkin.lng
      end
    end

    context 'with near param' do
      it 'should return checkins near the lat lng provided' do
        get :index, params: params.merge(near: '51.5,-0.5')
        expect(res_hash.all? { |checkin| 51.5 - Checkin.find(checkin['id']).lat < 0.5 }).to be true
        expect(res_hash.size).to eq 30
      end

      it 'should not return any checkins if none near' do
        get :index, params: params.merge(near: '45,-0.5')
        expect(res_hash.size).to eq 0
      end
    end

    context 'with date param' do
      it 'should return checkins from the date provided' do
        date = Date.today
        get :index, params: params.merge(date: date)
        expect(res_hash.all? { |checkin| Date.parse(checkin['created_at']) == date }).to be true
        expect(res_hash.size).to eq 30
      end

      it 'should not return any checkins if none on date' do
        get :index, params: params.merge(date: Date.yesterday)
        expect(res_hash.size).to eq 0
      end
    end

    context 'with time scope params' do
      it 'should return checkins in the time scope provided' do
        now = Time.now
        get :index, params: params.merge(time_unit: 'hour', time_amount: 1)
        expect(res_hash.all? { |checkin| now - Time.parse(checkin['created_at']) < now - 1.hour.ago }).to be true
        expect(res_hash.size).to eq 30
      end

      it 'should not return any checkins if none in time scope' do
        get :index, params: params.merge(time_unit: 'second', time_amount: 0)
        expect(res_hash.size).to eq 0
      end
    end

    context 'with unique places param' do
      it 'should return only unique fogged area checkins' do
        device.checkins.second.update(fogged_city: 'London', output_city: 'London')
        get :index, params: params.merge(unique_places: true)
        expect(res_hash.size).to eq 2
        expect(res_hash[1]['city']).to eq device.checkins.second.fogged_city
      end
    end
  end

  describe 'POST #create' do
    it 'should create a checkin when there is a pre-existing device' do
      subscription
      friend_sub
      count = user.checkins.count
      create_headers
      post :create, params: create_params
      expect(res_hash[:data].first['uuid']).to eq device.uuid
      expect(user.checkins.count).to be(count + 1)
      expect(user.checkins.first.device).to eq device
    end

    it 'should return 400 if you POST a checkin with missing parameters' do
      create_headers
      post :create, params: { checkin: { lat: Faker::Address.latitude } }
      expect(response.status).to eq(400)
      expect(res_hash[:error]).to eq('You must provide a lat and lng')
    end

    it 'should return 400 if you POST a checkin with invalid uuid' do
      request.headers['X-UUID'] = 'thisdevicedoesntexist'
      post :create, params: create_params
      expect(response.status).to eq(400)
      expect(res_hash[:error]).to eq('You must provide a valid uuid')
    end
  end

  describe 'POST #batch_create' do
    it 'should create a batch of checkins when there is a pre-existing device' do
      count = user.checkins.count
      create_headers
      post :batch_create, body: [lat_lng, lat_lng, lat_lng].to_json, format: :json
      expect(res_hash[:message]).to eq('Checkins created')
      expect(user.checkins.count).to be(count + 3)
      expect(user.checkins.first.device).to eq device
    end

    it 'should return 422 if you POST a checkin with missing parameters' do
      create_headers
      post :batch_create, body: [{ lat: Faker::Address.latitude }].to_json, format: :json
      expect(response.status).to eq(422)
      expect(res_hash[:error]).to eq('Checkins not created')
    end
  end
end