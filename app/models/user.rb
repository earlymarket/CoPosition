class User < ApplicationRecord
  extend FriendlyId
  include ApprovalMethods, SlackNotifiable, RemoveId

  acts_as_token_authenticatable

  friendly_id :username, use: [:finders, :slugged]

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable,
         authentication_keys: { username: false, email: true }

  validates :username, uniqueness: true, allow_blank: true,
                       format: { with: /\A[-a-zA-Z_]+\z/, message: 'only allows letters, underscores and dashes' }

  has_many :devices, dependent: :destroy
  has_many :checkins, through: :devices
  has_many :requests
  has_many :approvals, dependent: :destroy
  has_many :subscriptions, as: :subscriber, dependent: :destroy
  has_many :developers, -> { where "status = 'accepted'" }, through: :approvals, source: :approvable,
                                                            source_type: 'Developer'
  has_many :developer_approvals, -> { where(status: 'accepted', approvable_type: 'Developer') }, class_name: 'Approval'
  has_many :friends, -> { where "status = 'accepted'" }, through: :approvals, source: :approvable, source_type: 'User'
  has_many :friend_approvals, -> { where(status: 'accepted', approvable_type: 'User') }, class_name: 'Approval'
  has_many :pending_friends, -> { where "status = 'pending'" }, through: :approvals, source: :approvable,
                                                                source_type: 'User'
  has_many :friend_requests, -> { where "status = 'requested'" }, through: :approvals, source: :approvable,
                                                                  source_type: 'User'
  has_many :developer_requests, -> { where "status = 'developer-requested'" }, through: :approvals, source: :approvable,
                                                                               source_type: 'Developer'
  has_many :permissions, as: :permissible, dependent: :destroy
  has_many :permitted_devices, through: :permissions, source: :permissible, source_type: 'Device'

  before_create :generate_token, unless: :webhook_key?

  after_create :approve_coposition_mobile_app

  has_attachment :avatar
  ## Pathing

  def url_id
    username.empty? ? id : username.downcase
  end

  ## Approvals

  def approve_coposition_mobile_app
    Approval.add_developer(self, Developer.default(mobile: true))
  end

  def approved?(permissible)
    developers.include?(permissible) || friends.include?(permissible)
  end

  def request_from?(approvable)
    friend_requests.include?(approvable) || developer_requests.include?(approvable)
  end

  def approval_for(approvable)
    approvals.find_by(approvable_id: approvable.id, approvable_type: approvable.class.to_s) || NoApproval.new
  end

  def destroy_permissions_for(approvable)
    devices.each do |device|
      permission = device.permission_for(approvable)
      permission.destroy if permission
    end
  end

  def not_coposition_developers
    copo_keys = [Rails.application.secrets['coposition_api_key'], Rails.application.secrets['mobile_app_api_key']]
    developers.where('api_key NOT IN(?)', copo_keys)
  end

  ## Devices

  def approve_devices(permissible)
    devices.includes(:developers, :permitted_users).each do |device|
      if permissible.class.to_s == 'Developer'
        device.developers << permissible unless device.developers.include? permissible
      else
        device.permitted_users << permissible unless device.permitted_users.include? permissible
      end
    end
  end

  ## Checkins

  def safe_checkin_info(args)
    args[:device] ? args[:device].safe_checkin_info_for(args) : safe_checkin_info_for(args)
  end

  def safe_checkin_info_for(args)
    args[:multiple_devices] = true
    safe_checkins = devices.flat_map { |device| device.safe_checkin_info_for(args) }
                           .sort_by  { |key| key['created_at'] }.reverse
    if args[:action] == 'index'
      safe_checkins.paginate(page: args[:page], per_page: args[:per_page])
    elsif args[:action] == 'last'
      safe_checkins.slice(0, 1)
    end
  end

  def get_checkins(permissible, device)
    device ? device.permitted_history_for(permissible) : get_user_checkins_for(permissible)
  end

  def get_user_checkins_for(permissible)
    subqueries = devices.map do |device|
      Checkin.arel_table[:id].in(device.permitted_history_for(permissible).ids)
    end
    subqueries.present? ? Checkin.where(subqueries.inject(&:or)) : Checkin.none
  end

  def changed_location?
    most_recent = checkins[0]
    second_most_recent = checkins[1]
    return true unless second_most_recent
    lat_diff = (most_recent.lat - second_most_recent.lat).abs
    lng_diff = (most_recent.lng - second_most_recent.lng).abs
    lat_diff > 0.001 || lng_diff > 0.001
  end

  ##############

  def slack_message
    "A new user has registered, id: #{id}, name: #{username}, there are now #{User.count} users."
  end

  def public_info
    # Clears out any potentially sensitive attributes
    # Returns a normal ActiveRecord relation
    User.select([:id, :username, :slug, :email]).find(id)
  end

  def self.public_info
    all.select([:id, :username, :slug, :email])
  end

  def public_info_hash
    # Converts to hash and attaches avatar
    public_info.attributes.merge(avatar: avatar || { public_id: 'no_avatar' })
  end

  private

  def generate_token
    self.webhook_key = SecureRandom.uuid
  end
end
