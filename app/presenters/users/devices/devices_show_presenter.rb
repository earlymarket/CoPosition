module Users::Devices
  class DevicesShowPresenter < ApplicationPresenter
    FIRST_LOAD_MAX = 5_000
    MAX_CHECKINS_TO_DISPLAY = 20_000
    MAX_CHECKINS_TO_LOAD = 50_000

    attr_reader :user
    attr_reader :device
    attr_reader :owner
    attr_reader :checkins
    attr_reader :devices
    attr_reader :filename
    attr_reader :date_range
    attr_reader :checkins_view

    def initialize(user, params)
      @user = user
      @params = params
      @owner = device_page? ? Device.find(params[:id]) : user
      @device = Device.find(params[:id]) if device_page?
      @devices = user.devices
      @date_range = first_load && owner.checkins.any? ? first_load_range : checkins_date_range
      @checkins_view = params[:checkins_view] == "true"

      set_data_for_download if download_format.present?
    end

    def show_gon
      {
        checkin: checkin,
        checkins: raw_paginated_checkins,
        cities: gon_show_cities,
        counts: gon_cities_counts,
        first_load: first_load,
        device: owner.id,
        devices: devices,
        current_user_id: user.id,
        total: gon_show_checkins.count,
        max: MAX_CHECKINS_TO_LOAD,
        checkins_view: checkins_view
      }
    end

    def form_for
      device
    end

    def form_path
      device_page? ? user_device_path(user.url_id, device) : user_checkins_path(user.url_id)
    end

    def form_range_filter(text, from)
      if device_page?
        link_to text,
          user_device_path(
            user.url_id,
            device,
            from: from,
            to: Time.zone.today,
            user: {
              device_ids: params[:user] && params[:user][:device_ids] || devices.pluck(:id)
            },
            checkins_view: params[:checkins_view]
          ),
          method: :get
      else
        link_to text,
          user_checkins_path(
            user.url_id,
            from: from,
            to: Time.zone.today,
            user: {
              device_ids: params[:user] && params[:user][:device_ids] || devices.pluck(:id)
            },
            checkins_view: params[:checkins_view]
          ),
          method: :get
      end
    end

    private

    def set_data_for_download
      @filename = "device-#{device.id}-checkins-#{DateTime.current}." + download_format
      @checkins = gon_show_checkins.unscope(:order).order(created_at: :asc).send("to_" + download_format)
    end

    def download_format
      @downlod_format ||= params[:download]
    end

    def first_load
      @first_load ||= params[:first_load]
    end

    def checkin
      @checkin ||= params[:checkin_id] ? Checkin.find(params[:checkin_id]) : nil
    end

    def gon_show_checkins_paginated
      gon_show_checkins
        .paginate(page: 1, per_page: 5000)
        .select(:id, :lat, :lng, :created_at, :address, :fogged, :fogged_city, :edited, :device_id)
    end

    def raw_paginated_checkins
      if gon_show_checkins.count <= MAX_CHECKINS_TO_DISPLAY
        ActiveRecord::Base.connection.execute(gon_show_checkins_paginated.to_sql).to_a
      else
        []
      end
    end

    def first_load_range
      return { from: nil, to: nil } if (checkins = gon_show_checkins).size.zero?

      { from: checkins.last.created_at.beginning_of_day, to: Time.zone.today }
    end

    def gon_show_checkins
      @gon_show_checkins ||= if checkin
        owner_checkins.where(id: checkin.id)
      elsif first_load
        owner_checkins.limit(FIRST_LOAD_MAX)
      elsif date_range[:from]
        owner_checkins.where(created_at: date_range[:from]..date_range[:to])
      else
        owner_checkins
      end
    end

    def owner_checkins
      checkins = owner.checkins
      if params[:device_id]
        checkins.where(device_id: params[:device_id])
      elsif params[:user]
        checkins.where(device_id: params[:user][:device_ids])
      else
        checkins
      end
    end

    def gon_show_cities
      checkins = first_load ? gon_show_checkins.where(id: gon_show_checkins.select(:id)) : gon_show_checkins
      city_checkins = Checkin.where(id: checkins.unscope(:order).select("DISTINCT ON(fogged_city) checkins.id"))
      city_checkins_sql = city_checkins.select("created_at", "fogged_lat AS lat", "fogged_lng AS lng",
        "fogged_city AS city", "fogged_country_code AS country_code", "id").to_sql
      ActiveRecord::Base.connection.execute(city_checkins_sql)
    end

    def gon_cities_counts
      gon_show_checkins.where(id: gon_show_checkins.select(:id)).unscope(:order).group(:fogged_city).count
    end

    def device_page?
      params[:id].present?
    end
  end
end
