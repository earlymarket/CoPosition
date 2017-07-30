module Users
  class SendSmoochMessage
    include Interactor

    delegate :user, :message, :api, to: :context

    def call
      user.devices.each do |device|
        next unless device.config && device.config.custom && (id = device.config.custom["smoochId"])
        begin
          api.post_message(id, message)
        rescue SmoochApi::ApiError => e
          puts "Exception when calling ConversationApi->post_message: #{e}"
        end
      end
    end
  end
end
