class Device < ApplicationRecord
  include SlackNotifiable, HumanizeMinutes, RemoveId

  belongs_to :user
  has_one :config, dependent: :destroy
  has_one :configurer, through: :configs, source: :developer
  has_many :checkins, dependent: :destroy
  has_many :permissions, dependent: :destroy
  has_many :developers, through: :permissions, source: :permissible, source_type: 'Developer'
  has_many :permitted_users, through: :permissions, source: :permissible, source_type: 'User'
  has_many :allowed_user_permissions, -> { where.not privilege: 0 }, class_name: 'Permission'
  has_many :allowed_users, through: :allowed_user_permissions, source: :permissible, source_type: 'User'

  validates :name, uniqueness: { scope: :user_id }, if: :user_id

  before_create do |dev|
    dev.uuid = SecureRandom.uuid
  end

  def construct(current_user, device_name)
    if update(user: current_user, name: device_name)
      developers << current_user.developers
      permitted_users << current_user.friends
    end
  end

  def safe_checkin_info_for(args)
    sanitized = filtered_checkins(args)
    sanitize_checkins(sanitized, args)
  end

  def filtered_checkins(args)
    sanitized = args[:copo_app] ? checkins : permitted_history_for(args[:permissible])
    sanitized.since_time(args[:time_amount], args[:time_unit])
             .near_to(args[:near])
             .on_date(args[:date])
             .unique_places_only(args[:unique_places])
             .limit_returned_checkins(args)
  end

  def sanitize_checkins(sanitized, args)
    if args[:type] == 'address'
      sanitized = sanitized.map(&:reverse_geocode!) unless args[:action] == 'index' && args[:multiple_devices]
      # if only one checkin in relation geocoding would turn into array so needs to be converted back sometimes
      sanitized = checkins.where(id: sanitized[0].id) if sanitized.class.to_s == 'Array'
    end
    return sanitized if args[:copo_app]
    replace_checkin_attributes(args[:permissible], sanitized)
  end

  def replace_checkin_attributes(permissible, sanitized)
    if can_bypass_fogging?(permissible)
      sanitized.select(:id, :created_at, :updated_at, :device_id, :lat,
                       :lng, :address, :city, :postal_code, :country_code)
    else
      sanitized.select('id', 'created_at', 'updated_at', 'device_id', 'output_lat AS lat', 'output_lng AS lng',
                       'output_address AS address', 'output_city AS city', 'output_postal_code AS postal_code',
                       'output_country_code AS country_code')
    end
  end

  def permitted_history_for(permissible)
    resolve_privilege(delayed_checkins_for(permissible), permissible)
  end

  def resolve_privilege(unresolved_checkins, permissible)
    return Checkin.none if privilege_for(permissible) == 'disallowed'
    return unresolved_checkins if unresolved_checkins.empty?
    if privilege_for(permissible) == 'last_only'
      unresolved_checkins.limit(1)
    else
      unresolved_checkins
    end
  end

  def privilege_for(permissible)
    permission_for(permissible).privilege
  end

  def delayed_checkins_for(permissible)
    if can_bypass_delay?(permissible)
      checkins
    else
      checkins.before(delayed.to_i.minutes.ago)
    end
  end

  def permission_for(permissible)
    permissions.find_by(permissible_id: permissible.id, permissible_type: permissible.class.to_s)
  end

  def can_bypass_fogging?(permissible)
    permission_for(permissible).bypass_fogging
  end

  def can_bypass_delay?(permissible)
    permission_for(permissible).bypass_delay
  end

  def slack_message
    "A new device was created, id: #{id}, name: #{name}, user_id: #{user_id}. There are now #{Device.count} devices"
  end

  def update_delay(mins)
    mins.to_i.zero? ? update(delayed: nil) : update(delayed: mins)
  end

  def switch_fog
    update(fogged: !fogged)
    Checkin.transaction do
      unfogged = checkins.where(fogged: false)
      fogged ? unfogged.each(&:set_output_to_fogged) : unfogged.each(&:set_output_to_unfogged)
    end
    fogged
  end

  def humanize_delay
    if delayed.nil?
      "#{name} is not delayed."
    else
      "#{name} delayed by #{humanize_minutes(delayed)}."
    end
  end

  def public_info
    # Clears out any potentially sensitive attributes, returns a normal ActiveRecord relation
    # Returns a normal ActiveRecord relation
    Device.select([:id, :user_id, :name, :alias, :published]).find(id)
  end

  def subscriptions(event)
    Subscription.where(event: event).where(subscriber_id: user_id)
  end

  def notify_friends(data)
    Subscription.where(event: 'friend_new_checkin').where(subscriber_id: user.friends).each do |sub|
      checkin = safe_checkin_info_for(permissible: sub.subscriber, type: 'address', action: 'last').first
      next unless checkin && checkin['id'] == data['id'] && user.changed_location?
      sub.send_data([checkin])
    end
  end

  def notify_subscribers(event, data)
    notify_friends(data) if event == 'new_checkin'
    return unless (subs = subscriptions(event))
    data = data.as_json
    data.merge!(remove_id.as_json)
    data.merge!(user.public_info.remove_id.as_json) if user
    subs.each { |subscription| subscription.send_data([data]) }
  end

  def self.public_info
    select([:id, :user_id, :name, :alias, :published])
  end

  def self.last_checkins
    all.map { |device| device.checkins.first if device.checkins.exists? }.compact.sort_by(&:created_at).reverse
  end

  def self.geocode_last_checkins
    all.each { |device| device.checkins.first.reverse_geocode! if device.checkins.exists? }
  end

  def self.ordered_by_checkins
    device_ids = last_checkins.map(&:device_id)
    ordered_devices = all.index_by(&:id).values_at(*device_ids)
    ordered_devices += all
    ordered_devices.uniq
  end
end
