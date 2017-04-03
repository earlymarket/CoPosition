require "rails_helper"

RSpec.describe Users::Checkins::UpdateCheckin, type: :interactor do
  subject(:context) { described_class.call(params: params) }

  let(:checkin) { FactoryGirl.create :checkin, device: device }
  let(:device) { FactoryGirl.create :device, fogged: false }
  let(:params) { ActionController::Parameters.new(id: checkin.id, checkin: { lat: checkin.lat + 10 }) }

  describe "call" do
    context "when given lat/lng" do
      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns checkin" do
        expect(context.checkin).to eq checkin
      end

      it "updates checkin lat" do
        expect(context.checkin.lat).to eq checkin.lat + 10
      end
    end

    context "when given no params" do
      let(:params) { ActionController::Parameters.new(id: checkin.id) }

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns checkin" do
        expect(context.checkin).to eq checkin
      end

      it "updates output values" do
        expect(context.checkin.output_lat).to eq context.checkin.fogged_lat
      end
    end
  end
end
