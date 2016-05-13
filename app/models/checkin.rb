class Checkin < ActiveRecord::Base
  include SwitchFogging

  validates :lat, presence: :true
  validates :lng, presence: :true
  belongs_to :device

  delegate :user, to: :device

  default_scope { order(created_at: :desc) }
  scope :since, -> (date) { where("created_at > ?", date)}
  scope :before, -> (date) { where("created_at < ?", date)}

  reverse_geocoded_by :lat, :lng do |obj,results|
    if results.present?
      results.first.methods.each do |m|
        obj.send("#{m}=", results.first.send(m)) if column_names.include? m.to_s
      end
    else
      obj.update(address: 'No address available')
    end
  end


  after_create do
    if device
      self.uuid = device.uuid
      self.fogged = device.fogged
      device.checkins << self
      reverse_geocode! if device.checkins.count == 1
      add_fogged_info
    else
      raise "Checkin is not assigned to a device." unless Rails.env.test?
    end
  end

  def resolve_address(options = {})
    options = {permissible: nil, type: nil}.merge(options)
    reverse_geocode! if options[:type] == "address"
    public_info(options[:permissible])
  end

  def self.resolve_address(options = {})
    # this will convert it to an array
    # paginate before use!
    all.map {|checkin| checkin.resolve_address(options) }
  end

  def reverse_geocode!
    unless reverse_geocoded?
      reverse_geocode
      save
    end
    self
  end

  def self.hash_group_and_count_by(attribute)
    select(&attribute).group_by(&attribute)
    .each_with_object({}) do |(key,checkins), result|
      result[key] = checkins.count
    end
    .sort_by{ |_attribute, count| count }.reverse!
  end

  def self.percentage_increase(time_range)
    recent_checkins_count = where(created_at: 1.send(time_range).ago..Time.now).count.to_f
    older_checkins_count = where(created_at: 2.send(time_range).ago..1.send(time_range).ago).count.to_f
    if recent_checkins_count > 0 && older_checkins_count > 0
      (((recent_checkins_count/older_checkins_count)-1)*100).round(2)
    end
  end

  protected

    def public_info(permissible)
      public_checkin = Checkin.new(attributes)
      if replace_foggable_attributes?(permissible)
        public_checkin = public_checkin.replace_foggable_attributes
      end
      public_checkin.address = fogged_area if address == 'Not yet geocoded'
      public_checkin.attributes.delete_if {|key, value| key =~ /fogged|uuid/ || value == nil}
    end

    def replace_foggable_attributes?(permissible)
      (fogged? || device.fogged?) && (!permissible || !device.can_bypass_fogging?(permissible))
    end

    def replace_foggable_attributes
      assign_attributes(address: fogged_area, lat: fogged_lat, lng: fogged_lng)
      Checkin.new(attributes.delete_if {|key, _v| key =~ /city|postal/ })
    end

    def nearest_city
      center_point = [self.lat, self.lng]
      City.near(center_point, 200).first || NoCity.new
    end

    def add_fogged_info
      self.fogged_lat ||= nearest_city.latitude || self.lat + rand(-0.5..0.5)
      self.fogged_lng ||= nearest_city.longitude || self.lng + rand(-0.5..0.5)
      self.fogged_area ||= nearest_city.name
      save
    end

    def reverse_geocoded?
      address != 'Not yet geocoded'
    end

end
