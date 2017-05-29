class Location < ApplicationRecord
  belongs_to :user
  has_many :checkins
  has_many :devices, through: :checkins
  validates_presence_of :lat, :lng

  reverse_geocoded_by :lat, :lng

  def reverse_geocode!
    unless reverse_geocoded?
      reverse_geocode
      save
    end
    self
  end

  def reverse_geocoded?
    address?
  end
  class << self
    def limit_returned_locations(args)
      if args[:multiple_devices]
        all.uniq
      else
        uniq.paginate(page: args[:page], per_page: args[:per_page])
      end
    end

    def near_to(near)
      return all unless near
      near_array = near.split(",")
      lat = near_array[0].to_f
      lng = near_array[1].to_f
      where(lat: (lat - 0.5)..(lat + 0.5), lng: (lng - 0.5)..(lng + 0.5))
    end
  end
end
