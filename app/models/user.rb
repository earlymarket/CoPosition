class User < ApplicationRecord
  extend FriendlyId
  include ApprovalMethods, SlackNotifiable, RemoveId

  PUBLIC_ATTRIBUTES = %i(id username slug email)

  acts_as_token_authenticatable

  attr_accessor :private_profile, :pin_color

  friendly_id :username, use: %i(finders slugged)

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable,
    authentication_keys: { username: false, email: true }

  validates :username, uniqueness: true, case_sensitive: false, allow_blank: true,
                       format: { with: /\A[-a-zA-Z_]+\z/, message: "only allows letters, underscores and dashes" },
                       length: { in: 4..20 }
  validates :email, confirmation: true

  has_one :email_subscription, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :checkins, through: :devices
  has_many :requests
  has_many :approvals, dependent: :destroy
  has_many :subscriptions, as: :subscriber, dependent: :destroy
  has_many :email_requests, dependent: :destroy
  has_many :developers,
    -> { where "status in (?)", %w[accepted complete] },
    through: :approvals,
    source: :approvable,
    source_type: "Developer"
  has_many :complete_developers,
    -> { where "status = 'complete'" },
    through: :approvals,
    source: :approvable,
    source_type: "Developer"
  has_many :approved_developers,
    -> { where "status = 'accepted'" },
    through: :approvals,
    source: :approvable,
    source_type: "Developer"
  has_many :developer_approvals, -> { where(status: "accepted", approvable_type: "Developer") }, class_name: "Approval"
  has_many :friends,
    -> { where "status = 'accepted' AND users.is_active = true" },
    through: :approvals,
    source: :approvable,
    source_type: "User"
  has_many :friend_approvals, -> { where(status: "accepted", approvable_type: "User") }, class_name: "Approval"
  has_many :pending_friends,
    -> { where "status = 'pending' AND users.is_active = true" },
    through: :approvals,
    source: :approvable,
    source_type: "User"
  has_many :friend_requests,
    -> { where "status = 'requested' AND users.is_active = true" },
    through: :approvals,
    source: :approvable,
    source_type: "User"
  has_many :developer_requests,
    -> { where "status = 'developer-requested'" },
    through: :approvals,
    source: :approvable,
    source_type: "Developer"
  has_many :permissions, as: :permissible, dependent: :destroy
  has_many :permitted_devices, through: :permissions, source: :permissible, source_type: "Device"

  before_create :generate_token, unless: :webhook_key?

  before_destroy :destroy_approvals, :destroy_checkins

  after_create :approve_coposition_mobile_app, :create_pending_requests, :create_email_subscription

  has_attachment :avatar

  scope :active, -> { where(is_active: true) }

  ## Pathing

  def url_id
    username.empty? ? id : username.downcase
  end

  def should_generate_new_friendly_id?
    slug.blank? || username_changed?
  end

  def self.active_users
    User.where(is_active: true)
  end

  def active_for_authentication?
    super and self.is_active?
  end

  def inactive_message
    "Your account has been disabled"
  end

  def update_last_web_visit_at
    return if last_web_visit_at == Date.current
    update(last_web_visit_at: Date.current)
  end

  def update_last_mobile_visit_at
    return if last_mobile_visit_at == Date.current
    update(last_mobile_visit_at: Date.current)
  end

  ## Approvals

  def approve_coposition_mobile_app
    mobile_dev = Developer.default(mobile: true)
    mobile_dev.approvals.find_by(user_id: id).tap do |approval|
      approval ||= Approval.add_developer(self, mobile_dev)
      approval.complete!
    end
    Doorkeeper::AccessToken.find_or_create_for(mobile_dev.oauth_application, id, "public", nil, true)
  end

  def create_pending_requests
    EmailRequest.where(email: email).find_each do |request|
      Approval.add_friend(request.user, self)
      request.destroy
    end
  end

  def approved?(permissible)
    authorized_dev?(permissible) || approved_user?(permissible)
  end

  def request_from?(approvable)
    friend_requests.include?(approvable) || developer_requests.include?(approvable)
  end

  def approval_for(approvable)
    approvals.find_by(approvable_id: approvable.id, approvable_type: approvable.class.to_s) || NoApproval.new
  end

  def destroy_approvals
    Approval.where(approvable_id: id, approvable_type: "User").destroy_all
  end

  ## Permissions

  def destroy_permissions_for(approvable)
    devices.each do |device|
      permission = device.permission_for(approvable)
      permission&.destroy
    end
  end

  ## Email Subscriptions

  def create_email_subscription
    EmailSubscription.create(user: self)
  end

  ## Devices

  def approve_devices(permissible)
    devices.includes(:developers, :permitted_users).each do |device|
      if permissible.class.to_s == "Developer"
        device.developers << permissible unless device.developers.include? permissible
      else
        device.permitted_users << permissible unless device.permitted_users.include? permissible
      end
    end
  end

  ## Checkins

  # returns sanitized + filtered checkins without pagination info if device present
  def safe_checkin_info(args)
    args[:device] ? args[:device].safe_checkin_info_for(args) : safe_checkin_info_for(args)
  end

  # returns filtered checkins with pagination info, but not sanitized if device present
  def filtered_checkins(args)
    args[:device] ? args[:device].filtered_checkins(args) : safe_checkin_info_for(args)
  end

  def safe_checkin_info_for(args)
    args[:multiple_devices] = true
    # sort_by slows this query down A LOT
    safe_checkins = devices.flat_map { |device| device.safe_checkin_info_for(args) }
                           .sort_by  { |key| key["created_at"] }.reverse
    if args[:action] == "index"
      safe_checkins.paginate(page: args[:page], per_page: args[:per_page])
    elsif args[:action] == "last"
      safe_checkins.slice(0, 1)
    end
  end

  def destroy_checkins
    devices.each { |device| DeleteDeviceWorker.perform_async(device.id) }
  end

  def slack_message
    "A new user has registered, id: #{id}, name: #{username}, there are now #{User.count} users."
  end

  def display_name
    username.present? ? username : email.split("@").first
  end

  def public_info
    # Clears out any potentially sensitive attributes
    # Returns a normal ActiveRecord relation
    User.select(PUBLIC_ATTRIBUTES).find(id)
  end

  def self.public_info
    all.select(PUBLIC_ATTRIBUTES)
  end

  def public_info_hash
    # Converts to hash and attaches avatar
    public_info.attributes.merge(avatar: avatar || { public_id: "no_avatar" })
  end

  def copo_app_access_token
    copo_app = Developer.default(mobile: true).oauth_application
    return nil unless copo_app

    Doorkeeper::AccessToken
      .where(["resource_owner_id = ? AND application_id = ?", id, copo_app.id])
      .first
      &.token
  end

  private

  def authorized_dev?(permissible)
    complete_developers.include?(permissible)
  end

  def approved_dev?(permissible)
    developers.include?(permissible)
  end

  def approved_user?(permissible)
    friends.include?(permissible)
  end

  def generate_token
    self.webhook_key = SecureRandom.uuid
  end
end
