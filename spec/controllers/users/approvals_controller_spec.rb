require "rails_helper"

RSpec.describe Users::ApprovalsController, type: :controller do
  include ControllerMacros

  let(:user) do
    user = create_user
    user.devices << create(:device)
    user
  end
  let(:friend) do
    friend = create :user
    friend.devices << create(:device)
    friend
  end
  let(:developer) { create :developer }
  let(:approval) do
    app = create :approval
    app.update(user: user)
    app.save
    app
  end
  let(:approval_two) do
    app = create :approval
    app.update(user: friend)
    app.save
    app
  end
  let(:user_params) { { user_id: user.id } }
  let(:add_params) { { email: friend.email } }
  let(:friend_approval_create_params) do
    user_params.merge(approval: { approvable: friend.email, approvable_type: "User" })
  end
  let(:friend_approval_create_params_upcased) do
    user_params.merge(approval: { approvable: friend.email.upcase, approvable_type: "User" })
  end
  let(:approve_reject_params) { user_params.merge(id: approval.id) }
  let(:approve_revoke_params) { approve_reject_params.merge(revoke: true) }
  let(:invite_params) do
    user_params.merge(invite: "", approval: { approvable: "new@email.com", approvable_type: "User" })
  end

  describe "GET #new" do
    it "assigns an empty approval" do
      get :new, params: user_params
      expect((assigns :approval).model_name).to match "Approval"
    end
  end

  describe "POST #create" do
    context "when adding a friend" do
      it "creates a pending approval, friend request" do
        approval_count = Approval.where(approvable_type: "User").count
        post :create, params: friend_approval_create_params
        expect(Approval.where(approvable_type: "User").count).to eq approval_count + 2
        expect(Approval.where(user: user, approvable: friend, status: "pending")).to exist
        expect(Approval.where(user: friend, approvable: user, status: "requested")).to exist
      end

      it "is case insensitive" do
        approval_count = Approval.where(approvable_type: "User").count
        post :create, params: friend_approval_create_params_upcased
        expect(Approval.where(approvable_type: "User").count).to eq approval_count + 2
        expect(Approval.where(user: user, approvable: friend, status: "pending")).to exist
        expect(Approval.where(user: friend, approvable: user, status: "requested")).to exist
      end

      it "confirms an existing user friend request" do
        approval.update(status: "requested", approvable_id: friend.id, approvable_type: "User")
        approval_two.update(status: "pending", approvable_id: user.id, approvable_type: "User")
        post :create, params: friend_approval_create_params
        expect(Approval.where(user: user, approvable: friend, status: "accepted")).to exist
        expect(Approval.where(user: friend, approvable: user, status: "accepted")).to exist
      end
    end

    context "when adding a friend not signed up with copo" do
      it "creates an EmailRequest" do
        request_count = EmailRequest.count
        post :create, params: user_params.merge(approval: { approvable: "new@email.com", approvable_type: "User" })
        expect(EmailRequest.count).to eq request_count + 1
      end
    end

    context "when an incorrect name is provided" do
      it "doesn't create or approve an approval if trying to add self" do
        approval_count = Approval.where(approvable_type: "User").count
        friend_approval_create_params[:approval][:approvable] = user.email
        post :create, params: friend_approval_create_params
        expect(flash[:alert]).to match "Adding self"
        expect(Approval.where(approvable_type: "User").count).to eq approval_count
      end

      it "doesn't create/approve if trying to add an exisiting friend" do
        approval.update(status: "accepted", approvable_id: friend.id, approvable_type: "User")
        approval_two.update(status: "accepted", approvable_id: user.id, approvable_type: "User")
        approval_count = Approval.count
        post :create, params: friend_approval_create_params
        expect(flash[:alert]).to match "exists"
        expect(Approval.count).to eq approval_count
      end
    end
  end

  describe "GET #add" do
    it "redirects signed in user to add page" do
      user
      get :add, params: add_params
      expect(response).to redirect_to(new_user_approval_path(user, approvable_type: "User", email: friend.email))
    end

    it "redirects signed out user to sign in page" do
      get :add, params: add_params
      expect(response).to redirect_to(new_user_session_url(return_to: request.fullpath))
    end
  end

  describe "GET #index" do
    it "assigns current users apps, devices, pending with Developer type" do
      approval.update(status: "accepted", approvable_id: developer.id, approvable_type: "Developer")
      get :index, params: user_params.merge(approvable_type: "Developer")
      expect(assigns(:approvals_presenter).approved).to eq user.approved_developers.not_coposition_developers
      expect(assigns(:approvals_presenter).devices).to eq user.devices
      expect(assigns(:approvals_presenter).pending).to eq user.developer_requests
    end

    it "assigns current users friends with User type" do
      approval.update(status: "requested", approvable_id: friend.id, approvable_type: "User")
      approval_two.update(status: "pending", approvable_id: user.id, approvable_type: "User")
      Approval.accept(user, friend, "User")
      get :index, params: user_params.merge(approvable_type: "User")
      expect(assigns(:approvals_presenter).pending).to eq user.friend_requests
      expect(assigns(:approvals_presenter).approved).to eq user.friends
      expect(assigns(:approvals_presenter).devices).to eq user.devices
    end
  end

  describe "GET #apps" do
    it "redirects to index if user logged in" do
      user
      get :apps
      expect(response).to redirect_to(user_apps_path(user))
    end

    it "rediects to login if no user logged in" do
      get :apps
      expect(response).to redirect_to(new_user_session_path(return_to: "/apps"))
    end
  end

  describe "GET #friends" do
    it "redirects to index if user logged in" do
      user
      get :friends
      expect(response).to redirect_to(user_friends_path(user))
    end

    it "rediects to login if no user logged in" do
      get :friends
      expect(response).to redirect_to(new_user_session_path(return_to: "/friends"))
    end
  end

  describe "PUT #update" do
    it "approves a developer approval request" do
      approval.update(status: "developer-requested", approvable_id: developer.id, approvable_type: "Developer")
      request.accept = "text/javascript"
      put :update, params: approve_reject_params
      expect(Approval.find_by(approvable_id: developer.id).status).to eq "accepted"
    end
  end

  describe "DELETE #destroy" do
    it "rejects and destroy a developer approval request" do
      approval.update(status: "developer-requested", approvable_id: developer.id, approvable_type: "Developer")
      approval_count = Approval.count
      request.accept = "text/javascript"
      delete :destroy, params: approve_reject_params
      expect(Approval.count).to eq approval_count - 1
    end

    it "rejects and destroy both sides of a user approval" do
      approval.update(status: "requested", approvable_id: friend.id, approvable_type: "User")
      approval_two.update(status: "pending", approvable_id: user.id, approvable_type: "User")
      approval_count = Approval.count
      request.accept = "text/javascript"
      delete :destroy, params: approve_reject_params
      expect(Approval.count).to eq approval_count - 2
    end

    it "destroys an existing approval and permissions" do
      approval.update(status: "requested", approvable_id: friend.id, approvable_type: "User")
      approval_two.update(status: "pending", approvable_id: user.id, approvable_type: "User")
      Approval.accept(user, friend, "User")
      permission_count = Permission.count
      request.accept = "text/javascript"
      delete :destroy, params: approve_reject_params
      expect(Permission.count).to eq permission_count - 2
    end

    it "updates an existing approval to accepted" do
      approval.update(status: "complete", approvable_id: developer.id, approvable_type: "Developer")
      request.accept = "text/javascript"
      expect {
        delete :destroy, params: approve_revoke_params
      }.to change { Approval.find(approval.id).status }.to "accepted"
    end
  end
end
