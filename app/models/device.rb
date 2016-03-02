class Device < ActiveRecord::Base
  include SlackNotifiable
  include SwitchFogging

  belongs_to :user
  has_many :checkins, dependent: :destroy
  has_many :permissions, dependent: :destroy
  has_many :developers, through: :permissions, source: :permissible, :source_type => "Developer"
  has_many :permitted_users, through: :permissions, source: :permissible, :source_type => "User"

  before_create do |dev|
    dev.uuid = SecureRandom.uuid
  end

  def construct(current_user, device_name)
    update(user: current_user, name: device_name)
    developers << current_user.developers
    permitted_users << current_user.friends
  end

  def checkins
    delayed? ? super.before(delayed.minutes.ago) : super
  end

  def permitted_history_for(permissible)
    return Checkin.none if permission_for(permissible).privilege == "disallowed"
    approval_date = user.approval_for(permissible).approval_date

    if permission_for(permissible).privilege == "last_only"
      can_show_history?(permissible) ? Checkin.where(id: checkins.last.id) : Checkin.where(id: checkins.since(approval_date).last.id)
    else
      can_show_history?(permissible) ? checkins : checkins.since(approval_date)
    end

  end

  def permission_for(permissible)
    permissions.find_by(permissible_id: permissible.id, permissible_type: permissible.class.to_s)
  end

  def can_show_history?(permissible)
    permission_for(permissible).show_history
  end

  def can_bypass_fogging?(permissible)
    permission_for(permissible).bypass_fogging
  end

  def slack_message
    "A new device has been created"
  end

  def set_delay(mins)
    if mins.to_i == 0
      update(delayed: nil)
    else
      update(delayed: mins)
    end
  end

end
