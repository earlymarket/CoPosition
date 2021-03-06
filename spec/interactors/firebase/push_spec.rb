require "rails_helper"

describe Firebase::Push do
  let(:user) { create :user }

  let(:notification) do
    {
      body: "Coposition test message",
      title: "Coposition check-in"
    }
  end

  let(:expected_body) do
    {
      to: "/topics/#{user.id}",
      priority: "high",
      notification: {
        body: "Coposition test message",
        title: "Coposition check-in"
      }
    }.to_json
  end

  let(:expected_headers) do
    {
      "Content-Type" => "application/json",
      "Authorization" => "key=#{Rails.app_config.firebase_server_key}"
    }
  end

  let(:response) { { "message_id": 1 }.to_json }

  before do
    stub_request(:post, "https://fcm.googleapis.com/fcm/send")
      .with(body: expected_body, headers: expected_headers)
      .to_return(body: response, headers: json_content_type)
  end

  it "sends push notification" do
    described_class.call(topic: user.id, notification: notification)
  end

  context "when device is defined" do
    let(:device) { create :device, user: user }
    let(:expected_body) do
      {
        to: "/topics/#{user.id}",
        priority: "high",
        notification: {
          body: "Coposition test message",
          title: "Coposition check-in"
        },
        device: device.id
      }.to_json
    end

    it "includes device id into push payload" do
      described_class.call(
        device: device.id,
        topic: user.id,
        notification: notification
      )
    end
  end

  context "when content_available is defined" do
    let(:content_available) { true }
    let(:expected_body) do
      {
        to: "/topics/#{user.id}",
        priority: "high",
        notification: {
          body: "Coposition test message",
          title: "Coposition check-in"
        },
        content_available: true
      }.to_json
    end

    it "includes content-available into push payload" do
      described_class.call(
        content_available: content_available,
        topic: user.id,
        notification: notification
      )
    end
  end
end
