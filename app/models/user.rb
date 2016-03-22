class User < ActiveRecord::Base
  extend FriendlyId
  include ApprovalMethods
  include SlackNotifiable

  acts_as_token_authenticatable

  friendly_id :username, use: [:slugged, :finders]

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => { username: false, email: true }

  validates :username, uniqueness: true,
                       allow_blank: true,
                       format: { with: /\A[-a-zA-Z_]+\z/,
                         message: "only allows letters, underscores and dashes" }

  has_many :devices, dependent: :destroy
  has_many :checkins, through: :devices
  has_many :requests
  has_many :approvals, dependent: :destroy
  has_many :developers, -> { where "status = 'accepted'" }, through: :approvals, source: :approvable, :source_type => "Developer"
  has_many :friends, -> { where "status = 'accepted'" }, through: :approvals, source: :approvable, :source_type => "User"
  has_many :pending_friends, -> { where "status = 'pending'" }, :through => :approvals, source: :approvable, :source_type => "User"
  has_many :friend_requests, -> { where "status = 'requested'" }, :through => :approvals, source: :approvable, :source_type => "User"
  has_many :developer_requests, -> { where "status = 'developer-requested'" }, :through => :approvals, source: :approvable, :source_type => "Developer"
  has_many :permissions, :as => :permissible, dependent: :destroy
  has_many :permitted_devices, through: :permissions, source: :permissible, :source_type => "Device"

  has_attachment :avatar
  ## Pathing

  def url_id
    username.empty? ? id : username.downcase
  end

  ## Approvals

  def approved?(permissible)
    developers.include?(permissible) || friends.include?(permissible)
  end

  def has_request_from(approvable)
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

  def approved_for(approval)
    if approval.approvable_type == 'User'
      self.friends
    elsif approval.approvable_type == 'Developer'
      self.developers
    else
      raise "Unhandled approval type"
    end
  end

  def pending_for(approval)
    if approval.approvable_type == 'User'
      self.friend_requests
    elsif approval.approvable_type == 'Developer'
      self.developer_requests
    else
      raise "Unhandled approval type"
    end
  end

  ## Devices

  def approve_devices(permissible)
    if permissible.class.to_s == 'Developer'
      dev_devices = devices.includes(:developers)
      dev_devices.each do |device|
        device.developers << permissible unless device.developers.include? permissible
      end
    else
      usr_devices = devices.includes(:permitted_users)
      usr_devices.each do |device|
        device.permitted_users << permissible unless device.permitted_users.include? permissible
      end
    end
  end

  ################

  ## Checkins

  def get_checkins(permissible, device)
    device ? device.permitted_history_for(permissible) : get_user_checkins(permissible)
  end

  def get_user_checkins(permissible)
    checkins_ids = devices.inject([]) do |result, device|
      result + device.permitted_history_for(permissible).pluck(:id)
    end
    Checkin.where(id: checkins_ids)
  end

  ##############

  def slack_message
    "A new user has registered, id: #{self.id}, name: #{self.username}, there are now #{User.count} users."
  end

  def notifications
    @notes ||= begin
      @notes = []
      if pending_approvals.present?
        @notes << {
          notification: {
              msg: "You have #{pending_approvals.count} pending approvals",
              link_path: "user_apps_path"
            }
          }
      end
      if friend_requests.present?
        @notes << {
          notification: {
              msg: "You have #{friend_requests.count} friend requests",
              link_path: "user_friends_path"
            }
          }
      end
      @notes
    end
  end

end
