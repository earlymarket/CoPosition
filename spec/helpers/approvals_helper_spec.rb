require "rails_helper"

RSpec.describe ApprovalsHelper, type: :helper do
  let(:user) do
    user = create(:user)
    user.pending_friends << [create(:user), create(:user)]
    user
  end
  let(:user_approvals_input) { helper.approvals_input("User") }
  let(:developer_approvals_input) { helper.approvals_input("Developer") }

  describe "#approvals_approvable_name" do
    it "converts a friend's email if their username is empty" do
      friend = create(:user, username: "")
      expect(friend.email).to include(helper.approvals_approvable_name(friend))
      expect(helper.approvals_approvable_name(friend).length < friend.email.length).to be
    end

    it "gives a company name if passed a developer" do
      dev = create(:developer)
      expect(helper.approvals_approvable_name(dev)).to be dev.company_name
    end
  end

  describe "#approvals_friends_device_link" do
    it "adds a link if approvable_type is User" do
      allow(helper).to receive(:current_user) { user }
      expect(helper.approvals_friends_device_link("User", user) { "blah" }).to match "<a href"
      expect(helper.approvals_friends_device_link("User", user) { "blah" }).to match "blah"
    end

    it "doesn't add a link if approvable_type is Developer" do
      expect(helper.approvals_friends_device_link("Developer", user) { "blah" }).to_not match "<a href"
      expect(helper.approvals_friends_device_link("Developer", user) { "blah" }).to match "blah"
    end
  end

  describe "#approvals_friends_locater" do
    it "returns nothing if approvable type isn't User" do
      expect(helper.approvals_friends_locator("Developer", user)).to eq nil
    end

    it "returns a string if approvable type User" do
      expect(helper.approvals_friends_locator("User", user)).to be_kind_of String
    end

    it "returns a string containing my_location" do
      expect(helper.approvals_friends_locator("User", user)).to match "my_location"
    end
  end
end
