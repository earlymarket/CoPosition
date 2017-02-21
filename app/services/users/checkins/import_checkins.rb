module Users::Checkins
  class ImportCheckins
    def initialize(params)
      @file = params[:file]
      @device = Device.find(params[:device_id])
    end

    def success?
      return false unless @file && valid_file?
      ImportWorker.perform_async(@device.id, @file.path)
      true
    end

    def valid_file?
      CSV.foreach(@file.path, headers: true) do |csv|
        return csv.headers == Checkin.column_names
      end
    end

    def error
      return 'You must choose a CSV file to upload' unless @file
      'Invalid CSV file format'
    end
  end
end