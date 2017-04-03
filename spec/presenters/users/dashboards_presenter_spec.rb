require "rails_helper"

describe ::Users::DashboardsPresenter do
  subject(:dashboard) { described_class.new(user) }

  let(:user) do
    us = FactoryGirl.create(:user)
    us.friends << friend
    us
  end
  let(:friend) { FactoryGirl.create(:user) }
  let(:device) { FactoryGirl.create(:device, user_id: user.id) }
  let(:checkins) do
    FactoryGirl.create(:checkin, device_id: device.id)
    FactoryGirl.create(:checkin, device_id: device.id).reverse_geocode!
    FactoryGirl.create(:checkin, device_id: device.id)
  end

  describe "Interface" do
    %i(most_frequent_areas percent_change weeks_checkins_count most_used_device last_countries gon).each do |method|
      it { is_expected.to respond_to method }
    end
  end

  describe "most_used_device" do
    it "returns an empty array if no devices have checkins" do
      expect(dashboard.most_used_device).to eq nil
    end

    it "returns a device if a device has checkins" do
      checkins
      expect(dashboard.most_used_device).to be_kind_of Device
    end

    it "calls device_checkins_count" do
      allow(dashboard).to receive(:device_checkins_count).and_return []
      dashboard.most_used_device
      expect(dashboard).to have_received(:device_checkins_count)
    end

    it "returns another device if that device has more checkins" do
      checkins
      FactoryGirl.create(:device, user_id: user.id)
      expect(dashboard.most_used_device).to eq device
    end
  end

  describe "last_countries" do
    it "returns an empty array if no checkins" do
      expect(dashboard.last_countries).to eq []
    end

    context "with 3 checkins, 2 countries" do
      before do
        checkins
      end

      it "returns array of checkins" do
        expect(dashboard.last_countries).to be_kind_of Array
      end

      it "returns checkins ordered by created at" do
        checkins
        expect(dashboard.last_countries[0]).to eq device.checkins.first
      end

      it "returns checkins grouped by country" do
        expect(dashboard.last_countries.length).to eq 2
      end
    end
  end

  describe "gon" do
    it "returns a hash" do
      expect(dashboard.gon).to be_kind_of Hash
    end

    it "calls current_user_info" do
      allow(dashboard).to receive(:current_user_info)
      dashboard.gon
      expect(dashboard).to have_received(:current_user_info)
    end

    it "calls friends" do
      allow(dashboard).to receive(:friends)
      dashboard.gon
      expect(dashboard).to have_received(:friends)
    end

    it "calls months_checkins" do
      allow(dashboard).to receive(:months_checkins)
      dashboard.gon
      expect(dashboard).to have_received(:months_checkins)
    end
  end

  describe "fogged_city_count" do
    it "calls hash_group_and_count_by" do
      allow(Checkin).to receive(:hash_group_and_count_by).and_return []
      dashboard.send(:fogged_city_count)
      expect(Checkin).to have_received(:hash_group_and_count_by).at_least(1).times
    end

    it "returns an array" do
      expect(dashboard.send(:fogged_city_count)).to be_kind_of Array
    end
  end

  describe "device_checkins_count" do
    it "calls hash_group_and_count_by" do
      allow(Checkin).to receive(:hash_group_and_count_by).and_return []
      dashboard.send(:device_checkins_count)
      expect(Checkin).to have_received(:hash_group_and_count_by).at_least(1).times
    end

    it "returns an array" do
      expect(dashboard.send(:device_checkins_count)).to be_kind_of Array
    end
  end

  describe "friends" do
    before do
      checkins
    end

    it "returns an array" do
      expect(dashboard.send(:friends)).to be_kind_of Array
    end

    it "calls public_info_hash" do
      allow(friend).to receive(:public_info_hash)
      dashboard.send(:friends)
      expect(friend).to have_received(:public_info_hash)
    end

    it "calls safe_checkin_info_for" do
      allow(friend).to receive(:safe_checkin_info_for).and_return []
      dashboard.send(:friends)
      expect(friend).to have_received(:safe_checkin_info_for)
    end
  end

  describe "weeks_checkins" do
    it "returns active record relation" do
      checkins
      expect(dashboard.send(:weeks_checkins)).to be_kind_of ActiveRecord::Relation
    end
  end

  describe "months_checkins" do
    it "returns an array" do
      checkins
      expect(dashboard.send(:months_checkins)).to be_kind_of Array
    end
  end

  describe "current_user_info" do
    it "returns a hash" do
      checkins
      expect(dashboard.send(:current_user_info)).to be_kind_of Hash
    end

    it "calls public_info_hash" do
      allow(user).to receive(:public_info_hash)
      dashboard.send(:current_user_info)
      expect(user).to have_received(:public_info_hash)
    end
  end
end
