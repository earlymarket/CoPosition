module Users
  class DevicesPresenter < ApplicationPresenter
    attr_reader :user
    attr_reader :devices
    attr_reader :device
    attr_reader :checkins
    attr_reader :filename
    attr_reader :config
    attr_reader :date_range

    FOGGED_FIELD_SET = %w(
      id
      created_at
      updated_at
      device_id
      fogged_lat AS lat
      fogged_lng AS lng
      fogged_city AS address
      fogged_city AS city
      fogged_country_code AS postal_code
      fogged_country_code AS country_code
    ).freeze

    OUTPUT_FIELD_SET = %w(
      id
      created_at
      updated_at
      device_id
      output_lat AS lat
      output_lng AS lng
      output_address AS address
      output_city AS city
      output_postal_code AS postal_code
      output_country_code AS country_code
    ).freeze

    def initialize(user, params, action)
      @user = user
      @params = params
      send action
    end

    def index
      devices = user.devices
      devices.geocode_last_checkins
      device_ids = devices.last_checkins.map { |checkin| checkin["device_id"] }
      devices = devices.index_by(&:id).values_at(*device_ids)
      devices += user.devices.includes(:permissions)
      @devices = devices.uniq.paginate(page: @params[:page], per_page: 5)
    end

    def show
      @device = Device.find(@params[:id])
      @date_range = checkins_date_range
      return unless (download_format = @params[:download])
      @filename = "device-#{device.id}-checkins-#{Time.zone.today}." + download_format
      @checkins = device.checkins.send("to_" + download_format)
    end

    def shared
      @device = Device.find(@params[:id])
      @checkin = device.before_delay_checkins.first
      @checkin&.reverse_geocode!
    end

    def info
      @device = Device.find(@params[:id])
      @config = device.config
    end

    def index_gon
      {
        checkins: gon_index_checkins,
        current_user_id: user.id,
        devices: devices,
        permissions: devices.map { |device| device.permissions.not_coposition_developers }.inject(:+)
      }
    end

    def show_gon
      {
        checkins: gon_show_checkins_paginated,
        device: device.id,
        current_user_id: user.id,
        total: gon_show_checkins.count
      }
    end

    def shared_gon
      {
        device: device.public_info,
        user: device.user.public_info_hash,
        checkin: gon_shared_checkin
      }
    end

    def form_for
      device
    end

    def form_path
      user_device_path(user.url_id, device)
    end

    def form_range_filter(text, from)
      link_to(text, user_device_path(user.url_id, device, from: from, to: Time.zone.today), method: :get)
    end

    private

    def gon_index_checkins
      checkins =
        user
        .devices
        .map { |device| device.checkins.first.as_json.merge(device: device.name) if device.checkins.exists? }
        .compact
      checkins.sort_by { |checkin| checkin["created_at"] }.reverse
    end

    def gon_shared_checkin
      return unless @checkin

      checkin = Checkin.where(id: @checkin.id)
      if device.fogged?
        checkin.select(FOGGED_FIELD_SET)[0]
      else
        checkin.select(OUTPUT_FIELD_SET)[0]
      end
    end

    def gon_show_checkins_paginated
      gon_show_checkins
        .paginate(page: 1, per_page: 1000)
        .select(:id, :lat, :lng, :created_at, :address, :fogged, :fogged_city, :edited)
    end

    def gon_show_checkins
      date_range[:from] ? device.checkins.where(created_at: date_range[:from]..date_range[:to]) : device.checkins
    end
  end
end
